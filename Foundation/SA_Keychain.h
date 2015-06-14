//
//  SA_Keychain.h
//
//  Created by Ben Gottlieb & Patrick McCarron on 7/28/14.
//  Copyright (c) 2014 Stand Alone, inc. All rights reserved.
//

//
//  NOTE About Keychain Sharing's Access Groups
//
//  Access Groups are setup inside the Xcode Target -> Capabilities screen.
//  By default the Application will use this group for Keychain use, it does NOT need to be specified.
//  If you wish to specify a specific Access Group it must be the entire "APP_ID.com.company.groupname" string.
//

#import <Foundation/Foundation.h>

@interface SA_KeychainEntry : NSObject
@property (nonatomic, strong) NSString *username, *password, *identifier;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, readonly) BOOL isDataEntry;

+ (instancetype) keychainEntryWithUsername: (NSString *) username password: (NSString *) password andIdentifier: (NSString *) identifier;
+ (instancetype) keychainEntryWithData: (NSData *) data andIdentifier: (NSString *) identifier;

@end

@interface SA_Keychain : NSObject

+ (instancetype) defaultKeychain;

- (SA_KeychainEntry *) entryForIdentifier: (NSString *) identifier;
- (SA_KeychainEntry *) entryForIdentifier: (NSString *) identifier inAccessGroup: (NSString *) group;

- (BOOL) doesEntryExistForIdentifier: (NSString *) identifier;
- (BOOL) doesEntryExistForIdentifier: (NSString *) identifier inAccessGroup: (NSString *) group;

- (BOOL) storeEntry: (SA_KeychainEntry *) entry;
- (BOOL) storeEntry: (SA_KeychainEntry *) entry inAccessGroup: (NSString *) group;

- (void) clearEntryForIdentifier: (NSString *) identifier;
- (void) clearEntryForIdentifier: (NSString *) identifier inAccessGroup: (NSString *) group;

@end
