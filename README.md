# SysExplorer

iOS system monitor and internals explorer. Installs via TrollStore with extended entitlements.

<img src="Screenshot.png" width="300" />

## Features

### Stage 1 — Process List ✅
- Real-time list of all running processes
- PID, process name, RAM usage
- Powered by `proc_listallpids` + `proc_pidinfo` (C system calls)

### Stage 2 — Process Detail (coming soon)
- Memory regions via `mach_vm_region_recurse()`
- Loaded dylibs
- Open file descriptors
- Entitlements via `csops`

### Stage 3 — Mach-O Inspector (coming soon)
- Parse binaries: segments, sections, symbols
- Load commands, code signing info

### Stage 4 — XPC Explorer (coming soon)
- Enumerate XPC services from launchd plists
- Check service availability

### Stage 5 — IOKit Browser (coming soon)
- Full IOKit registry traversal
- Browse classes and properties of every IOService

## Stack

- **UI**: Swift + UIKit
- **System layer**: Objective-C + C
- **Build**: Xcode, iOS 15.0+, arm64

## Requirements

- iPhone with [TrollStore](https://github.com/opa334/TrollStore) installed
- iOS 15.0 – 17.x

## Entitlements

```xml
<key>task_for_pid-allow</key>
<true/>
<key>com.apple.private.security.no-sandbox</key>
<true/>
<key>platform-application</key>
<true/>
<key>com.apple.private.security.no-container</key>
<true/>
```

## Disclaimer

Read-only exploration tool. Does not modify process memory or inject code.
