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

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief A response to a request.
 *
 * This is a typedef for `OFDictionary<OFString *, id> *`.
 */
typedef OFDictionary<OFString *, id> *mtx_response_t;

/**
 * @brief A block called with the response for an MTXRequest.
 *
 * @param response The response to the request, as a dictionary parsed from JSON
 * @param statusCode The HTTP status code returned for the request
 * @param exception The first exception that occurred during the request,
 *		    or `nil` on success
 */
typedef void (^mtx_request_block_t)(mtx_response_t _Nullable response,
    int statusCode, id _Nullable exception);

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
 * @brief The URL of the homeserver to send the request to.
 */
@property (readonly, nonatomic) OFURL *homeserver;

/**
 * @brief The HTTP request method.
 *
 * Defaults to `OF_HTTP_REQUEST_METHOD_GET`.
 */
@property (nonatomic) of_http_request_method_t method;

/**
 * @brief The path of the request.
 */
@property (copy, nonatomic) OFString *path;

/**
 * @brief The query for the request.
 */
@property (copy, nullable, nonatomic)
    OFDictionary<OFString *, OFString *> *query;

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
		     homeserver: (OFURL *)homeserver;

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
		  homeserver: (OFURL *)homeserver;

/**
 * @brief Performs the request and calls the specified block once the request
 *	  succeeded or failed.
 *
 * @param block The block to call once the request succeeded or failed
 */
- (void)performWithBlock: (mtx_request_block_t)block;
@end

OF_ASSUME_NONNULL_END
