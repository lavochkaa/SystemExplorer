#import "SEXPCEnumerator.h"
#include <MacTypes.h>
#include <Foundation/Foundation.h>
#include <cstdint>
#include <mach-o/loader.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>

@implementation SEXPCEnumerator
+ (NSArray<NSString *> *)extractStrings:(NSString *)binaryPath {
    // variables
    uint8_t *ptr;
    uint32_t ncmds;

    bool found = NO;
    uint32_t resultOffset = 0;
    uint64_t resultSize = 0;

    // Step 1: open + mmap the file (see MachOParser.mm for the pattern)
    int fd = open(binaryPath.UTF8String, O_RDONLY);
    if (fd < 0) return @[];

    struct stat st;
    fstat(fd, &st);

    void *data = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
    close(fd);
    if (data == MAP_FAILED) return @[];

    struct mach_header_64 *header = (struct mach_header_64 *)data;
    ncmds = header->ncmds;
    ptr = (uint8_t *)data + sizeof(struct mach_header_64);
    
    // Step 2: walk load commands, find LC_SEGMENT_64 with segname == "__TEXT"
    for (uint32_t i = 0; i < ncmds; i++) {
        struct load_command *lc = (struct load_command *)ptr;
        if (lc->cmd == LC_SEGMENT_64) {
            struct segment_command_64 *seg = (struct segment_command_64 *)ptr;
            if (strcmp(seg->segname, "__TEXT") == 0) {
                // section_64[] идет сразу же после segment_command_64 в памяти
                // Step 3: walk that segment's section_64 array, find sectname == "__cstring"
                struct section_64 *sect = (struct section_64 *)(seg + 1);
                for (uint32_t s = 0; s < seg->nsects; s++) {
                    if (strcmp(sect[s].sectname, "__cstring") == 0) {
                        // тогда нам это укажет диапазон
                        found = YES;
                        resultOffset = sect[s].offset;
                        resultSize = sect[s].size;

                        if (!(resultOffset + resultSize <= (uint64_t)st.st_size)) {
                            NSLog(@"SEXPCEnumetator: Err: st.st_size (%lld) < offset (%u) + size (%llu)",
                                (long long)st.st_size, sect[s].offset, sect[s].size);
                            found = NO;
                            break;
                        }
                        break;
                    }
                }
            }
        }

        ptr += lc->cmdsize;
    }
    if (!found) {
        munmap(data, st.st_size);
        return @[];
    }
    // Step 4: slice out [data + section->offset, section->offset + section->size)
    const char *base = (const char *)data + resultOffset;
    const char *cursor = base;
    size_t remaining = (size_t)resultSize;

    NSMutableArray<NSString *> *strings = [NSMutableArray array];

    while (cursor < base + resultSize) {
        // Step 5: split that range on '\0' into NSStrings
        size_t len = strnlen(cursor, remaining);
        NSString *s = [[NSString alloc] initWithBytes:cursor length:(len) encoding:(NSUTF8StringEncoding)];
        
        size_t check = len + 1;
        if (check > remaining) break;
        cursor += len + 1;
        remaining = (base + resultSize) - cursor;

        if (s) {
            [strings addObject:s];
        }
    }
    munmap(data, st.st_size);
    return strings;
}
@end
