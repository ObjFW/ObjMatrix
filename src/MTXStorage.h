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

/**
 * @brief A block which will be treated as a single transaction for the storage.
 *
 * @return Whether the transaction should be committed (`true`) or rolled back
 *	   (`false`).
 */
typedef bool (^mtx_storage_transaction_block_t)(void);

/**
 * @brief A protocol for a storage to be used by @ref MTXClient.
 */
@protocol MTXStorage <OFObject>
/**
 * @brief Performs all operations inside the block as a transaction.
 */
- (void)transactionWithBlock: (mtx_storage_transaction_block_t)block;

/**
 * @brief Stores the next batch for the specified device.
 *
 * @param nextBatch The next batch for the device
 * @param deviceID The device for which to store the next batch
 */
- (void)setNextBatch: (OFString *)nextBatch
	 forDeviceID: (OFString *)deviceID;

/**
 * @brief Returns the next batch for the specified device.
 *
 * @param deviceID The device ID for which to return the next batch
 * @return The next batch for the specified device, or `nil` if none is
 *	   available.
 */
- (nullable OFString *)nextBatchForDeviceID: (OFString *)deviceID;
@end

OF_ASSUME_NONNULL_END
