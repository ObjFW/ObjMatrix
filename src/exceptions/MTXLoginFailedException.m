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

#import "MTXLoginFailedException.h"

@implementation MTXLoginFailedException
+ (instancetype)exceptionWithUser: (OFString *)user
		       homeserver: (OFURL *)homeserver
		       statusCode: (int)statusCode
			 response: (mtx_response_t)response
{
	return [[[self alloc] initWithUser: user
				homeserver: homeserver
				statusCode: statusCode
				  response: response] autorelease];
}

- (instancetype)initWithUser: (OFString *)user
		  homeserver: (OFURL *)homeserver
		  statusCode: (int)statusCode
		    response: (mtx_response_t)response
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
