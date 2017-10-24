//
//  SA_Keychain.m
//
//  Created by Ben Gottlieb & Patrick McCarron on 7/28/14.
//  Copyright (c) 2014 Stand Alone, inc. All rights reserved.
//

#import "SA_Keychain.h"
#import <Security/Security.h>

#define SET_ACCESS_GROUP	(!TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR == NO)

#define kKeychainDataKey @"kKeychainDataKey"

@interface SA_KeychainEntry ()
@property (nonatomic, readonly) id payload;
@end

@implementation SA_KeychainEntry
@synthesize data = _data, username = _username, password = _password, identifier = _identifier;

+ (instancetype) keychainEntryWithUsername: (NSString *) username password: (NSString *) password andIdentifier: (NSString *) identifier {
    SA_KeychainEntry *entry = [[SA_KeychainEntry alloc] init];
    entry.username = username;
    entry.password = password;
    entry.identifier = identifier;
    return entry;
}

+ (instancetype) keychainEntryWithData: (NSData *) data andIdentifier: (NSString *) identifier {
    SA_KeychainEntry *entry = [[SA_KeychainEntry alloc] init];
    entry.username = kKeychainDataKey;
    entry.password = nil;
    entry.data = data;
    entry.identifier = identifier;
    return entry;
}

- (BOOL) isDataEntry {
    return ([self.username caseInsensitiveCompare:kKeychainDataKey] == NSOrderedSame);
}

- (NSString *) description {
    NSUInteger dataLength = self.isDataEntry ? self.data.length : self.password.length;
	return [NSString stringWithFormat: @"SA_KeychainEntry Identifier: %@ Username: %@ %@ Length: %lu", self.identifier, self.username, self.isDataEntry ? @"Data" : @"Password", (unsigned long) dataLength];
}

- (id) payload {
	NSData *data = self.isDataEntry ? self.data : [self.password dataUsingEncoding: NSUTF8StringEncoding];
	return data;
}

@end

@implementation SA_Keychain

static SA_Keychain *s_defaultKeychain = nil;
+ (instancetype) defaultKeychain {
	static dispatch_once_t  once; dispatch_once(&once, ^ { s_defaultKeychain = [[self alloc] init]; });
	return s_defaultKeychain;
}

- (SA_KeychainEntry *) entryForIdentifier: (NSString *) identifier {
    return [self entryForIdentifier:identifier inAccessGroup:nil];
}

- (SA_KeychainEntry *) entryForIdentifier: (NSString *) identifier inAccessGroup: (NSString *) group {
    if (identifier == nil) return nil;
    
    NSMutableDictionary *attributes = [@{
                                         (id)CFBridgingRelease(kSecClass):              CFBridgingRelease(kSecClassGenericPassword),
                                         (id)CFBridgingRelease(kSecAttrService):        identifier,
                                         (id)CFBridgingRelease(kSecReturnAttributes):   @YES,
                                         (id)CFBridgingRelease(kSecMatchLimit):         CFBridgingRelease(kSecMatchLimitOne)
                                         } mutableCopy];
    if (group && SET_ACCESS_GROUP) {
        [attributes setObject:group forKey:(id)CFBridgingRelease(kSecAttrAccessGroup)];
    }
    
    @try {
        NSDictionary *result = nil;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) attributes, (void*)&result);
        
        if (status == errSecSuccess && [result isKindOfClass:[NSDictionary class]]) {
            SA_KeychainEntry *entry = [[SA_KeychainEntry alloc] init];
            entry.identifier = identifier;
            entry.username = (NSString *) [result objectForKey: (__bridge NSString *) kSecAttrAccount];
            if ([entry isDataEntry]) {
                entry.data = [result objectForKey: (__bridge NSString *) kSecAttrGeneric];
                entry.password = nil;
            } else {
				NSData				*raw = [result objectForKey: (__bridge NSString *) kSecAttrGeneric];
				
				if ([raw isKindOfClass: [NSString class]])
					entry.password = (id) raw;
				else if ([raw isKindOfClass: [NSData class]])
					entry.password = [[NSString alloc] initWithData: raw encoding:NSUTF8StringEncoding];
                entry.data = nil;
            }
            return entry;
        } else if (status == errSecItemNotFound) {
            return nil;
        } else {
            NSLog(@"Error fetching keychain item %@ status:%d - result: %@", identifier, (int)status, result);
        }
    } @catch (id e) {
        NSLog(@"Exception fetching keychain item");
        return nil;
    }
    
    return nil;
}

- (BOOL) doesEntryExistForIdentifier: (NSString *) identifier { return [self doesEntryExistForIdentifier: identifier inAccessGroup: nil]; }
- (BOOL) doesEntryExistForIdentifier: (NSString *) identifier inAccessGroup: (NSString *) group {
	if (identifier == nil) return NO;
	
	NSMutableDictionary *attributes = [@{
										 (id)CFBridgingRelease(kSecClass):              CFBridgingRelease(kSecClassGenericPassword),
										 (id)CFBridgingRelease(kSecAttrService):        identifier,
										 (id)CFBridgingRelease(kSecMatchLimit):         CFBridgingRelease(kSecMatchLimitOne)
										 } mutableCopy];
	if (group && SET_ACCESS_GROUP) {
		[attributes setObject:group forKey:(id)CFBridgingRelease(kSecAttrAccessGroup)];
	}
	
	@try {
		NSDictionary *result = nil;
		OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) attributes, (void*)&result);
		
		if (status == errSecSuccess) return YES;
	} @catch (id e) {
		NSLog(@"Exception fetching keychain item");
		return NO;
	}
	
	return NO;
}


- (BOOL) storeEntry: (SA_KeychainEntry *) entry {
	return [self storeEntry:entry inAccessGroup:nil];
}

- (BOOL) storeEntry: (SA_KeychainEntry *) entry inAccessGroup: (NSString *) group {
    if (entry == nil || (entry.password == nil && entry.data == nil) || entry.username == nil || entry.identifier == nil) return NO;
	
    SA_KeychainEntry *existingEntry = [self entryForIdentifier:entry.identifier inAccessGroup:group];
	OSStatus		status;
	
    if (existingEntry) {
        BOOL dataTypeIsTheSame = (existingEntry.isDataEntry == entry.isDataEntry);
		NSAssert(dataTypeIsTheSame, @"Keychain entry data type changed when updating entry with identifier %@.", entry.identifier);
		if (!dataTypeIsTheSame) return NO;
		
        BOOL entryChanged = (![existingEntry.data isEqual: entry.data] || ![existingEntry.password isEqual: entry.password] || ![existingEntry.username isEqual: entry.username]);
        if (entryChanged) {
            NSMutableDictionary *attributes = [@{
                                                 (id)CFBridgingRelease(kSecClass):         CFBridgingRelease(kSecClassGenericPassword),
                                                 (id)CFBridgingRelease(kSecAttrService):   existingEntry.identifier,
                                                 (id)CFBridgingRelease(kSecAttrLabel):     existingEntry.identifier,
                                                 (id)CFBridgingRelease(kSecAttrAccount):   existingEntry.username
                                                 } mutableCopy];
            
            if (group && SET_ACCESS_GROUP) {
                [attributes setObject:group forKey:(id)CFBridgingRelease(kSecAttrAccessGroup)];
            }
            
            NSDictionary *updateData = @{
                                         (id)CFBridgingRelease(kSecAttrGeneric):   entry.payload,
                                         (id)CFBridgingRelease(kSecAttrAccount):   entry.username,
                                         };
            
            @try {
                OSStatus		status = SecItemUpdate((__bridge CFDictionaryRef) attributes, (__bridge CFDictionaryRef) updateData);
				if (status == errSecSuccess) return YES;
				NSLog(@"Error while updating entry for %@: %d", entry.identifier, (int) status);
				return NO;
            } @catch (id e) {
                NSLog(@"Error storing keychain entry");
				return NO;
            }
            
        }
    } else {
        NSMutableDictionary *attributes = [@{
                                             (id)CFBridgingRelease(kSecClass):         CFBridgingRelease(kSecClassGenericPassword),
                                             (id)CFBridgingRelease(kSecAttrService):   entry.identifier,
                                             (id)CFBridgingRelease(kSecAttrLabel):     entry.identifier,
                                             (id)CFBridgingRelease(kSecAttrAccount):   entry.username,
                                             (id)CFBridgingRelease(kSecAttrGeneric):   entry.payload
                                             } mutableCopy];
        
        if (group && SET_ACCESS_GROUP) {
            [attributes setObject:group forKey:(id)CFBridgingRelease(kSecAttrAccessGroup)];
        }
        
        @try {
            status = SecItemAdd((__bridge CFDictionaryRef) attributes, NULL);
			if (status == errSecSuccess) return YES;
			NSLog(@"Error while storing entry for %@: %d", entry.identifier, (int) status);
			return NO;
        } @catch (id e) {
			
        }
    }
	return NO;
}

- (void) clearEntryForIdentifier: (NSString *) identifier {
    [self clearEntryForIdentifier:identifier inAccessGroup:nil];
}

- (void) clearEntryForIdentifier: (NSString *) identifier inAccessGroup: (NSString *) group {
    NSMutableDictionary *attributes = [@{
                                         (id)CFBridgingRelease(kSecClass):              CFBridgingRelease(kSecClassGenericPassword),
                                         (id)CFBridgingRelease(kSecAttrService):        identifier,
                                         (id)CFBridgingRelease(kSecReturnAttributes):   @NO
                                         } mutableCopy];
    
    if (group && SET_ACCESS_GROUP) {
        [attributes setObject:group forKey:(id)CFBridgingRelease(kSecAttrAccessGroup)];
    }
    @try {
        SecItemDelete((__bridge CFDictionaryRef) attributes);
    } @catch (id e) {
        NSLog(@"Error clearing keychain entries");
    }
}

@end
