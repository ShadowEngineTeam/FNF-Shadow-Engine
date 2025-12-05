#ifndef MEMORY_H
#define MEMORY_H

#if defined(_WIN32)
#include <windows.h>
#include <psapi.h>

#elif defined(__APPLE__) && defined(__MACH__)
#include <mach/mach.h>

#elif defined(__linux__) || defined(__gnu_linux__) || defined(__ANDROID__)
#include <stdio.h>

#else
#error "Cannot define getCurrentRSS() for an unknown OS."
#endif

size_t getCurrentRSS(void)
{
#if defined(_WIN32)
    PROCESS_MEMORY_COUNTERS_EX info;
    if (GetProcessMemoryInfo(GetCurrentProcess(),
                             (PROCESS_MEMORY_COUNTERS*)&info,
                             sizeof(info))) {
        return (size_t)info.PrivateUsage;
    }
    return (size_t)0L;

#elif defined(__APPLE__) && defined(__MACH__)
    struct task_vm_info vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;

    if (task_info(mach_task_self(), TASK_VM_INFO,
                  (task_info_t)&vmInfo, &count) == KERN_SUCCESS) {
        return (size_t)vmInfo.internal + (size_t)vmInfo.compressed;
    }
    return (size_t)0L;

#elif defined(__linux__) || defined(__gnu_linux__) || defined(__ANDROID__)
    size_t vmrss = 0, vmswap = 0;
    FILE *fp = fopen("/proc/self/status", "r");
    if (fp) {
        char line[256];
        while (fgets(line, sizeof(line), fp)) {
            if (sscanf(line, "VmRSS: %zu kB", &vmrss) == 1)
                continue;
            if (sscanf(line, "VmSwap: %zu kB", &vmswap) == 1)
                continue;
        }
        fclose(fp);
        return (vmrss + vmswap) * 1024;
    }
    return (size_t)0L;

#else
    return (size_t)0L;
#endif
}

#endif
