/*
 * Copyright (c) 2020 Jonathan Schleifer <js@nil.im>
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

#import "MTXStorage.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief SQLite3-based storage for @ref MTXClient.
 */
@interface MTXSQLite3Storage: OFObject <MTXStorage>
/**
 * @brief Creates a new SQLite3-based storage for @ref MTXClient.
 *
 * @param path The path for the SQLite3 database
 * @return An autoreleased MTXSQLite3Storage
 */
+ (instancetype)storageWithPath: (OFString *)path;

/**
 * @brief Initializes an already allocated MTXSQLite3Storage.
 *
 * @param path The path for the SQLite3 database
 * @return An initialized MTXSQLite3Storage
 */
- (instancetype)initWithPath: (OFString *)path OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
