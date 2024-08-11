/*
 * Copyright (c) 2020, 2021, 2024 Jonathan Schleifer <js@nil.im>
 *
 * https://fl.nil.im/objmatrix
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES WITH
 * REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS.  IN NO EVENT SHALL ISC BE LIABLE FOR ANY SPECIAL, DIRECT,
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
 * LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
 * OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 */

#import <ObjFW/ObjFW.h>

#import "MTXStorage.h"

OF_ASSUME_NONNULL_BEGIN

@class MTXClient;

/**
 * @brief A block called when a new login succeeded or failed.
 *
 * @param client If the login succeeded, the newly created client
 * @param exception If the login failed, an exception
 */
typedef void (^MTXClientLoginBlock)(MTXClient *_Nullable client,
    id _Nullable exception);

/**
 * @brief A block called when the response for an operation was received.
 *
 * @param exception `nil` on success, otherwise an exception
 */
typedef void (^MTXClientResponseBlock)(id _Nullable exception);

/**
 * @brief A block called when an exception occurred during sync.
 *
 * @param exception The exception which occurred during sync
 */
typedef void (^MTXSyncExceptionHandlerBlock)(id exception);

/**
 * @brief A block called when the room list was fetched.
 *
 * @param rooms An array of joined rooms, or nil on error
 * @param exception An exception if fetching the room list failed
 */
typedef void (^MTXClientRoomListBlock)(OFArray<OFString *> *_Nullable rooms,
    id _Nullable exception);

/**
 * @brief A block called when a room was joined.
 *
 * @param roomID The room ID that was joined, or nil on error. This can be used
 *		 to get the room ID if a room alias was joined.
 * @param exception An exception if joining the room failed
 */
typedef void (^MTXClientRoomJoinBlock)(OFString *_Nullable roomID,
    id _Nullable exception);

/**
 * @brief A class that represents a client.
 */
@interface MTXClient: OFObject
/**
 * @brief The user ID used by the client.
 */
@property (readonly, nonatomic) OFString *userID;

/**
 * @brief The device ID used by the client.
 */
@property (readonly, nonatomic) OFString *deviceID;

/**
 * @brief The access token used by the client.
 */
@property (readonly, nonatomic) OFString *accessToken;

/**
 * @brief The homeserver used by the client.
 */
@property (readonly, nonatomic) OFIRI *homeserver;

/**
 * @brief The storage used by the client.
 */
@property (readonly, nonatomic) id <MTXStorage> storage;

/**
 * @brief The timeout for sync requests.
 *
 * Defaults to 5 minutes.
 */
@property (nonatomic) OFTimeInterval syncTimeout;

/**
 * @brief A block to handle exceptions that occurred during sync.
 */
@property (copy, nonatomic) MTXSyncExceptionHandlerBlock syncExceptionHandler;

/**
 * @brief Creates a new client with the specified access token on the specified
 *	  homeserver.
 *
 * @param userID The user ID for the client
 * @param deviceID The device ID for the client
 * @param accessToken The access token for the client
 * @param homeserver The IRI of the homeserver
 * @param storage The storage the client should use
 * @return An autoreleased MTXClient
 */
+ (instancetype)clientWithUserID: (OFString *)userID
			deviceID: (OFString *)deviceID
		     accessToken: (OFString *)accessToken
		      homeserver: (OFIRI *)homeserver
			 storage: (id <MTXStorage>)storage;

/**
 * @brief Logs into the homeserver and creates a new client.
 *
 * @param user The user to log into
 * @param password The password to log in with
 * @param homeserver The homeserver to log into
 * @param storage The storage the client should use
 * @param block A block to call once login succeeded or failed
 */
+ (void)logInWithUser: (OFString *)user
	     password: (OFString *)password
	   homeserver: (OFIRI *)homeserver
	      storage: (id <MTXStorage>)storage
		block: (MTXClientLoginBlock)block;

/**
 * @brief Initializes an already allocated client with the specified access
 *	  token on the specified homeserver.
 *
 * @param userID The user ID for the client
 * @param deviceID The device ID for the client
 * @param accessToken The access token for the client
 * @param homeserver The IRI of the homeserver
 * @param storage The storage the client should use
 * @return An initialized MTXClient
 */
- (instancetype)initWithUserID: (OFString *)userID
		      deviceID: (OFString *)deviceID
		   accessToken: (OFString *)accessToken
		    homeserver: (OFIRI *)homeserver
		       storage: (id <MTXStorage>)storage
    OF_DESIGNATED_INITIALIZER;

/**
 * @brief Starts the sync loop.
 */
- (void)startSyncLoop;

/**
 * @brief Stops the sync loop.
 *
 * The currently waiting sync is not aborted, but after it returns, no new sync
 * will be started.
 */
- (void)stopSyncLoop;

/**
 * @brief Logs out the device and invalidates the access token.
 *
 * @warning The client can no longer be used after this succeeded!
 *
 * @param block A block to call when logging out succeeded or failed
 */
- (void)logOutWithBlock: (MTXClientResponseBlock)block;

/**
 * @brief Fetches the list of joined rooms.
 *
 * @param block A block to call with the list of joined room
 */
- (void)fetchRoomListWithBlock: (MTXClientRoomListBlock)block;

/**
 * @brief Joins the specified room.
 *
 * @param room The room to join. Either a room ID or a room alias.
 * @param block A block to call when the room was joined
 */
- (void)joinRoom: (OFString *)room block: (MTXClientRoomJoinBlock)block;

/**
 * @brief Leaves the specified room.
 *
 * @param roomID The room ID to leave
 * @param block A block to call when the room was left
 */
- (void)leaveRoom: (OFString *)roomID block: (MTXClientResponseBlock)block;

/**
 * @brief Sends the specified message to the specified room ID.
 *
 * @param message The message to send
 * @param roomID The room ID to which to send the message
 * @param block A block to call when the message was sent
 */
- (void)sendMessage: (OFString *)message
	     roomID: (OFString *)roomID
	      block: (MTXClientResponseBlock)block;
@end

OF_ASSUME_NONNULL_END
