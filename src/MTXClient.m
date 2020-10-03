/*
 * Copyright (c) 2020, Jonathan Schleifer <js@nil.im>
 *
 * https://fossil.nil.im/objmatrix
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice is present in all copies.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import "MTXClient.h"
#import "MTXRequest.h"

#import "MTXFetchRoomListFailedException.h"
#import "MTXJoinRoomFailedException.h"
#import "MTXLeaveRoomFailedException.h"
#import "MTXLoginFailedException.h"
#import "MTXLogoutFailedException.h"

static void
validateHomeserver(OFURL *homeserver)
{
	if (![homeserver.scheme isEqual: @"http"] &&
	    ![homeserver.scheme isEqual: @"https"])
		@throw [OFUnsupportedProtocolException
		    exceptionWithURL: homeserver];

	if (homeserver.path != nil && ![homeserver.path isEqual: @"/"])
		@throw [OFInvalidArgumentException exception];

	if (homeserver.user != nil || homeserver.password != nil ||
	    homeserver.query != nil || homeserver.fragment != nil)
		@throw [OFInvalidArgumentException exception];
}

@implementation MTXClient
+ (instancetype)clientWithUserID: (OFString *)userID
			deviceID: (OFString *)deviceID
		     accessToken: (OFString *)accessToken
		      homeserver: (OFURL *)homeserver
{
	return [[[self alloc] initWithUserID: userID
				    deviceID: deviceID
				 accessToken: accessToken
				  homeserver: homeserver] autorelease];
}

+ (void)logInWithUser: (OFString *)user
	     password: (OFString *)password
	   homeserver: (OFURL *)homeserver
		block: (mtx_client_login_block_t)block
{
	void *pool = objc_autoreleasePoolPush();

	validateHomeserver(homeserver);

	MTXRequest *request = [MTXRequest
	    requestWithPath: @"/_matrix/client/r0/login"
		accessToken: nil
		 homeserver: homeserver];
	request.method = OF_HTTP_REQUEST_METHOD_POST;
	request.body = @{
		@"type": @"m.login.password",
		@"identifier": @{
			@"type": @"m.id.user",
			@"user": user
		},
		@"password": password
	};

	[request performWithBlock: ^ (mtx_response_t response, int statusCode,
				       id exception) {
		if (exception != nil) {
			block(nil, exception);
			return;
		}

		if (statusCode != 200) {
			id exception = [MTXLoginFailedException
			    exceptionWithUser: user
				   homeserver: homeserver
				   statusCode: statusCode
				     response: response];
			block(nil, exception);
			return;
		}

		OFString *userID = response[@"user_id"];
		OFString *deviceID = response[@"device_id"];
		OFString *accessToken = response[@"access_token"];
		if (![userID isKindOfClass: OFString.class] ||
		    ![deviceID isKindOfClass: OFString.class] ||
		    ![accessToken isKindOfClass: OFString.class]) {
			block(nil, [OFInvalidServerReplyException exception]);
			return;
		}

		OFString *baseURL =
		    response[@"well_known"][@"m.homeserver"][@"base_url"];
		if (baseURL != nil &&
		    ![baseURL isKindOfClass: OFString.class]) {
			block(nil, [OFInvalidServerReplyException exception]);
			return;
		}

		OFURL *realHomeserver;
		if (baseURL != nil) {
			@try {
				realHomeserver = [OFURL URLWithString: baseURL];
			} @catch (id e) {
				block(nil, e);
				return;
			}
		} else
			realHomeserver = homeserver;

		MTXClient *client = [MTXClient
		    clientWithUserID: userID
			    deviceID: deviceID
			 accessToken: accessToken
			  homeserver: realHomeserver];
		block(client, nil);
	}];

	objc_autoreleasePoolPop(pool);
}

- (instancetype)initWithUserID: (OFString *)userID
		      deviceID: (OFString *)deviceID
		   accessToken: (OFString *)accessToken
		    homeserver: (OFURL *)homeserver
{
	self = [super init];

	@try {
		validateHomeserver(homeserver);

		_userID = [userID copy];
		_deviceID = [deviceID copy];
		_accessToken = [accessToken copy];
		_homeserver = [homeserver copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_userID release];
	[_deviceID release];
	[_accessToken release];
	[_homeserver release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@\n"
	    @"\tUser ID = %@\n"
	    @"\tDevice ID = %@\n"
	    @"\tAccess token = %@\n"
	    @"\tHomeserver = %@\n"
	    @">",
	    self.class, _userID, _deviceID, _accessToken, _homeserver];
}

- (MTXRequest *)requestWithPath: (OFString *)path
{
	return [MTXRequest requestWithPath: path
			       accessToken: _accessToken
				homeserver: _homeserver];
}

- (void)logOutWithBlock: (mtx_client_logout_block_t)block
{
	void *pool = objc_autoreleasePoolPush();
	MTXRequest *request =
	    [self requestWithPath: @"/_matrix/client/r0/logout"];
	request.method = OF_HTTP_REQUEST_METHOD_POST;
	[request performWithBlock: ^ (mtx_response_t response, int statusCode,
				       id exception) {
		if (exception != nil) {
			block(exception);
			return;
		}

		if (statusCode != 200) {
			block([MTXLogoutFailedException
			    exceptionWithStatusCode: statusCode
					   response: response
					     client: self]);
			return;
		}

		block(nil);
	}];

	objc_autoreleasePoolPop(pool);
}

- (void)fetchRoomListWithBlock: (mtx_client_room_list_block_t)block
{
	void *pool = objc_autoreleasePoolPush();
	MTXRequest *request =
	    [self requestWithPath: @"/_matrix/client/r0/joined_rooms"];
	[request performWithBlock: ^ (mtx_response_t response, int statusCode,
				       id exception) {
		if (exception != nil) {
			block(nil, exception);
			return;
		}

		if (statusCode != 200) {
			block(nil, [MTXFetchRoomListFailedException
			    exceptionWithStatusCode: statusCode
					   response: response
					     client: self]);
			return;
		}

		OFArray<OFString *> *joinedRooms = response[@"joined_rooms"];
		if (![joinedRooms isKindOfClass: OFArray.class]) {
			block(nil, [OFInvalidServerReplyException exception]);
			return;
		}
		for (OFString *room in joinedRooms) {
			if (![room isKindOfClass: OFString.class]) {
				block(nil,
				    [OFInvalidServerReplyException exception]);
				return;
			}
		}

		block(response[@"joined_rooms"], nil);
	}];

	objc_autoreleasePoolPop(pool);
}

- (void)joinRoom: (OFString *)room
	   block: (mtx_client_room_join_block_t)block
{
	void *pool = objc_autoreleasePoolPush();
	MTXRequest *request = [self requestWithPath:
	    [OFString stringWithFormat: @"/_matrix/client/r0/join/%@", room]];
	request.method = OF_HTTP_REQUEST_METHOD_POST;
	[request performWithBlock: ^ (mtx_response_t response, int statusCode,
				       id exception) {
		if (exception != nil) {
			block(nil, exception);
			return;
		}

		if (statusCode != 200) {
			block(nil, [MTXJoinRoomFailedException
			    exceptionWithRoom: room
				   statusCode: statusCode
				     response: response
				       client: self]);
			return;
		}

		OFString *roomID = response[@"room_id"];
		if (![roomID isKindOfClass: OFString.class]) {
			block(nil, [OFInvalidServerReplyException exception]);
			return;
		}

		block(roomID, nil);
	}];

	objc_autoreleasePoolPop(pool);
}

- (void)leaveRoom: (OFString *)roomID
	    block: (mtx_client_room_leave_block_t)block
{
	void *pool = objc_autoreleasePoolPush();
	MTXRequest *request = [self requestWithPath: [OFString
	    stringWithFormat: @"/_matrix/client/r0/rooms/%@/leave", roomID]];
	request.method = OF_HTTP_REQUEST_METHOD_POST;
	[request performWithBlock: ^ (mtx_response_t response, int statusCode,
				       id exception) {
		if (exception != nil) {
			block(exception);
			return;
		}

		if (statusCode != 200) {
			block([MTXLeaveRoomFailedException
			    exceptionWithRoomID: roomID
				     statusCode: statusCode
				       response: response
					 client: self]);
			return;
		}

		block(nil);
	}];

	objc_autoreleasePoolPop(pool);
}
@end
