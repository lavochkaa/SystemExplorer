#import <Foundation/Foundation.h>

@interface IOKitEntry : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *className;
@end

@interface IOKitExplorer : NSObject
+ (NSArray<IOKitEntry *> *)getRootEntries;
+ (void)collectEntries:(uint32_t)entry into:(NSMutableArray *)result depth:(int)depth maxDepth:(int)maxDepth;
@end
