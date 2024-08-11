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

#import "MTXLoginFailedException.h"

@implementation MTXLoginFailedException
+ (instancetype)exceptionWithUser: (OFString *)user
		       homeserver: (OFIRI *)homeserver
		       statusCode: (int)statusCode
			 response: (MTXResponse)response
{
	return [[[self alloc] initWithUser: user
				homeserver: homeserver
				statusCode: statusCode
				  response: response] autorelease];
}

- (instancetype)initWithUser: (OFString *)user
		  homeserver: (OFIRI *)homeserver
		  statusCode: (int)statusCode
		    response: (MTXResponse)response
{
	self = [super init];

	@try {
		_user = [user copy];
		_homeserver = [homeserver copy];
		_statusCode = statusCode;
		_response = [response copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_user release];
	[_homeserver release];
	[_response release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to log in user %@ on %@ with status code %d: %@",
	    _user, _homeserver, _statusCode, _response];
}
@end
