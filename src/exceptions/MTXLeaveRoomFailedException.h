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

#import "MTXClientException.h"

OF_ASSUME_NONNULL_BEGIN

@interface MTXLeaveRoomFailedException: MTXClientException
@property (readonly, nonatomic) OFString *roomID;

+ (instancetype)exceptionWithStatusCode: (int)statusCode
			       response: (MTXResponse)response
				 client: (MTXClient *)client OF_UNAVAILABLE;
+ (instancetype)exceptionWithRoomID: (OFString *)roomID
			 statusCode: (int)statusCode
			   response: (MTXResponse)response
			     client: (MTXClient *)client;
- (instancetype)initWithStatusCode: (int)statusCode
			  response: (MTXResponse)response
			    client: (MTXClient *)client OF_UNAVAILABLE;
- (instancetype)initWithRoomID: (OFString *)roomID
		    statusCode: (int)statusCode
		      response: (MTXResponse)response
			client: (MTXClient *)client;
@end

OF_ASSUME_NONNULL_END
