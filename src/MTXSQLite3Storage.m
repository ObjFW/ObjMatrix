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

#import <ObjSQLite3/ObjSQLite3.h>

#import "MTXSQLite3Storage.h"

@implementation MTXSQLite3Storage
{
	SL3Connection *_conn;
	SL3PreparedStatement *_nextBatchSetStatement, *_nextBatchGetStatement;
}

+ (instancetype)storageWithPath: (OFString *)path
{
	return [[[self alloc] initWithPath: path] autorelease];
}

- (instancetype)initWithPath: (OFString *)path
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		_conn = [[SL3Connection alloc] initWithPath: path];

		[self createTables];

		_nextBatchSetStatement = [[_conn prepareStatement:
		    @"INSERT OR REPLACE INTO next_batch (\n"
		    @"    device_id, next_batch\n"
		    @") VALUES (\n"
		    @"    $device_id, $next_batch\n"
		    @")"] retain];
		_nextBatchGetStatement = [[_conn prepareStatement:
		    @"SELECT next_batch FROM next_batch\n"
		    @"WHERE device_id=$device_id"] retain];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_nextBatchSetStatement release];
	[_nextBatchGetStatement release];
	[_conn release];

	[super dealloc];
}

- (void)createTables
{
	[_conn executeStatement: @"CREATE TABLE IF NOT EXISTS next_batch (\n"
				 @"    device_id TEXT PRIMARY KEY,\n"
				 @"    next_batch TEXT\n"
				 @")"];
}

- (void)transactionWithBlock: (mtx_storage_transaction_block_t)block
{
	[_conn transactionWithBlock: block];
}

- (void)setNextBatch: (OFString *)nextBatch
	 forDeviceID: (OFString *)deviceID
{
	void *pool = objc_autoreleasePoolPush();

	[_nextBatchSetStatement reset];
	[_nextBatchSetStatement bindWithDictionary: @{
		@"$device_id": deviceID,
		@"$next_batch": nextBatch
	}];
	[_nextBatchSetStatement step];

	objc_autoreleasePoolPop(pool);
}

- (OFString *)nextBatchForDeviceID: (OFString *)deviceID
{
	void *pool = objc_autoreleasePoolPush();

	[_nextBatchGetStatement reset];
	[_nextBatchGetStatement bindWithDictionary: @{
		@"$device_id": deviceID
	}];

	if (![_nextBatchGetStatement step])
		return nil;

	OFString *nextBatch =
	    [[_nextBatchGetStatement rowDictionary][@"next_batch"] retain];

	objc_autoreleasePoolPop(pool);

	return [nextBatch autorelease];
}
@end
