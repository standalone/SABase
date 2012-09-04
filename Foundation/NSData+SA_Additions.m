//
//  NSData+Additions.m
//
//  Created by Ben Gottlieb on 1/5/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import "NSData+SA_Additions.h"
#import "NSString+SA_Additions.h"
#import <CommonCrypto/CommonHMAC.h>


//=============================================================================================================================
#pragma mark Base 64
static char					k_encodingTable[64] = {
								'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
								'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
								'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
								'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/' };

#define xx 65

static unsigned char base64DecodeLookup[256] =
{
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 62, xx, xx, xx, 63, 
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, xx, xx, xx, xx, xx, xx, 
    xx,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, xx, xx, xx, xx, xx, 
    xx, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
};

void * ImprovedBase64Decode(const char *inputBuffer, size_t length, size_t *outputLength);

#define BINARY_UNIT_SIZE 3
#define BASE64_UNIT_SIZE 4

void * ImprovedBase64Decode(const char *inputBuffer, size_t length, size_t *outputLength) {
	if (length == -1)
	{
		length = strlen(inputBuffer);
	}
	
	size_t outputBufferSize =
	((length+BASE64_UNIT_SIZE-1) / BASE64_UNIT_SIZE) * BINARY_UNIT_SIZE;
	unsigned char *outputBuffer = (unsigned char *)malloc(outputBufferSize);
	
	size_t i = 0;
	size_t j = 0;
	while (i < length)
	{
		//
		// Accumulate 4 valid characters (ignore everything else)
		//
		unsigned char accumulated[BASE64_UNIT_SIZE] = {};
		size_t accumulateIndex = 0;
		while (i < length)
		{
			unsigned char decode = base64DecodeLookup[inputBuffer[i++]];
			if (decode != xx)
			{
				accumulated[accumulateIndex] = decode;
				accumulateIndex++;
				
				if (accumulateIndex == BASE64_UNIT_SIZE)
				{
					break;
				}
			}
		}
		
		//
		// Store the 6 bits from each of the 4 characters as 3 bytes
		//
		outputBuffer[j] = (accumulated[0] << 2) | (accumulated[1] >> 4);
		outputBuffer[j + 1] = (accumulated[1] << 4) | (accumulated[2] >> 2);
		outputBuffer[j + 2] = (accumulated[2] << 6) | accumulated[3];
		j += accumulateIndex - 1;
	}
	
	if (outputLength) {
		*outputLength = j;
	}
	return outputBuffer;
}


@implementation NSData (NSData_SA_Additions)

- (NSString *) base64Encoded  {
	return [self base64EncodingWithLineLength: 0]; 
}

+ (NSData *) dataWithBase64EncodedString: (NSString *) aString {
	NSData *data = [aString dataUsingEncoding:NSASCIIStringEncoding];
	size_t outputLength;
	void *outputBuffer = ImprovedBase64Decode([data bytes], [data length], &outputLength);
	NSData *result = [NSData dataWithBytes:outputBuffer length:outputLength];
	free(outputBuffer);
	return result;
}

- (NSString *) base64EncodingWithLineLength:(unsigned int) lineLength {
	const unsigned char     *bytes = [self bytes];
	NSMutableString			*result = [NSMutableString stringWithCapacity:[self length]];
	unsigned long			ixtext = 0;
	unsigned long			lentext = [self length];
	long					ctremaining = 0;
	unsigned char			inbuf[3], outbuf[4];
	unsigned short			i = 0, charsonline = 0, ctcopy = 0;
	unsigned long			ix = 0;

	while (YES) {
		ctremaining = lentext - ixtext;
		if (ctremaining <= 0) break;

		for(i = 0; i < 3; i++) {
			ix = ixtext + i;
			if (ix < lentext) 
				inbuf[i] = bytes[ix];
			else 
				inbuf [i] = 0;
		}
		outbuf [0] = (inbuf [0] & 0xFC) >> 2;
		outbuf [1] = ((inbuf [0] & 0x03) << 4) | ((inbuf [1] & 0xF0) >> 4);
		outbuf [2] = ((inbuf [1] & 0x0F) << 2) | ((inbuf [2] & 0xC0) >> 6);
		outbuf [3] = inbuf [2] & 0x3F;
		ctcopy = 4;
		
		switch( ctremaining ) {
			case 1:
				ctcopy = 2;
				break;

			case 2:
				ctcopy = 3;
				break;
		}
		
		for( i = 0; i < ctcopy; i++ )
			[result appendFormat:@"%c", k_encodingTable[outbuf[i]]];
			for (i = ctcopy; i < 4; i++) {
				[result appendString: @"="];
			}
			ixtext += 3;
			charsonline += 4;
			
			if (lineLength > 0 ) {
				if (charsonline >= lineLength ) {
					charsonline = 0;
					[result appendString:@"\n"];
				}
			}
	}

	return [NSString stringWithString:result];
}

//=============================================================================================================================
#pragma mark 
+ (NSData *) dataWithString: (NSString *) string {
	if (string == nil) return nil;
	const char			*raw = [string UTF8String];
	return [NSData dataWithBytes: raw length: strlen(raw)];
}


- (NSString *) descriptionWithLineWidth: (int) lineWidth includingHex: (BOOL) includingHex includingASCII: (BOOL) includingASCII {
	#define MAXDATABYTES 1024

    unsigned char					*bytes = (unsigned char *)[self bytes];
    NSInteger						length = [self length];
    NSMutableString					*buf = [NSMutableString stringWithFormat: @"NSData %d bytes:\n", (int) length];
    int								i, j;
	
    for (i = 0 ; i < length ; i += lineWidth) {
        if (i > MAXDATABYTES) {      // don't print too much!
            [buf appendString: @"\n...\n"];
            break;
        }
		
		if (includingHex) for (j = 0 ; j < lineWidth ; j++) {   // Show the row in Hex
            int					offset = i + j;
			
            if (offset < length)  {
                [buf appendFormat: @"%02X ", bytes[offset]];
            }  else {
                [buf appendFormat: @"   "];
            }
        }
        if (includingHex && includingASCII) [buf appendString:@"| "];   // now show in ASCII
        if (includingASCII) for (j = 0 ; j < lineWidth; j++) {
            int offset = i + j;
            if (offset < length) {
                unsigned char						theChar = bytes[offset];
                
				if (theChar < 32 || theChar > 127) theChar ='.';
                [buf appendFormat:@"%c", theChar];
            }
        }
        [buf appendString:@"\n"];
    }
    [buf deleteCharactersInRange:NSMakeRange([buf length]-1, 1)];
    return buf;
} 

- (NSString *) description {
	return [NSMutableString stringWithFormat: @"NSData %d bytes:\n%@", (int) self.length, [self descriptionWithLineWidth: 32 includingHex: YES includingASCII: YES]];
}

- (NSString *) stringValue {
	char				*raw = (char *) malloc(self.length + 1);
	char				zero = 0;

	memmove(raw, self.bytes, self.length);
	
	
	memmove(&raw[self.length], &zero, 1);
	NSString			*str = [NSString stringWithCString: raw encoding: NSASCIIStringEncoding];
	free(raw);
	return str;
}

- (NSString *) saveToTempFile {
	NSString				*filePath = [NSString tempFileNameWithSeed: @"data" ofType: @"txt"];
	NSError					*error = nil;
	
	if (![self writeToFile: filePath options: 0 error: &error]) return [NSString stringWithFormat: @"Failed to save file: %@", error];
	return filePath;
}

- (NSString *) hexStringWithSpaces: (BOOL) spaces {
	unsigned char					*bytes = (unsigned char *)[self bytes];
	NSInteger						length = [self length];
	NSMutableString					*buf = [NSMutableString string];
	NSString						*format = spaces ? @"%02X " : @"%02X";
	
	for (int i = 0; i < length; i++) {
		[buf appendFormat: format, bytes[i]];
    }
    return buf;
}

- (NSUInteger) offsetOfBytes: (unsigned char *) bytes length: (NSUInteger) length {
	return [self offsetOfBytes: bytes length: length inRange: NSMakeRange(0, self.length)];
} 

- (NSUInteger) offsetOfBytes: (unsigned char *) bytes length: (NSUInteger) length inRange: (NSRange) range {
	NSUInteger						i, dataLength = range.length - (length - 1);
	unsigned char					*data = (unsigned char *) [self bytes];
	
	for (i = range.location; i < dataLength; i++) {
		if (data[i] == bytes[0] && (length == 0 || memcmp(&data[i + 1], &bytes[1], length - 1) == 0)) return i;
	}
	
	return NSNotFound;
} 

- (BOOL) nullTerminateIfPossible {
	if (self.length == 0) return NO;
	
	NSRange					lastByteRange = NSMakeRange(self.length - 1, 1);
	char					lastByte;
	
	@try {
		[self getBytes: &lastByte range: lastByteRange];
	} @catch (id e) {
		return NO;
	}
	
	if (lastByte == 0) return YES;		//already 0, bail
	
	if (![self respondsToSelector: @selector(appendBytes:length:)]) return NO;		//can't append (not mutable)
	
	lastByte = 0;
	[(id) self appendBytes: &lastByte length: 1];
	return YES;
}

//=============================================================================================================================
#pragma mark SHA1
- (NSData *) SHA1DataWithKeyText: (NSString *) keyText {
	/*
	 inputs:
	 NSData *keyData;
	 NSData *clearTextData
	 */
	
	uint8_t							digest[CC_SHA1_DIGEST_LENGTH] = {0};
	CCHmacContext					hmacContext;
	NSData							*keyData = [NSData dataWithString: keyText];
	
	CCHmacInit(&hmacContext, kCCHmacAlgSHA1, keyData.bytes, keyData.length);
	CCHmacUpdate(&hmacContext, self.bytes, self.length);
	CCHmacFinal(&hmacContext, digest);
	
	NSData							*result = [NSData dataWithBytes: digest length: CC_SHA1_DIGEST_LENGTH];
	
	return result;
}

- (BOOL) appearsToBeXML {
	NSData				*firstPart = [self subdataWithRange: NSMakeRange(0, 15)];
	
	return memcmp((char *) [firstPart bytes], "<?xml version=\"", 15) == 0;
}

@end
