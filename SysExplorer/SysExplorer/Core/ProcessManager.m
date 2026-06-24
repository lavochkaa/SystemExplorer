#import "ProcessManager.h"
#include <sys/sysctl.h>

// libproc.h is not in public iOS SDK, declare what we need manually
extern int proc_listallpids(void *buffer, int buffersize);
extern int proc_pidpath(int pid, void *buffer, uint32_t buffersize);

#define PROC_PIDTASKINFO 4
#define PROC_PIDLISTFDS 1
#define PROX_FDTYPE_VNODE 1
#define PROX_FDTYPE_SOCKET 2
#define PROX_FDTYPE_PIPE 6

struct proc_fdinfo {
    int32_t proc_fd;
    uint32_t proc_fdtype;
};

#include <sys/param.h>

struct proc_taskinfo {
    uint64_t pti_virtual_size;
    uint64_t pti_resident_size;
    uint64_t pti_total_user;
    uint64_t pti_total_system;
    uint64_t pti_threads_user;
    uint64_t pti_threads_system;
    int32_t  pti_policy;
    int32_t  pti_faults;
    int32_t  pti_pageins;
    int32_t  pti_cow_faults;
    int32_t  pti_messages_sent;
    int32_t  pti_messages_received;
    int32_t  pti_syscalls_mach;
    int32_t  pti_syscalls_unix;
    int32_t  pti_csw;
    int32_t  pti_threadnum;
    int32_t  pti_numrunning;
    int32_t  pti_priority;
};

extern int proc_pidinfo(int pid, int flavor, uint64_t arg, void *buffer, int buffersize);


@implementation SysProcessInfo
@end

@implementation ProcessManager

+ (NSArray<SysProcessInfo *> *)getAllProcesses {
    // Fixed buffer to avoid blocking call with NULL on simulator
    int maxPids = 1024;
    pid_t *pids = malloc(maxPids * sizeof(pid_t));
    int count = proc_listallpids(pids, maxPids * sizeof(pid_t));
    if (count <= 0) { free(pids); return @[]; }

    NSMutableArray *result = [NSMutableArray array];

    for (int i = 0; i < 10; i++) {
        pid_t pid = pids[i];

        char pathBuffer[MAXPATHLEN];
        proc_pidpath(pid, pathBuffer,  sizeof(pathBuffer));

        struct proc_taskinfo taskInfo;
        int ret = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, sizeof(taskInfo));
        
        SysProcessInfo *info = [[SysProcessInfo alloc] init];
        info.pid = pid;
        info.name = [[NSString stringWithUTF8String:pathBuffer] lastPathComponent] ?: @"unknown";
        info.path = [NSString  stringWithUTF8String:pathBuffer];
        info.memoryBytes = (ret > 0) ? taskInfo.pti_resident_size : 0;
        info.threadCount = (ret > 0) ? taskInfo.pti_threadnum : 0;

        [result addObject:info];
    }

    free(pids);
    return result;


}

+ (NSArray<NSString *> *)getOpenFilesForPid:(pid_t)pid {
    int bufferSize = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, NULL, 0);
    if (bufferSize <= 0) return @[];

    struct proc_fdinfo *fds = malloc(bufferSize);
    int count = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, fds, bufferSize);
    count /= sizeof(struct proc_fdinfo);

    NSMutableArray *result = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        NSString *type;
        switch (fds[i].proc_fdtype) {
            case PROX_FDTYPE_VNODE: type = @"file"; break;
            case PROX_FDTYPE_SOCKET: type = @"socket"; break;
            case PROX_FDTYPE_PIPE: type = @"pipe"; break;
            default: type = @"other"; break;
        }
        [result addObject:[NSString stringWithFormat:@"fd%d: %@", fds[i].proc_fd, type]];
    }
    free(fds);
    return result;
}

@end
