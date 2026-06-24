#import <Foundation/Foundation.h>

@interface SysProcessInfo : NSObject
@property (nonatomic) pid_t pid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic) uint64_t memoryBytes;
@property (nonatomic) int32_t threadCount;
@end

@interface ProcessManager : NSObject
+ (NSArray<SysProcessInfo *> *)getAllProcesses;
@end