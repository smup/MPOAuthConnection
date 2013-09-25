//
//  MPOAuthURLRequest.h
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.05.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MPOAuthURLRequest : NSObject /* {
@private
	NSURL			*_url;
	NSString		*_httpMethod;
	NSURLRequest	*_urlRequest;
	NSMutableArray	*_parameters;
	
	UIImage			*_image;
	NSString		*_imageParamName;
} */

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *HTTPMethod;
@property (nonatomic, readonly, strong) NSURLRequest *urlRequest;
@property (nonatomic, strong) NSMutableArray *parameters;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *imageParamName;
@property (nonatomic, strong) NSDictionary * customHttpHeaders;

- (id)initWithURL:(NSURL *)inURL andParameters:(NSArray *)parameters;
- (id)initWithURLRequest:(NSURLRequest *)inRequest;

- (void)addParameters:(NSArray *)inParameters;

- (NSURLRequest  *)urlRequestSignedWithSecret:(NSString *)inSecret usingMethod:(NSString *)inScheme;

@end
