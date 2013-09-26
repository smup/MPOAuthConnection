//
//  MPOAuthAuthenticationMethodAuthExchange.m
//  MPOAuthMobile
//
//  Created by Karl Adam on 09.12.20.
//  Copyright 2009 matrixPointer. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>
#import "MPOAuthAuthenticationMethodAuthExchange.h"
#import "MPOAuthAPI.h"
#import "MPOAuthAPIRequestLoader.h"
#import "MPOAuthCredentialStore.h"
#import "MPURLRequestParameter.h"
#import "MUAppDelegate.h"
#import "MULocationManager.h"

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

- (void)authenticate {
	id <MPOAuthCredentialStore> credentials = [self.oauthAPI credentials];
	
	if (!credentials.accessToken && !credentials.accessTokenSecret) {
		
		NSMutableArray *params = [[NSMutableArray alloc] initWithCapacity:2];
		
		NSString *fbAccessToken = nil;
        FBSession * fbSession = FBSession.activeSession;
        if (fbSession.state == FBSessionStateOpen) {
            fbAccessToken = fbSession.accessToken;
        }
		if ([fbAccessToken length] > 0) {
			MPURLRequestParameter *accessTokenParameter = [[MPURLRequestParameter alloc] initWithName:@"fb_token" andValue:fbAccessToken];
			[params addObject:accessTokenParameter];
		}
		else {
			NSString *name = [[self.oauthAPI credentials] name];
			NSString *email = [[self.oauthAPI credentials] username];
			NSString *password = [[self.oauthAPI credentials] password];
			NSAssert(email, @"AuthExchange requires a email credential");
			NSAssert(password, @"AuthExchange requires a Password credential");
            CLLocation *lastKnownLocation = [[MULocationManager sharedLocationManager] lastKnownLocation];
            
            if (lastKnownLocation != nil) {
                NSString * latString = [[NSNumber numberWithFloat:[lastKnownLocation coordinate].latitude] stringValue];
                MPURLRequestParameter * lat = [[MPURLRequestParameter alloc] initWithName:@"lat" andValue:latString];
                [params addObject:lat];

                NSString * lonString = [[NSNumber numberWithFloat:[lastKnownLocation coordinate].longitude] stringValue];
                MPURLRequestParameter * lon = [[MPURLRequestParameter alloc] initWithName:@"lon" andValue:lonString];
                [params addObject:lon];
            }
		
			MPURLRequestParameter *fieldsParameter = [[MPURLRequestParameter alloc] initWithName:@"fields" andValue:@"gender,birthday,city_id"];
			[params addObject:fieldsParameter];

			MPURLRequestParameter *usernameParameter = [[MPURLRequestParameter alloc] initWithName:@"email" andValue:email];
			[params addObject:usernameParameter];

			MPURLRequestParameter *passwordParameter = [[MPURLRequestParameter alloc] initWithName:@"password" andValue:password];
			[params addObject:passwordParameter];
            
            if ([name length] > 0) {
                MPURLRequestParameter *nameParameter = [[MPURLRequestParameter alloc] initWithName:@"name" andValue:name];
                [params addObject:nameParameter];
            }
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
