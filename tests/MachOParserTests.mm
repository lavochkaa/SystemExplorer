#import <Foundation/Foundation.h>
#include <mach-o/loader.h>
#include <mach/machine.h>
#include <cstring>
#include <vector>
#import "../SysExplorer/SysExplorer/Core/MachOParser.h"

static MachOInfo *parse(const std::vector<uint8_t> &bytes) {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    NSData *data = [NSData dataWithBytes:bytes.data() length:bytes.size()];
    if (![data writeToFile:path atomically:YES]) return nil;
    MachOInfo *info = [MachOParser parseFile:path];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    return info;
}

template <typename T>
static void append(std::vector<uint8_t> &bytes, const T &value) {
    const auto *start = reinterpret_cast<const uint8_t *>(&value);
    bytes.insert(bytes.end(), start, start + sizeof(value));
}

int main() {
    @autoreleasepool {
        mach_header_64 header = {};
        header.magic = MH_MAGIC_64;
        header.cputype = CPU_TYPE_ARM64;
        header.filetype = MH_EXECUTE;

        std::vector<uint8_t> valid;
        append(valid, header);
        MachOInfo *validInfo = parse(valid);
        if (!validInfo || ![validInfo.arch isEqualToString:@"arm64"] ||
            ![validInfo.fileType isEqualToString:@"Executable"]) return 1;

        std::vector<uint8_t> truncated = {0xcf, 0xfa, 0xed, 0xfe};
        if (parse(truncated)) return 2;

        header.ncmds = 1;
        header.sizeofcmds = sizeof(load_command);
        std::vector<uint8_t> missingCommand;
        append(missingCommand, header);
        if (parse(missingCommand)) return 3;

        load_command emptyCommand = {};
        std::vector<uint8_t> zeroCommand = missingCommand;
        append(zeroCommand, emptyCommand);
        if (parse(zeroCommand)) return 4;

        header.ncmds = 2;
        header.sizeofcmds = 16;
        std::vector<uint8_t> shortSecondCommand;
        append(shortSecondCommand, header);
        load_command firstCommand = {LC_UUID, 12};
        append(shortSecondCommand, firstCommand);
        shortSecondCommand.resize(shortSecondCommand.size() + 8);
        if (parse(shortSecondCommand)) return 7;

        dylib_command library = {};
        library.cmd = LC_LOAD_DYLIB;
        library.cmdsize = sizeof(library) + 8;
        library.dylib.name.offset = sizeof(library);
        header.ncmds = 1;
        header.sizeofcmds = library.cmdsize;
        std::vector<uint8_t> validLibrary;
        append(validLibrary, header);
        append(validLibrary, library);
        const char name[8] = {'l', 'i', 'b', '.', 'd', 'y', 'l', '\0'};
        validLibrary.insert(validLibrary.end(), name, name + sizeof(name));
        MachOInfo *libraryInfo = parse(validLibrary);
        if (!libraryInfo || libraryInfo.linkedLibraries.count != 1 ||
            ![libraryInfo.linkedLibraries[0] isEqualToString:@"lib.dyl"]) return 5;

        std::vector<uint8_t> invalidLibraryOffset = validLibrary;
        size_t offsetField = sizeof(header) + offsetof(dylib_command, dylib.name.offset);
        uint32_t outOfBoundsOffset = library.cmdsize;
        memcpy(invalidLibraryOffset.data() + offsetField, &outOfBoundsOffset, sizeof(outOfBoundsOffset));
        if (parse(invalidLibraryOffset)) return 8;

        validLibrary.back() = 'x';
        if (parse(validLibrary)) return 6;
    }
    puts("8 Mach-O parser cases passed");
    return 0;
}
