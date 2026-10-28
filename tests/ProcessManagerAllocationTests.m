#import <Foundation/Foundation.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <sys/param.h>
#include <sys/sysctl.h>

// Compile the production implementation with a deterministic allocation failure.
#define malloc(size) NULL
#import "../SysExplorer/SysExplorer/Core/ProcessManager.m"
#undef malloc

static int fdInfoCalls = 0;

int proc_listallpids(void *buffer, int bufferSize) {
    (void)buffer;
    (void)bufferSize;
    return 0;
}

int proc_pidpath(int pid, void *buffer, uint32_t bufferSize) {
    (void)pid;
    (void)buffer;
    (void)bufferSize;
    return 0;
}

int proc_pidinfo(int pid, int flavor, uint64_t arg, void *buffer, int bufferSize) {
    (void)pid;
    (void)flavor;
    (void)arg;
    (void)bufferSize;
    fdInfoCalls++;
    NSCAssert(buffer == NULL, @"A failed allocation must not reach the second syscall");
    return sizeof(struct proc_fdinfo);
}

int csops(pid_t pid, unsigned int ops, void *userAddress, size_t userSize) {
    (void)pid;
    (void)ops;
    (void)userAddress;
    (void)userSize;
    return -1;
}

int main(void) {
    @autoreleasepool {
        NSArray<NSString *> *files = [ProcessManager getOpenFilesForPid:42];
        NSCAssert(files.count == 0, @"Allocation failure must return an empty array");
        NSCAssert(fdInfoCalls == 1, @"Allocation failure must skip the second syscall");
        puts("Process open-file allocation regression passed");
    }
    return 0;
}
