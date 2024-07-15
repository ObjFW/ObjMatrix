/*
 * Copyright (c) 2020, 2021, 2024, Jonathan Schleifer <js@nil.im>
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
validateHomeserver(OFIRI *homeserver)
{
	if (![homeserver.scheme isEqual: @"http"] &&
	    ![homeserver.scheme isEqual: @"https"])
		@throw [OFUnsupportedProtocolException
		    exceptionWithIRI: homeserver];

	if (homeserver.path != nil && ![homeserver.path isEqual: @"/"])
		@throw [OFInvalidArgumentException exception];

	if (homeserver.user != nil || homeserver.password != nil ||
	    homeserver.query != nil || homeserver.fragment != nil)
		@throw [OFInvalidArgumentException exception];
}

@implementation MTXClient
{
	bool _syncing;
}

+ (instancetype)clientWithUserID: (OFString *)userID
			deviceID: (OFString *)deviceID
		     accessToken: (OFString *)accessToken
		      homeserver: (OFIRI *)homeserver
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
	   homeserver: (OFIRI *)homeserver
	      storage: (id <MTXStorage>)storage
		block: (MTXClientLoginBlock)block
{
	void *pool = objc_autoreleasePoolPush();

	validateHomeserver(homeserver);

	MTXRequest *request = [MTXRequest
	    requestWithPath: @"/_matrix/client/r0/login"
		accessToken: nil
		 homeserver: homeserver];
	request.method = OFHTTPRequestMethodPost;
	request.body = @{
		@"type": @"m.login.password",
		@"identifier": @{
			@"type": @"m.id.user",
			@"user": user
		},
		@"password": password
	};

	[request performWithBlock: ^ (MTXResponse response, int statusCode,
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
			block(nil,
			    [OFInvalidServerResponseException exception]);
			return;
		}

		OFString *baseIRI =
		    response[@"well_known"][@"m.homeserver"][@"base_url"];
		if (baseIRI != nil &&
		    ![baseIRI isKindOfClass: OFString.class]) {
			block(nil,
			    [OFInvalidServerResponseException exception]);
			return;
		}

		OFIRI *realHomeserver;
		if (baseIRI != nil) {
			@try {
				realHomeserver = [OFIRI IRIWithString: baseIRI];
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
		    homeserver: (OFIRI *)homeserver
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
		_syncTimeout = 300;
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

- (void)startSyncLoop
{
	if (_syncing)
		return;

	_syncing = true;

	void *pool = objc_autoreleasePoolPush();
	MTXRequest *request = [self
	    requestWithPath: @"/_matrix/client/r0/sync"];
	unsigned long long timeoutMs = _syncTimeout * 1000;
	OFMutableArray<OFPair <OFString *, OFString *> *> *queryItems =
	    [OFMutableArray array];
	OFString *since = [_storage nextBatchForDeviceID: _deviceID];

	[queryItems addObject:
	    [OFPair pairWithFirstObject: @"timeout"
			   secondObject: @(timeoutMs).stringValue]];

	if (since != nil)
		[queryItems addObject:
		    [OFPair pairWithFirstObject: @"since"
				   secondObject: since]];

	request.queryItems = queryItems;
	[request performWithBlock: ^ (MTXResponse response, int statusCode,
				       id exception) {
		if (exception != nil) {
			if (_syncExceptionHandler != NULL)
				_syncExceptionHandler(exception);
			return;
		}

		if (statusCode != 200) {
			if (_syncExceptionHandler != NULL)
				_syncExceptionHandler([MTXSyncFailedException
				    exceptionWithStatusCode: statusCode
						   response: response
						     client: self]);
			return;
		}

		OFString *nextBatch = response[@"next_batch"];
		if (![nextBatch isKindOfClass: OFString.class]) {
			if (_syncExceptionHandler != NULL)
				_syncExceptionHandler(
				    [OFInvalidServerResponseException
				    exception]);
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
			if (_syncExceptionHandler != NULL)
				_syncExceptionHandler(e);
			return;
		}

		if (_syncing)
			[self startSyncLoop];
	}];

	objc_autoreleasePoolPop(pool);
}

- (void)stopSyncLoop
{
	_syncing = false;
}

- (void)logOutWithBlock: (MTXClientResponseBlock)block
{
	void *pool = objc_autoreleasePoolPush();
	MTXRequest *request =
	    [self requestWithPath: @"/_matrix/client/r0/logout"];
	request.method = OFHTTPRequestMethodPost;
	[request performWithBlock: ^ (MTXResponse response, int statusCode,
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

- (void)fetchRoomListWithBlock: (MTXClientRoomListBlock)block
{
	void *pool = objc_autoreleasePoolPush();
	MTXRequest *request =
	    [self requestWithPath: @"/_matrix/client/r0/joined_rooms"];
	[request performWithBlock: ^ (MTXResponse response, int statusCode,
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
			block(nil,
			    [OFInvalidServerResponseException exception]);
			return;
		}
		for (OFString *room in joinedRooms) {
			if (![room isKindOfClass: OFString.class]) {
				block(nil,
				    [OFInvalidServerResponseException
				    exception]);
				return;
			}
		}

		block(response[@"joined_rooms"], nil);
	}];

	objc_autoreleasePoolPop(pool);
}

- (void)joinRoom: (OFString *)room block: (MTXClientRoomJoinBlock)block
{
	void *pool = objc_autoreleasePoolPush();
	MTXRequest *request = [self requestWithPath:
	    [OFString stringWithFormat: @"/_matrix/client/r0/join/%@", room]];
	request.method = OFHTTPRequestMethodPost;
	[request performWithBlock: ^ (MTXResponse response, int statusCode,
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
			block(nil,
			    [OFInvalidServerResponseException exception]);
			return;
		}

		block(roomID, nil);
	}];

	objc_autoreleasePoolPop(pool);
}

- (void)leaveRoom: (OFString *)roomID block: (MTXClientResponseBlock)block
{
	void *pool = objc_autoreleasePoolPush();
	MTXRequest *request = [self requestWithPath: [OFString
	    stringWithFormat: @"/_matrix/client/r0/rooms/%@/leave", roomID]];
	request.method = OFHTTPRequestMethodPost;
	[request performWithBlock: ^ (MTXResponse response, int statusCode,
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
	      block: (MTXClientResponseBlock)block;
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path = [OFString stringWithFormat:
	    @"/_matrix/client/r0/rooms/%@/send/m.room.message", roomID];
	MTXRequest *request = [self requestWithPath: path];
	request.method = OFHTTPRequestMethodPost;
	request.body = @{
		@"msgtype": @"m.text",
		@"body": message
	};
	[request performWithBlock: ^ (MTXResponse response, int statusCode,
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
		[_storage addJoinedRoom: roomID forUser: _userID];
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
		[_storage removeJoinedRoom: roomID forUser: _userID];
}
@end
