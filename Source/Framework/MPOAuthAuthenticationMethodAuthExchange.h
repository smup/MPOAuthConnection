//
//  MPOAuthAuthenticationMethodAuthExchange.h
//  MPOAuthMobile
//
//  Created by Karl Adam on 09.12.20.
//  Copyright 2009 matrixPointer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPOAuthAPI.h"
#import "MPOAuthAuthenticationMethod.h"

@class MUMember;
@protocol MPOAuthAuthenticationMethodAuthExchangeDelegate;

@interface MPOAuthAuthenticationMethodAuthExchange : MPOAuthAuthenticationMethod <MPOAuthAPIInternalClient> {
	id <MPOAuthAuthenticationMethodAuthExchangeDelegate> delegate_;
}

@property (nonatomic, readwrite, assign) id <MPOAuthAuthenticationMethodAuthExchangeDelegate> delegate;

@end

@protocol MPOAuthAuthenticationMethodAuthExchangeDelegate <NSObject>
@optional
- (void)authenticationDidSucceed;
- (void)authenticationDidSucceedWithResult:(NSDictionary*)result andMember:(MUMember*)member;
- (void)authenticationDidFailWithError:(NSError *)error;
- (void)authenticationDidFailWithResult:(NSDictionary*)result;
@end
