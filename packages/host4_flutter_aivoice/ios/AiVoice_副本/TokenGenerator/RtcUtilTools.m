//
//  RtcUtilTools.m
//  火山引擎 RTC Token Generator
//  工具类实现
//

#import "RtcUtilTools.h"
#import <CommonCrypto/CommonCrypto.h>

const NSUInteger RTCVersionLength = 3;
const NSUInteger RTCAppIDLength = 24;

@implementation RtcUtilTools

+ (int32_t)getTimestamp {
    return (int32_t)[[NSDate date] timeIntervalSince1970];
}

+ (int32_t)randomInt {
    return arc4random_uniform(99999999) + 1;
}

+ (NSData *)hmacSign:(NSString *)key data:(NSData *)data {
    if (!key || !data) {
        return nil;
    }
    
    const char *keyBytes = [key UTF8String];
    const void *dataBytes = data.bytes;
    
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA256, 
           keyBytes, 
           strlen(keyBytes), 
           dataBytes, 
           data.length, 
           result);
    
    return [NSData dataWithBytes:result length:CC_SHA256_DIGEST_LENGTH];
}

+ (NSString *)base64Encode:(NSData *)data {
    if (!data) {
        return nil;
    }
    
    return [data base64EncodedStringWithOptions:0];
}

+ (NSData *)base64Decode:(NSString *)string {
    if (!string) {
        return nil;
    }
    
    return [[NSData alloc] initWithBase64EncodedString:string options:0];
}

@end
