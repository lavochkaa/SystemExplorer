#import "MachOParser.h"
#include <mach-o/loader.h>
#include <mach-o/fat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>

@implementation MachOInfo
@end

@implementation MachOParser
+ (MachOInfo *)parseFile:(NSString *)path {
    const char *cpath = path.UTF8String;
    int fd = open(cpath, O_RDONLY);
    if (fd < 0) return nil;

    struct stat st;
    fstat(fd, &st);

    void *data = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
    close(fd);
    if (data == MAP_FAILED) return nil;

    MachOInfo *info = [MachOInfo new];

    uint32_t magic = *(uint32_t *)data;

    if (magic == MH_MAGIC_64 || magic == MH_CIGAM_64) {
        info.is64bit = YES;
        struct mach_header_64 *header = (struct mach_header_64 *)data;
        info.arch = (header->cputype == CPU_TYPE_ARM64) ? @"arm64" : @"x86_64";
    } else if (magic == MH_MAGIC || magic == MH_CIGAM) {
        info.is64bit = NO;
        info.arch = @"arm";
    } else {
        munmap(data, st.st_size);
        return nil;
    }

    uint32_t filetype;
    if (info.is64bit) {
        filetype = ((struct mach_header_64 *)data)->filetype;
    } else {
        filetype = ((struct mach_header *)data)->filetype;
    }

    switch (filetype) {
        case MH_EXECUTE: info.fileType = @"Executable"; break;
        case MH_DYLIB:   info.fileType = @"Dynamic Library"; break;
        case MH_BUNDLE:  info.fileType = @"Bundle"; break;
        default:         info.fileType = @"Unknown"; break;
    }

    NSMutableArray *segments = [NSMutableArray array];
    NSMutableArray *libraries = [NSMutableArray array];

    uint8_t *ptr;
    uint32_t ncmds;

    if (info.is64bit) {
        struct mach_header_64 *h = (struct mach_header_64 *)data;
        ncmds = h->ncmds;
        ptr = (uint8_t *)data + sizeof(struct mach_header_64);
    } else {
        struct mach_header *h = (struct mach_header *)data;
        ncmds = h->ncmds;
        ptr = (uint8_t *)data + sizeof(struct mach_header);
    }

    for (uint32_t i = 0; i < ncmds; i++) {
        struct load_command *lc = (struct load_command *)ptr;

        if (lc->cmd == LC_SEGMENT_64) {
            struct segment_command_64 *seg = (struct segment_command_64 *)ptr;
            [segments addObject:[NSString stringWithUTF8String:seg->segname]];
        } else if (lc->cmd == LC_LOAD_DYLIB) {
            struct dylib_command *dylib = (struct dylib_command *)ptr;
            const char *name = (const char *)ptr + dylib->dylib.name.offset;
            [libraries addObject:[NSString stringWithUTF8String:name]];
        }

        ptr += lc->cmdsize;
    }

    info.segments = segments;
    info.linkedLibraries = libraries;

    munmap(data, st.st_size);
    return info;
}
@end
