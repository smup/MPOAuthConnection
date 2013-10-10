//
//  MPOAuthAuthenticationMethodAuthExchange.m
//  MPOAuthMobile
//
//  Created by Karl Adam on 09.12.20.
//  Copyright 2009 matrixPointer. All rights reserved.
//

#import "MPOAuthAuthenticationMethodAuthExchange.h"
#import "MPOAuthAPI.h"
#import "MPOAuthAPIRequestLoader.h"
#import "MPOAuthCredentialStore.h"
#import "MPURLRequestParameter.h"

#import <libxml/parser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

//TODO: Remove this!
#define kMPOAuthTokenRefreshDateDefaultsKey			@"MPOAuthAutomaticTokenRefreshLastExpiryDate"
@interface MPOAuthAPI ()
@property (nonatomic, readwrite, assign) MPOAuthAuthenticationState authenticationState;
@end

@implementation MPOAuthAuthenticationMethodAuthExchange

// @synthesize delegate = delegate_;

- (id)initWithAPI:(MPOAuthAPI *)inAPI forURL:(NSURL *)inURL withConfiguration:(NSDictionary *)inConfig {
	if (self = [super initWithAPI:inAPI forURL:inURL withConfiguration:inConfig]) {
		self.oauthGetAccessTokenURL = [NSURL URLWithString:[inConfig objectForKey:MPOAuthAccessTokenURLKey]];
	}
	return self;
}

- (void)authenticateWithParamsBlock:(NSArray *(^)())paramsBlock
{
	id <MPOAuthCredentialStore> credentials = [self.oauthAPI credentials];
	
	if (!credentials.accessToken && !credentials.accessTokenSecret) {
		
        NSArray *params = nil;
        if (paramsBlock) {
            params = paramsBlock();
        }
        
		[self.oauthAPI performPOSTMethod:nil
								   atURL:self.oauthGetAccessTokenURL
						  withParameters:params
							  withTarget:self
							   andAction:nil];
		
	} else if (credentials.accessToken && credentials.accessTokenSecret) {
		NSTimeInterval expiryDateInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:kMPOAuthTokenRefreshDateDefaultsKey];
		if (expiryDateInterval) {
			NSDate *tokenExpiryDate = [NSDate dateWithTimeIntervalSinceReferenceDate:expiryDateInterval];
			
			if ([tokenExpiryDate compare:[NSDate date]] == NSOrderedAscending) {
				[self refreshAccessToken];
			}
		}
	}	
	
}

- (void)_performedLoad:(MPOAuthAPIRequestLoader *)inLoader receivingData:(NSData *)inData {
	// make sure string is xml, if not, then throw an error
    NSData *data = [[inLoader responseString] dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary * results = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
        if ([self.delegate respondsToSelector:@selector(authenticationDidFailWithError:)]) {
            [self.delegate authenticationDidFailWithError:error];
        }
        return;
    }
    
    NSString * problem = [results objectForKey:@"problem"];
    if ([problem length] > 0) {

		[self.oauthAPI removeCredentialNamed:kMPOAuthCredentialPassword];
		if ([self.delegate respondsToSelector:@selector(authenticationDidFailWithResult:)]) {
			[self.delegate authenticationDidFailWithResult:results];
		}
   }
    else {
        
        NSString * oauth_token = [results objectForKey:@"oauth_token"];
        NSString * oauth_token_secret = [results objectForKey:@"oauth_token_secret"];
        
        if (([oauth_token length] > 0) && ([oauth_token_secret length] > 0)) {

            [self.oauthAPI removeCredentialNamed:kMPOAuthCredentialPassword];
            [self.oauthAPI setCredential:oauth_token withName:kMPOAuthCredentialAccessToken];
            [self.oauthAPI setCredential:oauth_token_secret withName:kMPOAuthCredentialAccessTokenSecret];
            
            // no expiration time
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kMPOAuthTokenRefreshDateDefaultsKey];
            
            [self.oauthAPI setAuthenticationState:MPOAuthAuthenticationStateAuthenticated];
            if ([self.delegate respondsToSelector:@selector(authenticationDidSucceedWithResult:andMember:)]) {
                [self.delegate authenticationDidSucceedWithResult:results andMember:nil];
            }
            else if ([self.delegate respondsToSelector:@selector(authenticationDidSucceed)]) {
                [self.delegate authenticationDidSucceed];
            }
            
        }
        else {
            
            [self.oauthAPI removeCredentialNamed:kMPOAuthCredentialPassword];
            
            NSDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:1];
            
            NSError *nsError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:-1 userInfo:userInfo];
            if ([self.delegate respondsToSelector:@selector(authenticationDidFailWithError:)]) {
                [self.delegate authenticationDidFailWithError:nsError];
            }
                        
        }
    }
	
}

#pragma mark -

- (void)loader:(MPOAuthAPIRequestLoader *)loader didFailWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(authenticationDidFailWithError:)]) {
        [self.delegate authenticationDidFailWithError:error];
    }    
}

@end
