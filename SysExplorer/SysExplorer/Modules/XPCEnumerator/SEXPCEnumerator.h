#pragma once
#import <Foundation/Foundation.h>

@interface SEXPCEnumerator : NSObject
+ (NSArray<NSString *> *)extractStrings:(NSString *)binaryPath;
+ (NSArray<NSString *> *)daemonPlistPaths;
+ (NSDictionary *)parserDaemonPlist:(NSString *)path;
@end
