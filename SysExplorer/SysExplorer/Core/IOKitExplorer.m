#import "IOKitExplorer.h"
#import <IOKit/IOKitLib.h>

@implementation IOKitEntry
@end

@implementation IOKitExplorer

+ (NSArray<IOKitEntry *> *)getRootEntries {
    NSMutableArray *result = [NSMutableArray array];
    io_registry_entry_t root = IORegistryGetRootEntry(0);
    [self collectEntries:root into:result depth:0 maxDepth:3];
    IOObjectRelease(root);
    return result;
}

+ (void)collectEntries:(io_registry_entry_t)entry into:(NSMutableArray *)result depth:(int)depth maxDepth:(int)maxDepth {
    if (depth > maxDepth) return;

    io_iterator_t iterator = 0;
    if (IORegistryEntryGetChildIterator(entry, kIOServicePlane, &iterator) != KERN_SUCCESS) return;

    io_object_t child;
    while ((child = IOIteratorNext(iterator)) != 0) {
        char name[128] = {0};
        char className[128] = {0};
        IORegistryEntryGetName(child, name);
        IOObjectGetClass(child, className);

        IOKitEntry *e = [[IOKitEntry alloc] init];
        NSString *indent = [@"" stringByPaddingToLength:depth * 2 withString:@" " startingAtIndex:0];
        e.name = [indent stringByAppendingString:[NSString stringWithUTF8String:name]];
        e.className = [NSString stringWithUTF8String:className];
        [result addObject:e];

        [self collectEntries:child into:result depth:depth + 1 maxDepth:maxDepth];
        IOObjectRelease(child);
    }
    IOObjectRelease(iterator);
}

@end
