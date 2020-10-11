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
#import "MTXSendMessageFailedException.h"
#import "MTXSyncFailedException.h"

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
			 storage: (id <MTXStorage>)storage
{
	return [[[self alloc] initWithUserID: userID
				    deviceID: deviceID
				 accessToken: accessToken
				  homeserver: homeserver
				     storage: storage] autorelease];
}

+ (void)logInWithUser: (OFString *)user
	     password: (OFString *)password
	   homeserver: (OFURL *)homeserver
	      storage: (id <MTXStorage>)storage
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

		MTXClient *client = [MTXClient clientWithUserID: userID
						       deviceID: deviceID
						    accessToken: accessToken
						     homeserver: realHomeserver
							storage: storage];
		block(client, nil);
	}];

	objc_autoreleasePoolPop(pool);
}

- (instancetype)initWithUserID: (OFString *)userID
		      deviceID: (OFString *)deviceID
		   accessToken: (OFString *)accessToken
		    homeserver: (OFURL *)homeserver
		       storage: (id <MTXStorage>)storage
{
	self = [super init];

	@try {
		validateHomeserver(homeserver);

		_userID = [userID copy];
		_deviceID = [deviceID copy];
		_accessToken = [accessToken copy];
		_homeserver = [homeserver copy];
		_storage = [storage retain];
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
	[_storage release];

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

- (void)syncWithTimeout: (of_time_interval_t)timeout
		  block: (mtx_client_response_block_t)block
{
	void *pool = objc_autoreleasePoolPush();
	MTXRequest *request = [self
	    requestWithPath: @"/_matrix/client/r0/sync"];
	unsigned long long timeoutMs = timeout * 1000;
	OFMutableDictionary<OFString *, OFString *> *query =
	    [OFMutableDictionary dictionaryWithObject: @(timeoutMs).stringValue
					       forKey: @"timeout"];
	query[@"since"] = [_storage nextBatchForDeviceID: _deviceID];
	request.query = query;
	[request performWithBlock: ^ (mtx_response_t response, int statusCode,
				       id exception) {
		if (exception != nil) {
			block(exception);
			return;
		}

		if (statusCode != 200) {
			block([MTXSyncFailedException
			    exceptionWithStatusCode: statusCode
					   response: response
					     client: self]);
			return;
		}

		OFString *nextBatch = response[@"next_batch"];
		if (![nextBatch isKindOfClass: OFString.class]) {
			block([OFInvalidServerReplyException exception]);
			return;
		}

		@try {
			[_storage transactionWithBlock: ^ {
				[_storage setNextBatch: nextBatch
					   forDeviceID: _deviceID];

				[self processRoomsSync: response[@"rooms"]];
				[self processPresenceSync:
				    response[@"presence"]];
				[self processAccountDataSync:
				    response[@"account_data"]];
				[self processToDeviceSync:
				    response[@"to_device"]];

				return true;
			}];
		} @catch (id e) {
			block(e);
			return;
		}

		block(nil);
	}];

	objc_autoreleasePoolPop(pool);
}

- (void)logOutWithBlock: (mtx_client_response_block_t)block
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
	    block: (mtx_client_response_block_t)block
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

- (void)sendMessage: (OFString *)message
	     roomID: (OFString *)roomID
	      block: (mtx_client_response_block_t)block;
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path = [OFString stringWithFormat:
	    @"/_matrix/client/r0/rooms/%@/send/m.room.message", roomID];
	MTXRequest *request = [self requestWithPath: path];
	request.method = OF_HTTP_REQUEST_METHOD_POST;
	request.body = @{
		@"msgtype": @"m.text",
		@"body": message
	};
	[request performWithBlock: ^ (mtx_response_t response, int statusCode,
				       id exception) {
		if (exception != nil) {
			block(exception);
			return;
		}

		if (statusCode != 200) {
			block([MTXSendMessageFailedException
			    exceptionWithMessage: message
					  roomID: roomID
				      statusCode: statusCode
					response: response
					  client: self]);
			return;
		}

		block(nil);
	}];

	objc_autoreleasePoolPop(pool);
}

- (void)processRoomsSync: (OFDictionary<OFString *, id> *)rooms
{
	[self processJoinedRooms: rooms[@"join"]];
	[self processInvitedRooms: rooms[@"invite"]];
	[self processLeftRooms: rooms[@"leave"]];
}

- (void)processPresenceSync: (OFDictionary<OFString *, id> *)presence
{
}

- (void)processAccountDataSync: (OFDictionary<OFString *, id> *)accountData
{
}

- (void)processToDeviceSync: (OFDictionary<OFString *, id> *)toDevice
{
}

- (void)processJoinedRooms: (OFDictionary<OFString *, id> *)rooms
{
	if (rooms == nil)
		return;

	for (OFString *roomID in rooms)
		[_storage addJoinedRoom: roomID
				forUser: _userID];
}

- (void)processInvitedRooms: (OFDictionary<OFString *, id> *)rooms
{
	if (rooms == nil)
		return;
}

- (void)processLeftRooms: (OFDictionary<OFString *, id> *)rooms
{
	if (rooms == nil)
		return;

	for (OFString *roomID in rooms)
		[_storage removeJoinedRoom: roomID
				   forUser: _userID];
}
@end
