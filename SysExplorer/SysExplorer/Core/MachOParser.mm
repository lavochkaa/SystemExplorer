#import "MachOParser.h"
#include <mach-o/loader.h>
#include <mach-o/fat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <cstring>

@implementation MachOInfo
@end

@implementation MachOParser
+ (MachOInfo *)parseFile:(NSString *)path {
    const char *cpath = path.UTF8String;
    if (!cpath) return nil;
    int fd = open(cpath, O_RDONLY);
    if (fd < 0) return nil;

    struct stat st;
    if (fstat(fd, &st) != 0 || st.st_size < (off_t)sizeof(uint32_t)) {
        close(fd);
        return nil;
    }

    const size_t size = (size_t)st.st_size;
    void *data = mmap(NULL, size, PROT_READ, MAP_PRIVATE, fd, 0);
    close(fd);
    if (data == MAP_FAILED) return nil;

    const uint8_t *bytes = (const uint8_t *)data;
    uint32_t magic;
    memcpy(&magic, bytes, sizeof(magic));
    size_t headerSize;
    uint32_t ncmds, sizeofcmds, filetype;
    MachOInfo *info = [MachOInfo new];

    if (magic == MH_MAGIC_64 && size >= sizeof(struct mach_header_64)) {
        struct mach_header_64 header;
        memcpy(&header, bytes, sizeof(header));
        headerSize = sizeof(header);
        ncmds = header.ncmds;
        sizeofcmds = header.sizeofcmds;
        filetype = header.filetype;
        info.is64bit = YES;
        info.arch = (header.cputype == CPU_TYPE_ARM64) ? @"arm64" : @"x86_64";
    } else if (magic == MH_MAGIC && size >= sizeof(struct mach_header)) {
        struct mach_header header;
        memcpy(&header, bytes, sizeof(header));
        headerSize = sizeof(header);
        ncmds = header.ncmds;
        sizeofcmds = header.sizeofcmds;
        filetype = header.filetype;
        info.is64bit = NO;
        info.arch = @"arm";
    } else {
        munmap(data, size);
        return nil;
    }

    if (sizeofcmds > size - headerSize || ncmds > sizeofcmds / sizeof(struct load_command)) {
        munmap(data, size);
        return nil;
    }

    switch (filetype) {
        case MH_EXECUTE: info.fileType = @"Executable"; break;
        case MH_DYLIB:   info.fileType = @"Dynamic Library"; break;
        case MH_BUNDLE:  info.fileType = @"Bundle"; break;
        default:         info.fileType = @"Unknown"; break;
    }

    NSMutableArray *segments = [NSMutableArray array];
    NSMutableArray *libraries = [NSMutableArray array];

    size_t offset = headerSize;
    size_t remaining = sizeofcmds;

    for (uint32_t i = 0; i < ncmds; i++) {
        if (remaining < sizeof(struct load_command)) {
            munmap(data, size);
            return nil;
        }
        struct load_command lc;
        memcpy(&lc, bytes + offset, sizeof(lc));
        if (lc.cmdsize < sizeof(lc) || lc.cmdsize > remaining) {
            munmap(data, size);
            return nil;
        }

        if (lc.cmd == LC_SEGMENT_64) {
            if (lc.cmdsize < sizeof(struct segment_command_64)) {
                munmap(data, size);
                return nil;
            }
            struct segment_command_64 seg;
            memcpy(&seg, bytes + offset, sizeof(seg));
            size_t length = strnlen(seg.segname, sizeof(seg.segname));
            NSString *name = [[NSString alloc] initWithBytes:seg.segname length:length encoding:NSUTF8StringEncoding];
            if (!name) {
                munmap(data, size);
                return nil;
            }
            [segments addObject:name];
        } else if (lc.cmd == LC_LOAD_DYLIB || lc.cmd == LC_LOAD_WEAK_DYLIB ||
                   lc.cmd == LC_REEXPORT_DYLIB || lc.cmd == LC_LOAD_UPWARD_DYLIB) {
            if (lc.cmdsize < sizeof(struct dylib_command)) {
                munmap(data, size);
                return nil;
            }
            struct dylib_command dylib;
            memcpy(&dylib, bytes + offset, sizeof(dylib));
            size_t nameOffset = dylib.dylib.name.offset;
            if (nameOffset < sizeof(dylib) || nameOffset >= lc.cmdsize) {
                munmap(data, size);
                return nil;
            }
            const char *nameStart = (const char *)bytes + offset + nameOffset;
            const char *end = (const char *)memchr(nameStart, '\0', lc.cmdsize - nameOffset);
            if (!end) {
                munmap(data, size);
                return nil;
            }
            NSString *name = [[NSString alloc] initWithBytes:nameStart length:end - nameStart encoding:NSUTF8StringEncoding];
            if (!name) {
                munmap(data, size);
                return nil;
            }
            [libraries addObject:name];
        }

        offset += lc.cmdsize;
        remaining -= lc.cmdsize;
    }
    if (remaining != 0) {
        munmap(data, size);
        return nil;
    }

    info.segments = segments;
    info.linkedLibraries = libraries;

    munmap(data, size);
    return info;
}
@end
