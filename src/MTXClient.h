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

#import <ObjFW/ObjFW.h>

OF_ASSUME_NONNULL_BEGIN

@class MTXClient;

/**
 * @brief A block called when a new login succeeded or failed.
 *
 * @param client If the login succeeded, the newly created client
 * @param exception If the login failed, an exception
 */
typedef void (^mtx_client_login_block_t)(MTXClient *_Nullable client,
    id _Nullable exception);

/**
 * @brief A block called when the device was logged out.
 *
 * @param exception `nil` on success, otherwise an exception
 */
typedef void (^mtx_client_logout_block_t)(id _Nullable exception);

/**
 * @brief A block called when the room list was fetched.
 *
 * @param rooms An array of joined rooms, or nil on error
 * @param exception An exception if fetching the room list failed
 */
typedef void (^mtx_client_room_list_block_t)(
    OFArray<OFString *> *_Nullable rooms, id _Nullable exception);

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
@property (readonly, nonatomic) OFURL *homeserver;

/**
 * @brief Creates a new client with the specified access token on the specified
 *	  homeserver.
 *
 * @param accessToken The access token for the client
 * @param homeserver The URL of the homeserver
 * @return An autoreleased MTXClient
 */
+ (instancetype)clientWithUserID: (OFString *)userID
			deviceID: (OFString *)deviceID
		     accessToken: (OFString *)accessToken
		      homeserver: (OFURL *)homeserver;

/**
 * @brief Logs into the homeserver and creates a new client.
 */
+ (void)logInWithUser: (OFString *)user
	     password: (OFString *)password
	   homeserver: (OFURL *)homeserver
		block: (mtx_client_login_block_t)block;

/**
 * @brief Initializes an already allocated client with the specified access
 *	  token on the specified homeserver.
 *
 * @param accessToken The access token for the client
 * @param homeserver The URL of the homeserver
 * @return An initialized MTXClient
 */
- (instancetype)initWithUserID: (OFString *)userID
		      deviceID: (OFString *)deviceID
		   accessToken: (OFString *)accessToken
		    homeserver: (OFURL *)homeserver OF_DESIGNATED_INITIALIZER;

/**
 * @brief Logs out the device and invalidates the access token.
 *
 * @warning The client can no longer be used after this succeeded!
 *
 * @param block A block to call when logging out succeeded or failed
 */
- (void)asyncLogOutWithBlock: (mtx_client_logout_block_t)block;

/**
 * @brief Fetches the list of joined rooms.
 *
 * @param block A block to call with the list of joined room
 */
- (void)asyncFetchRoomList: (mtx_client_room_list_block_t)block;
@end

OF_ASSUME_NONNULL_END
