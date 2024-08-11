/*
 * Copyright (c) 2020, 2021 Jonathan Schleifer <js@nil.im>
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

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief A block which will be treated as a single transaction for the storage.
 *
 * @return Whether the transaction should be committed (`true`) or rolled back
 *	   (`false`).
 */
typedef bool (^MTXStorageTransactionBlock)(void);

/**
 * @brief A protocol for a storage to be used by @ref MTXClient.
 */
@protocol MTXStorage <OFObject>
/**
 * @brief Performs all operations inside the block as a transaction.
 */
- (void)transactionWithBlock: (MTXStorageTransactionBlock)block;

/**
 * @brief Stores the next batch for the specified device.
 *
 * @param nextBatch The next batch for the device
 * @param deviceID The device for which to store the next batch
 */
- (void)setNextBatch: (OFString *)nextBatch forDeviceID: (OFString *)deviceID;

/**
 * @brief Returns the next batch for the specified device.
 *
 * @param deviceID The device ID for which to return the next batch
 * @return The next batch for the specified device, or `nil` if none is
 *	   available.
 */
- (nullable OFString *)nextBatchForDeviceID: (OFString *)deviceID;

/**
 * @brief Adds the specified room ID to the list of joined rooms for the
 *	  specified user ID.
 *
 * @param roomID The room ID to add to the list of joined rooms
 * @param userID The user ID for which to add the room
 */
- (void)addJoinedRoom: (OFString *)roomID forUser: (OFString *)userID;

/**
 * @brief Removes the specified room ID to the list of joined rooms for the
 *	  specified user ID.
 *
 * @param roomID The room ID to add to the list of joined rooms
 * @param userID The user ID for which to add the room
 */
- (void)removeJoinedRoom: (OFString *)roomID forUser: (OFString *)userID;

/**
 * @brief Returns the joined room IDs for the specified user ID.
 *
 * @param userID The user ID for which to return the joined rooms
 * @return The joined room IDs for the specified user ID
 */
- (OFArray<OFString *> *)joinedRoomsForUser: (OFString *)userID;
@end

OF_ASSUME_NONNULL_END
