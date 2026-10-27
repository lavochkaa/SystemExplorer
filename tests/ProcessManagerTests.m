#import <Foundation/Foundation.h>
#import "../SysExplorer/SysExplorer/Core/ProcessManager.h"

static int listCalls = 0;

int proc_listallpids(void *buffer, int bufferSize) {
    listCalls++;
    int capacity = bufferSize / (int)sizeof(pid_t);
    int count = MIN(capacity, 1030);
    pid_t *pids = buffer;
    for (int i = 0; i < count; i++) pids[i] = i + 1;
    return count;
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
    (void)buffer;
    (void)bufferSize;
    return 0;
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
        NSArray<SysProcessInfo *> *processes = [ProcessManager getAllProcesses];
        NSCAssert(processes.count == 1030, @"Process enumeration must grow beyond 1024 PIDs");
        NSCAssert(listCalls == 2, @"A full first buffer must trigger a retry");
        NSCAssert(processes.lastObject.pid == 1030, @"The last PID must be present");
        puts("Process enumeration regression passed");
    }
    return 0;
}
