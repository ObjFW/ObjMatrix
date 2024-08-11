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

#import "MTXSendMessageFailedException.h"

#import "MTXClient.h"

@implementation MTXSendMessageFailedException
+ (instancetype)exceptionWithMessage: (OFString *)message
			      roomID: (OFString *)roomID
			  statusCode: (int)statusCode
			    response: (MTXResponse)response
			      client: (MTXClient *)client
{
	return [[[self alloc] initWithMessage: message
				       roomID: roomID
				   statusCode: statusCode
				     response: response
				       client: client] autorelease];
}

- (instancetype)initWithMessage: (OFString *)message
			 roomID: (OFString *)roomID
		     statusCode: (int)statusCode
		       response: (MTXResponse)response
			 client: (MTXClient *)client
{
	self = [super initWithStatusCode: statusCode
				response: response
				  client: client];

	@try {
		_message = [message copy];
		_roomID = [roomID copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_message release];
	[_roomID release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to send message to room %@ for %@ with status code %d: %@",
	    _roomID, self.client.userID, self.statusCode, self.response];
}
@end
