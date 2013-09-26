//
//  MPOAuthAPI.m
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.05.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#import "MPOAuthAPIRequestLoader.h"
#import "MPOAuthAPI.h"
#import "MPOAuthCredentialConcreteStore.h"
#import "MPOAuthURLRequest.h"
#import "MPOAuthURLResponse.h"
#import "MPURLRequestParameter.h"
#import "MPOAuthAuthenticationMethod.h"
#import "MPOAuthAuthenticationMethodAuthExchange.h"
#import "NSURL+MPURLParameterAdditions.h"

NSString *kMPOAuthCredentialConsumerKey				= @"kMPOAuthCredentialConsumerKey";
NSString *kMPOAuthCredentialConsumerSecret			= @"kMPOAuthCredentialConsumerSecret";
NSString *kMPOAuthCredentialName                    = @"kMPOAuthCredentialName";
NSString *kMPOAuthCredentialUsername				= @"kMPOAuthCredentialUsername";
NSString *kMPOAuthCredentialPassword				= @"kMPOAuthCredentialPassword";
//NSString *kMPOAuthCredentialFBAccessToken			= @"kMPOAuthCredentialFBAccessToken";
NSString *kMPOAuthCredentialRequestToken			= @"kMPOAuthCredentialRequestToken";
NSString *kMPOAuthCredentialRequestTokenSecret		= @"kMPOAuthCredentialRequestTokenSecret";
NSString *kMPOAuthCredentialAccessToken				= @"kMPOAuthCredentialAccessToken";
NSString *kMPOAuthCredentialAccessTokenSecret		= @"kMPOAuthCredentialAccessTokenSecret";
NSString *kMPOAuthCredentialSessionHandle			= @"kMPOAuthCredentialSessionHandle";

NSString *kMPOAuthSignatureMethod					= @"kMPOAuthSignatureMethod";

@interface MPOAuthAPI ()
@property (nonatomic, readwrite, retain) id <MPOAuthCredentialStore, MPOAuthParameterFactory> credentials;
@property (nonatomic, readwrite, retain) NSURL *authenticationURL;
@property (nonatomic, readwrite, retain) NSURL *baseURL;
@property (nonatomic, readwrite, retain) NSMutableArray *activeLoaders;
@property (nonatomic, readwrite, assign) MPOAuthAuthenticationState authenticationState;

- (MPOAuthAPIRequestLoader *)performMethod:(NSString *)inMethod atURL:(NSURL *)inURL withParameters:(NSArray *)inParameters withTarget:(id)inTarget andAction:(SEL)inAction withCustomHttpHeaders:(NSDictionary*)customHttpHeaders usingHTTPMethod:(NSString *)inHTTPMethod;
@end

@implementation MPOAuthAPI

- (id)initWithCredentials:(NSDictionary *)inCredentials andBaseURL:(NSURL *)inBaseURL {
	return [self initWithCredentials:inCredentials authenticationURL:inBaseURL andBaseURL:inBaseURL];
}

- (id)initWithCredentials:(NSDictionary *)inCredentials authenticationURL:(NSURL *)inAuthURL andBaseURL:(NSURL *)inBaseURL {
	return [self initWithCredentials:inCredentials authenticationURL:inBaseURL andBaseURL:inBaseURL autoStart:YES];	
}

- (id)initWithCredentials:(NSDictionary *)inCredentials authenticationURL:(NSURL *)inAuthURL andBaseURL:(NSURL *)inBaseURL autoStart:(BOOL)aFlag {
	if (self = [super init]) {
		self.authenticationURL = inAuthURL;
		self.baseURL = inBaseURL;
		self.authenticationState = MPOAuthAuthenticationStateUnauthenticated;
		credentials_ = [[MPOAuthCredentialConcreteStore alloc] initWithCredentials:inCredentials forBaseURL:inBaseURL withAuthenticationURL:inAuthURL];
		self.authenticationMethod = [[[MPOAuthAuthenticationMethod alloc] initWithAPI:self forURL:inAuthURL] autorelease];
		self.signatureScheme = MPOAuthSignatureSchemeHMACSHA1;

		activeLoaders_ = [[NSMutableArray alloc] initWithCapacity:10];
		
		if (aFlag) {
			[self authenticate];
		}
	}
	return self;	
}

- (oneway void)dealloc {
	self.credentials = nil;
	self.baseURL = nil;
	self.authenticationURL = nil;
	self.authenticationMethod = nil;
	self.activeLoaders = nil;
	
	[super dealloc];
}

@synthesize credentials = credentials_;
@synthesize baseURL = baseURL_;
@synthesize authenticationURL = authenticationURL_;
@synthesize authenticationMethod = authenticationMethod_;
@synthesize signatureScheme = signatureScheme_;
@synthesize activeLoaders = activeLoaders_;
@synthesize authenticationState = oauthAuthenticationState_;

#pragma mark -

- (void)setSignatureScheme:(MPOAuthSignatureScheme)inScheme {
	signatureScheme_ = inScheme;
	
	NSString *methodString = @"HMAC-SHA1";
	
	switch (signatureScheme_) {
		case MPOAuthSignatureSchemePlainText:
			methodString = @"PLAINTEXT";
			break;
		case MPOAuthSignatureSchemeRSASHA1:
			methodString = @"RSA-SHA1";
		case MPOAuthSignatureSchemeHMACSHA1:
		default:
			// already initted to the default
			break;
	}
	
	[(MPOAuthCredentialConcreteStore *)credentials_ setSignatureMethod:methodString];
}

#pragma mark -

- (void)authenticate {
	NSAssert(credentials_.consumerKey, @"A Consumer Key is required for use of OAuth.");
	[self.authenticationMethod authenticate];
}

- (BOOL)isAuthenticated {
	return (self.authenticationState == MPOAuthAuthenticationStateAuthenticated);
}

#pragma mark -

- (MPOAuthAPIRequestLoader *)performMethod:(NSString *)inMethod withTarget:(id)inTarget andAction:(SEL)inAction {
	return [self performMethod:inMethod
                         atURL:self.baseURL
                withParameters:nil
                    withTarget:inTarget
                     andAction:inAction
         withCustomHttpHeaders:nil
               usingHTTPMethod:@"GET"];
}

- (MPOAuthAPIRequestLoader *)performMethod:(NSString *)inMethod atURL:(NSURL *)inURL withParameters:(NSArray *)inParameters withTarget:(id)inTarget andAction:(SEL)inAction {
	return [self performMethod:inMethod
                         atURL:inURL
                withParameters:inParameters
                    withTarget:inTarget
                     andAction:inAction
         withCustomHttpHeaders:nil
               usingHTTPMethod:@"GET"];
}

- (MPOAuthAPIRequestLoader *)performMethod:(NSString *)inMethod atURL:(NSURL *)inURL withParameters:(NSArray *)inParameters withTarget:(id)inTarget andAction:(SEL)inAction withCustomHttpHeaders:(NSDictionary *)customHttpHeaders {
	return [self performMethod:inMethod
                         atURL:inURL
                withParameters:inParameters
                    withTarget:inTarget
                     andAction:inAction
         withCustomHttpHeaders:customHttpHeaders
               usingHTTPMethod:@"GET"];
}

- (MPOAuthAPIRequestLoader *)performPOSTMethod:(NSString *)inMethod atURL:(NSURL *)inURL withParameters:(NSArray *)inParameters withTarget:(id)inTarget andAction:(SEL)inAction {
	return [self performMethod:inMethod
                         atURL:inURL
                withParameters:inParameters
                    withTarget:inTarget
                     andAction:inAction
         withCustomHttpHeaders:nil
               usingHTTPMethod:@"POST"];
}

- (MPOAuthAPIRequestLoader *)performDELETEMethod:(NSString *)inMethod atURL:(NSURL *)inURL withParameters:(NSArray *)inParameters withTarget:(id)inTarget andAction:(SEL)inAction 
{
    
	return [self performMethod:inMethod
                         atURL:inURL
                withParameters:inParameters
                    withTarget:inTarget
                     andAction:inAction
         withCustomHttpHeaders:nil
               usingHTTPMethod:@"DELETE"];
}

- (MPOAuthAPIRequestLoader *)performMethod:(NSString *)inMethod atURL:(NSURL *)inURL withParameters:(NSArray *)inParameters withTarget:(id)inTarget andAction:(SEL)inAction withCustomHttpHeaders:(NSDictionary *)customHttpHeaders usingHTTPMethod:(NSString *)inHTTPMethod
{
	if (!inMethod && ![inURL path] && ![inURL query]) {
		[NSException raise:@"MPOAuthNilMethodRequestException" format:@"Nil was passed as the method to be performed on %@", inURL];
	}
	
	NSURL *requestURL = inMethod ? [NSURL URLWithString:inMethod relativeToURL:inURL] : inURL;
	MPOAuthURLRequest *aRequest = [[MPOAuthURLRequest alloc] initWithURL:requestURL andParameters:inParameters];
    aRequest.customHttpHeaders = customHttpHeaders;
	MPOAuthAPIRequestLoader *loader = [[MPOAuthAPIRequestLoader alloc] initWithRequest:aRequest];
	
	aRequest.HTTPMethod = inHTTPMethod;
	
	loader.credentials = self.credentials;
	loader.target = inTarget;
	loader.action = inAction ? inAction : @selector(_performedLoad:receivingData:);
	
	[loader loadSynchronously:NO];
	//	[self.activeLoaders addObject:loader];
	
	[aRequest release];

	return [loader autorelease];
}

- (MPOAuthAPIRequestLoader *)performPOSTImageMethod:(NSString *)inMethod withParameters:(NSArray *)inParameters withImageParamName:(NSString *)imageParamName andImage:(UIImage *)image 
		   withTarget:(id)inTarget andAction:(SEL)inAction {
	NSURL *inURL = self.baseURL;
	
	if (!inMethod && ![inURL path] && ![inURL query]) {
		[NSException raise:@"MPOAuthNilMethodRequestException" format:@"Nil was passed as the method to be performed on %@", inURL];
	}
	
	NSURL *requestURL = inMethod ? [NSURL URLWithString:inMethod relativeToURL:inURL] : inURL;
	MPOAuthURLRequest *aRequest = [[MPOAuthURLRequest alloc] initWithURL:requestURL andParameters:inParameters];
	MPOAuthAPIRequestLoader *loader = [[MPOAuthAPIRequestLoader alloc] initWithRequest:aRequest];
	
	aRequest.HTTPMethod = @"POST";
	if (imageParamName && image) {
		aRequest.imageParamName = imageParamName;
		aRequest.image = image;
	}
	
	loader.credentials = self.credentials;
	loader.target = inTarget;
	loader.action = inAction ? inAction : @selector(_performedLoad:receivingData:);
	
	[loader loadSynchronously:NO];
	//	[self.activeLoaders addObject:loader];
	
	[aRequest release];

	return [loader autorelease];
}

- (MPOAuthAPIRequestLoader *)performURLRequest:(NSURLRequest *)inRequest withTarget:(id)inTarget andAction:(SEL)inAction {
	if (!inRequest && ![[inRequest URL] path] && ![[inRequest URL] query]) {
		[NSException raise:@"MPOAuthNilMethodRequestException" format:@"Nil was passed as the method to be performed on %@", inRequest];
	}

	MPOAuthURLRequest *aRequest = [[MPOAuthURLRequest alloc] initWithURLRequest:inRequest];
	MPOAuthAPIRequestLoader *loader = [[MPOAuthAPIRequestLoader alloc] initWithRequest:aRequest];
	
	loader.credentials = self.credentials;
	loader.target = inTarget;
	loader.action = inAction ? inAction : @selector(_performedLoad:receivingData:);
	
	[loader loadSynchronously:NO];
	//	[self.activeLoaders addObject:loader];
	
	[aRequest release];	
	
	return [loader autorelease];
}

- (NSData *)dataForMethod:(NSString *)inMethod {
	return [self dataForURL:self.baseURL andMethod:inMethod withParameters:nil];
}

- (NSData *)dataForMethod:(NSString *)inMethod withParameters:(NSArray *)inParameters {
	return [self dataForURL:self.baseURL andMethod:inMethod withParameters:inParameters];
}

- (NSData *)dataForURL:(NSURL *)inURL andMethod:(NSString *)inMethod withParameters:(NSArray *)inParameters {
	NSURL *requestURL = [NSURL URLWithString:inMethod relativeToURL:inURL];
	MPOAuthURLRequest *aRequest = [[MPOAuthURLRequest alloc] initWithURL:requestURL andParameters:inParameters];
	MPOAuthAPIRequestLoader *loader = [[MPOAuthAPIRequestLoader alloc] initWithRequest:aRequest];

	loader.credentials = self.credentials;
	[loader loadSynchronously:YES];
	
	[loader autorelease];
	[aRequest release];
	
	return loader.data;
}

#pragma mark -

- (id)credentialNamed:(NSString *)inCredentialName {
	return [self.credentials credentialNamed:inCredentialName];
}

- (void)setCredential:(id)inCredential withName:(NSString *)inName {
	[(MPOAuthCredentialConcreteStore *)self.credentials setCredential:inCredential withName:inName];
}

- (void)removeCredentialNamed:(NSString *)inName {
	[(MPOAuthCredentialConcreteStore *)self.credentials removeCredentialNamed:inName];
}

- (void)discardCredentials {
	[self.credentials discardOAuthCredentials];
	
	self.authenticationState = MPOAuthAuthenticationStateUnauthenticated;
}

#pragma mark -
#pragma mark - Private APIs -

- (void)_performedLoad:(MPOAuthAPIRequestLoader *)inLoader receivingData:(NSData *)inData {}

@end
