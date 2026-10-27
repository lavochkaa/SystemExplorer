#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import "../SysExplorer/SysExplorer/Core/IOKitExplorer.h"

static bool iteratorUsed[106];
static int releases = 0;

io_registry_entry_t IORegistryGetRootEntry(mach_port_t mainPort) {
    (void)mainPort;
    return 1;
}

kern_return_t IORegistryEntryGetChildIterator(io_registry_entry_t entry,
                                               const io_name_t plane,
                                               io_iterator_t *iterator) {
    (void)plane;
    *iterator = entry + 100;
    return KERN_SUCCESS;
}

io_object_t IOIteratorNext(io_iterator_t iterator) {
    if (iterator >= 105 || iteratorUsed[iterator]) return 0;
    iteratorUsed[iterator] = true;
    return iterator - 99;
}

kern_return_t IORegistryEntryGetName(io_registry_entry_t entry, io_name_t name) {
    snprintf(name, sizeof(io_name_t), "depth%u", entry - 1);
    return KERN_SUCCESS;
}

kern_return_t IOObjectGetClass(io_object_t object, io_name_t className) {
    (void)object;
    snprintf(className, sizeof(io_name_t), "MockService");
    return KERN_SUCCESS;
}

kern_return_t IOObjectRelease(io_object_t object) {
    (void)object;
    releases++;
    return KERN_SUCCESS;
}

int main(void) {
    @autoreleasepool {
        NSArray<IOKitEntry *> *entries = [IOKitExplorer getRootEntries];
        NSCAssert(entries.count == 3, @"Only three child levels should be shown");
        NSCAssert([entries[0].name isEqualToString:@"depth1"], @"First child must be shown");
        NSCAssert([entries[2].name isEqualToString:@"    depth3"], @"Third child must be shown");
        NSCAssert(releases == 7, @"Every returned object and iterator must be released");
        puts("IOKit depth regression passed");
    }
    return 0;
}
