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

#import "ObjMatrix.h"

@interface Tests: OFObject <OFApplicationDelegate>
@end

OF_APPLICATION_DELEGATE(Tests)

@implementation Tests
{
	MTXClient *_client;
}

- (void)applicationDidFinishLaunching
{
	__auto_type environment = OFApplication.environment;
	if (environment[@"OBJMATRIX_USER"] == nil ||
	    environment[@"OBJMATRIX_PASS"] == nil ||
	    environment[@"OBJMATRIX_HS"] == nil) {
		[of_stderr writeString: @"Please set OBJMATRIX_USER, "
					@"OBJMATRIX_PASS and OBJMATRIX_HS in "
					@"the environment!\n"];
		[OFApplication terminateWithStatus: 1];
	}

	OFURL *homeserver = [OFURL URLWithString: environment[@"OBJMATRIX_HS"]];
	[MTXClient logInWithUser: environment[@"OBJMATRIX_USER"]
			password: environment[@"OBJMATRIX_PASS"]
		      homeserver: homeserver
			   block: ^ (MTXClient *client, id exception) {
		if (exception != nil) {
			of_log(@"Error logging in: %@", exception);
			[OFApplication terminateWithStatus: 1];
		}

		_client = [client retain];
		of_log(@"Logged in client: %@", _client);

		[self fetchRoomList];
	}];
}

- (void)fetchRoomList
{
	[_client fetchRoomListWithBlock: ^ (OFArray<OFString *> *rooms,
					     id exception) {
		if (exception != nil) {
			of_log(@"Failed to fetch room list: %@", exception);
			[OFApplication terminateWithStatus: 1];
		}

		of_log(@"Fetched room list: %@", rooms);

		[self logOut];
	}];
}

- (void)logOut
{
	[_client logOutWithBlock: ^ (id exception) {
		if (exception != nil) {
			of_log(@"Failed to log out: %@\n", exception);
			[OFApplication terminateWithStatus: 1];
		}

		of_log(@"Logged out client");

		[OFApplication terminate];
	}];
}
@end
