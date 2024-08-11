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

#import "MTXClientException.h"

OF_ASSUME_NONNULL_BEGIN

@interface MTXJoinRoomFailedException: MTXClientException
@property (readonly, nonatomic) OFString *room;

+ (instancetype)exceptionWithStatusCode: (int)statusCode
			       response: (MTXResponse)response
				 client: (MTXClient *)client OF_UNAVAILABLE;
+ (instancetype)exceptionWithRoom: (OFString *)room
		       statusCode: (int)statusCode
			 response: (MTXResponse)response
			   client: (MTXClient *)client;
- (instancetype)initWithStatusCode: (int)statusCode
			  response: (MTXResponse)response
			    client: (MTXClient *)client OF_UNAVAILABLE;
- (instancetype)initWithRoom: (OFString *)room
		  statusCode: (int)statusCode
		    response: (MTXResponse)response
		      client: (MTXClient *)client;
@end

OF_ASSUME_NONNULL_END
