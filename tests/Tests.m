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

#import <ObjFW/ObjFW.h>

#import "ObjMatrix.h"

@interface Tests: OFObject <OFApplicationDelegate>
@end

OF_APPLICATION_DELEGATE(Tests)

@implementation Tests
{
	MTXClient *_client;
	OFString *_roomID;
}

- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	OFDictionary<OFString *, OFString *> *environment =
	    OFApplication.environment;
	if (environment[@"OBJMATRIX_USER"] == nil ||
	    environment[@"OBJMATRIX_PASS"] == nil ||
	    environment[@"OBJMATRIX_HS"] == nil) {
		[OFStdErr writeString: @"Please set OBJMATRIX_USER, "
				       @"OBJMATRIX_PASS and OBJMATRIX_HS in "
				       @"the environment!\n"];
		[OFApplication terminateWithStatus: 1];
	}

	OFIRI *homeserver = [OFIRI IRIWithString: environment[@"OBJMATRIX_HS"]];
	OFIRI *storageIRI = [OFIRI fileIRIWithPath: @"tests.db"];
	id <MTXStorage> storage =
	    [MTXSQLite3Storage storageWithIRI: storageIRI];
	[MTXClient logInWithUser: environment[@"OBJMATRIX_USER"]
			password: environment[@"OBJMATRIX_PASS"]
		      homeserver: homeserver
			 storage: storage
			   block: ^ (MTXClient *client, id exception) {
		if (exception != nil) {
			OFLog(@"Error logging in: %@", exception);
			[OFApplication terminateWithStatus: 1];
		}

		_client = [client retain];
		OFLog(@"Logged in client: %@", _client);

		[_client startSyncLoop];
		[self fetchRoomList];
	}];
}

- (void)fetchRoomList
{
	[_client fetchRoomListWithBlock: ^ (OFArray<OFString *> *rooms,
					     id exception) {
		if (exception != nil) {
			OFLog(@"Failed to fetch room list: %@", exception);
			[OFApplication terminateWithStatus: 1];
		}

		OFLog(@"Fetched room list: %@", rooms);

		[self joinRoom];
	}];
}

- (void)joinRoom
{
	OFString *room = @"#test:nil.im";
	[_client joinRoom: room block: ^ (OFString *roomID, id exception) {
		if (exception != nil) {
			OFLog(@"Failed to join room %@: %@", room, exception);
			[OFApplication terminateWithStatus: 1];
		}

		_roomID = [roomID copy];
		OFLog(@"Joined room %@", _roomID);

		[self sendMessage];
	}];
}

- (void)sendMessage
{
	[_client sendMessage: @"ObjMatrix test successful!"
		      roomID: _roomID
		       block: ^ (id exception) {
		if (exception != nil) {
			OFLog(@"Failed to send message to room %@: %@",
			    _roomID, exception);
			[OFApplication terminateWithStatus: 1];
		}

		OFLog(@"Message sent to %@", _roomID);

		OFLog(@"Waiting 5 seconds before leaving room and logging out");

		[self performSelector: @selector(leaveRoom) afterDelay: 5];
	}];
}

- (void)leaveRoom
{
	[_client leaveRoom: _roomID block: ^ (id exception) {
		if (exception != nil) {
			OFLog(@"Failed to leave room %@: %@", exception);
			[OFApplication terminateWithStatus: 1];
		}

		OFLog(@"Left room %@", _roomID);

		[self logOut];
	}];
}

- (void)logOut
{
	[_client logOutWithBlock: ^ (id exception) {
		if (exception != nil) {
			OFLog(@"Failed to log out: %@\n", exception);
			[OFApplication terminateWithStatus: 1];
		}

		OFLog(@"Logged out client");

		[OFApplication terminate];
	}];
}
@end
