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

#import "MTXRequest.h"

@implementation MTXRequest
{
	OFData *_body;
	MTXRequestBlock _block;
}

+ (instancetype)requestWithPath: (OFString *)path
		    accessToken: (OFString *)accessToken
		     homeserver: (OFIRI *)homeserver
{
	return [[[self alloc] initWithPath: path
			       accessToken: accessToken
				homeserver: homeserver] autorelease];
}

- (instancetype)initWithPath: (OFString *)path
		 accessToken: (OFString *)accessToken
		  homeserver: (OFIRI *)homeserver
{
	self = [super init];

	@try {
		_accessToken = [accessToken copy];
		_homeserver = [homeserver copy];
		_path = [path copy];
		_method = OFHTTPRequestMethodGet;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_accessToken release];
	[_homeserver release];
	[_path release];
	[_body release];

	[super dealloc];
}

- (void)setBody: (OFDictionary<OFString *, id> *)body
{
	void *pool = objc_autoreleasePoolPush();

	[_body release];

	OFString *JSONString = [body JSONRepresentation];
	_body = [[OFData alloc] initWithItems: JSONString.UTF8String
					count: JSONString.UTF8StringLength];

	objc_autoreleasePoolPop(pool);
}

- (OFDictionary<OFString *, id> *)body
{
	return [OFString stringWithUTF8String: _body.items
				       length: _body.count].objectByParsingJSON;
}

- (void)performWithBlock: (MTXRequestBlock)block
{
	void *pool = objc_autoreleasePoolPush();

	if (_block != nil)
		/* Not the best exception to indicate it's already in-flight. */
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	OFMutableIRI *requestIRI = [[_homeserver mutableCopy] autorelease];
	requestIRI.path = _path;
	requestIRI.queryItems = _queryItems;

	OFMutableDictionary *headers = [OFMutableDictionary dictionary];
	headers[@"User-Agent"] = @"ObjMatrix";
	if (_accessToken != nil)
		headers[@"Authorization"] =
		    [OFString stringWithFormat: @"Bearer %@", _accessToken];
	if (_body != nil)
		headers[@"Content-Length"] = @(_body.count).stringValue;

	OFHTTPRequest *request = [OFHTTPRequest requestWithIRI: requestIRI];
	request.method = _method;
	request.headers = headers;

	OFHTTPClient *client = [OFHTTPClient client];
	client.delegate = self;

	_block = [block copy];
	[self retain];
	[client asyncPerformRequest: request];

	objc_autoreleasePoolPop(pool);
}

-      (void)client: (OFHTTPClient *)client
  didPerformRequest: (OFHTTPRequest *)request
	   response: (OFHTTPResponse *)response
	  exception: (id)exception
{
	if (response != nil &&
	    [exception isKindOfClass: [OFHTTPRequestFailedException class]])
		exception = nil;

	/* Reset to nil first, so that another one can be performed. */
	MTXRequestBlock block = _block;
	_block = nil;

	if (exception == nil) {
		@try {
			OFMutableData *responseData = [OFMutableData data];
			while (!response.atEndOfStream) {
				char buffer[512];
				size_t length = [response readIntoBuffer: buffer
								  length: 512];

				[responseData addItems: buffer count: length];
			}

			MTXResponse responseJSON = [OFString
			    stringWithUTF8String: responseData.items
					  length: responseData.count]
			    .objectByParsingJSON;

			block(responseJSON, response.statusCode, nil);
		} @catch (id e) {
			block(nil, response.statusCode, e);
		}
	} else
		block(nil, 0, exception);

	[block release];
	[self release];
}

-     (void)client: (OFHTTPClient *)client
  wantsRequestBody: (OFStream *)body
	   request: (OFHTTPRequest *)request
{
	[body writeData: _body];
}
@end
