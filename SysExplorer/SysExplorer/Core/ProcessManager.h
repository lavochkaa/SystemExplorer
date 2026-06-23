#import <Foundation/Foundation.h>

@interface SysProcessInfo : NSObject
@property (nonatomic) pid_t pid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic) uint64_t memoryBytes;
@end

@interface ProcessManager : NSObject
+ (NSArray<SysProcessInfo *> *)getAllProcesses;
@end