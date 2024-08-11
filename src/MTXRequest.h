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

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief A response to a request.
 *
 * This is a typedef for `OFDictionary<OFString *, id> *`.
 */
typedef OFDictionary<OFString *, id> *MTXResponse;

/**
 * @brief A block called with the response for an MTXRequest.
 *
 * @param response The response to the request, as a dictionary parsed from JSON
 * @param statusCode The HTTP status code returned for the request
 * @param exception The first exception that occurred during the request,
 *		    or `nil` on success
 */
typedef void (^MTXRequestBlock)(MTXResponse _Nullable response, int statusCode,
    id _Nullable exception);

/**
 * @brief An internal class for performing a request on the Matrix server.
 */
@interface MTXRequest: OFObject <OFHTTPClientDelegate>
/**
 * @brief The access token to use.
 *
 * Some requests are unauthenticated - for those, the access token is `nil`.
 */
@property (readonly, nonatomic, nullable) OFString *accessToken;

/**
 * @brief The IRI of the homeserver to send the request to.
 */
@property (readonly, nonatomic) OFIRI *homeserver;

/**
 * @brief The HTTP request method.
 *
 * Defaults to `OF_HTTP_REQUEST_METHOD_GET`.
 */
@property (nonatomic) OFHTTPRequestMethod method;

/**
 * @brief The path of the request.
 */
@property (copy, nonatomic) OFString *path;

/**
 * @brief The query items for the request.
 */
@property (copy, nullable, nonatomic)
    OFArray<OFPair<OFString *, OFString *> *> *queryItems;

/**
 * @brief An optional body to send along with the request.
 *
 * This is a dictionary that gets serialized to JSON when the request is sent.
 */
@property (copy, nullable, nonatomic) OFDictionary<OFString *, id> *body;

/**
 * @brief Creates a new request with the specified access token and homeserver.
 *
 * @param accessToken An (optional) access token to use
 * @param homeserver The homeserver the request will be sent to
 * @return An autoreleased MTXRequest
 */
+ (instancetype)requestWithPath: (OFString *)path
		    accessToken: (nullable OFString *)accessToken
		     homeserver: (OFIRI *)homeserver;

/**
 * @brief Initializes an already allocated request with the specified access
 *	  token and homeserver.
 *
 * @param accessToken An (optional) access token to use
 * @param homeserver The homeserver the request will be sent to
 * @return An initialized MTXRequest
 */
- (instancetype)initWithPath: (OFString *)path
		 accessToken: (nullable OFString *)accessToken
		  homeserver: (OFIRI *)homeserver;

/**
 * @brief Performs the request and calls the specified block once the request
 *	  succeeded or failed.
 *
 * @param block The block to call once the request succeeded or failed
 */
- (void)performWithBlock: (MTXRequestBlock)block;
@end

OF_ASSUME_NONNULL_END
