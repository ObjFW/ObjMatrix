/*
 * Copyright (c) 2020, 2021, 2024, Jonathan Schleifer <js@nil.im>
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
	OFString *_roomID;
}

- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	__auto_type environment = OFApplication.environment;
	if (environment[@"OBJMATRIX_USER"] == nil ||
	    environment[@"OBJMATRIX_PASS"] == nil ||
	    environment[@"OBJMATRIX_HS"] == nil) {
		[OFStdErr writeString: @"Please set OBJMATRIX_USER, "
				       @"OBJMATRIX_PASS and OBJMATRIX_HS in "
				       @"the environment!\n"];
		[OFApplication terminateWithStatus: 1];
	}

	OFIRI *homeserver = [OFIRI IRIWithString: environment[@"OBJMATRIX_HS"]];
	id <MTXStorage> storage =
	    [MTXSQLite3Storage storageWithPath: @"tests.db"];
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
