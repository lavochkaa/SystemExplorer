#pragma once
#import <Foundation/Foundation.h>

@interface MachOInfo : NSObject
@property (nonatomic, copy) NSString *arch;
@property (nonatomic, copy) NSString *fileType;
@property (nonatomic) BOOL is64bit;
@property (nonatomic, strong) NSArray<NSString *> *segments;
@property (nonatomic, strong) NSArray<NSString *> *linkedLibraries;
@end

@interface MachOParser : NSObject
+ (MachOInfo *)parseFile:(NSString *)path;
@end