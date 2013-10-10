//
//  MPOAuthAPI.h
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.05.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPOAuthCredentialStore.h"
#import "MPOAuthParameterFactory.h"

extern NSString * const MPOAuthNotificationAccessTokenReceived;
extern NSString * const MPOAuthNotificationAccessTokenRejected;
extern NSString * const MPOAuthNotificationAccessTokenRefreshed;
extern NSString * const MPOAuthNotificationOAuthCredentialsReady;
extern NSString * const MPOAuthNotificationErrorHasOccurred;

extern NSString * const MPOAuthCredentialRequestTokenKey;
extern NSString * const MPOAuthCredentialRequestTokenSecretKey;
extern NSString * const MPOAuthCredentialAccessTokenKey;
extern NSString * const MPOAuthCredentialAccessTokenSecretKey;
extern NSString * const MPOAuthCredentialSessionHandleKey;


typedef enum {
	MPOAuthSignatureSchemePlainText,
	MPOAuthSignatureSchemeHMACSHA1,
	MPOAuthSignatureSchemeRSASHA1
} MPOAuthSignatureScheme;

typedef enum {
	MPOAuthAuthenticationStateUnauthenticated		= 0,
	MPOAuthAuthenticationStateAuthenticating		= 1,
	MPOAuthAuthenticationStateAuthenticated			= 2
} MPOAuthAuthenticationState;

@protocol MPOAuthAPIInternalClient
@end

@class MPOAuthAuthenticationMethod;
@class MPOAuthAPIRequestLoader;

@interface MPOAuthAPI : NSObject <MPOAuthAPIInternalClient> {
@private
	id <MPOAuthCredentialStore, MPOAuthParameterFactory>		credentials_;
	NSURL														*baseURL_;
	NSURL														*authenticationURL_;
	MPOAuthAuthenticationMethod									*authenticationMethod_;
	MPOAuthSignatureScheme										signatureScheme_;
	NSMutableArray												*activeLoaders_;
	MPOAuthAuthenticationState									oauthAuthenticationState_;
}

@property (nonatomic, readonly, retain) id <MPOAuthCredentialStore, MPOAuthParameterFactory> credentials;
@property (nonatomic, readonly, retain) NSURL *baseURL;
@property (nonatomic, readonly, retain) NSURL *authenticationURL;
@property (nonatomic, readwrite, retain) MPOAuthAuthenticationMethod *authenticationMethod;
@property (nonatomic, readwrite, assign) MPOAuthSignatureScheme signatureScheme;

@property (nonatomic, readonly, assign) MPOAuthAuthenticationState authenticationState;


- (id)initWithCredentials:(NSDictionary *)inCredentials andBaseURL:(NSURL *)inURL;
- (id)initWithCredentials:(NSDictionary *)inCredentials authenticationURL:(NSURL *)inAuthURL andBaseURL:(NSURL *)inBaseURL;
- (id)initWithCredentials:(NSDictionary *)inCredentials authenticationURL:(NSURL *)inAuthURL andBaseURL:(NSURL *)inBaseURL autoStart:(BOOL)aFlag;

- (void)authenticateWithParamsBlock:(NSArray *(^)())paramsBlock;
- (BOOL)isAuthenticated;

- (MPOAuthAPIRequestLoader *)performMethod:(NSString *)inMethod withTarget:(id)inTarget andAction:(SEL)inAction;
- (MPOAuthAPIRequestLoader *)performMethod:(NSString *)inMethod atURL:(NSURL *)inURL withParameters:(NSArray *)inParameters withTarget:(id)inTarget andAction:(SEL)inAction;
- (MPOAuthAPIRequestLoader *)performMethod:(NSString *)inMethod atURL:(NSURL *)inURL withParameters:(NSArray *)inParameters withTarget:(id)inTarget andAction:(SEL)inAction withCustomHttpHeaders:(NSDictionary*)customHttpHeaders;
- (MPOAuthAPIRequestLoader *)performPOSTMethod:(NSString *)inMethod atURL:(NSURL *)inURL withParameters:(NSArray *)inParameters withTarget:(id)inTarget andAction:(SEL)inAction;
- (MPOAuthAPIRequestLoader *)performDELETEMethod:(NSString *)inMethod atURL:(NSURL *)inURL withParameters:(NSArray *)inParameters withTarget:(id)inTarget andAction:(SEL)inAction;
- (MPOAuthAPIRequestLoader *)performURLRequest:(NSURLRequest *)inRequest withTarget:(id)inTarget andAction:(SEL)inAction;

- (MPOAuthAPIRequestLoader *)performPOSTImageMethod:(NSString *)inMethod withParameters:(NSArray *)inParameters withImageParamName:(NSString *)imageParamName andImage:(UIImage *)image withTarget:(id)inTarget andAction:(SEL)inAction;

- (NSData *)dataForMethod:(NSString *)inMethod;
- (NSData *)dataForMethod:(NSString *)inMethod withParameters:(NSArray *)inParameters;
- (NSData *)dataForURL:(NSURL *)inURL andMethod:(NSString *)inMethod withParameters:(NSArray *)inParameters;

- (id)credentialNamed:(NSString *)inCredentialName;
- (void)setCredential:(id)inCredential withName:(NSString *)inName;
- (void)removeCredentialNamed:(NSString *)inName;

- (void)discardCredentials;

@end
