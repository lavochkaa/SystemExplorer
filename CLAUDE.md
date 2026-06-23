# TrollStore iOS System Explorer

## Проект
iOS-приложение "SysExplorer" — системный монитор и инструмент для исследования iOS internals. Устанавливается через TrollStore с расширенными entitlements.

## Стек
- **UI**: Swift + UIKit (или SwiftUI, на выбор)
- **Low-level логика**: Objective-C и C/C++ (обёртки над системными API)
- **Сборка**: Xcode project, deployment target iOS 15.0+, arm64

## Архитектура

```
SysExplorer/
├── SysExplorer.xcodeproj/
├── SysExplorer/
│   ├── App/
│   │   ├── AppDelegate.swift
│   │   └── SceneDelegate.swift
│   ├── UI/                          # Swift — табы, списки, детали
│   │   ├── ProcessListVC.swift      # Таб 1: список процессов
│   │   ├── ProcessDetailVC.swift    # Детали процесса (memory regions, dylibs)
│   │   ├── XPCExplorerVC.swift      # Таб 2: XPC-сервисы
│   │   ├── MachOInspectorVC.swift   # Таб 3: Mach-O парсер
│   │   └── IOKitBrowserVC.swift     # Таб 4: IOKit дерево
│   ├── Core/                        # ObjC/C++ — системные вызовы
│   │   ├── ProcessManager.h/.m      # sysctl, proc_listpids, proc_pidinfo
│   │   ├── MachPortHelper.h/.m      # task_for_pid, mach_port enumeration
│   │   ├── XPCScanner.h/.m          # Перечисление XPC-сервисов из launchd plists
│   │   ├── MachOParser.h/.mm        # C++ парсер Mach-O (load commands, segments, symbols)
│   │   ├── IOKitExplorer.h/.m       # IOKit registry traversal
│   │   └── EntitlementReader.h/.m   # Чтение entitlements процесса через csops
│   ├── Bridging/
│   │   └── SysExplorer-Bridging-Header.h
│   └── Resources/
│       └── Info.plist
├── SysExplorer.entitlements         # TrollStore entitlements
└── README.md
```

## Entitlements (для TrollStore)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>task_for_pid-allow</key>
    <true/>
    <key>com.apple.private.security.no-sandbox</key>
    <true/>
    <key>platform-application</key>
    <true/>
    <key>com.apple.private.security.no-container</key>
    <true/>
</dict>
</plist>
```

## Фичи (реализовать поэтапно)

### Этап 1 — Process List (C + ObjC)
- `proc_listallpids()` — получить все PID
- `proc_pidinfo()` с `PROC_PIDTASKINFO` — CPU%, memory, threads
- `proc_pidpath()` — путь к бинарю
- UI: таблица с поиском и сортировкой, pull-to-refresh
- **Ключевые хедеры**: `<libproc.h>`, `<sys/sysctl.h>`

### Этап 2 — Process Detail (C/C++ + ObjC)
- Memory regions через `mach_vm_region_recurse()` (нужен `task_for_pid`)
- Загруженные dylibs через `task_info()` + `dyld_all_image_infos`
- Entitlements процесса через `csops(pid, CS_OPS_ENTITLEMENTS_BLOB, ...)`
- Open file descriptors через `proc_pidinfo()` с `PROC_PIDLISTFDS`

### Этап 3 — Mach-O Inspector (C++)
- Парсить бинарь с диска: magic, header, load commands
- Показать segments (TEXT, DATA, LINKEDIT), sections
- Список импортированных/экспортированных символов
- Detect code signing info (LC_CODE_SIGNATURE)
- **Структуры**: `<mach-o/loader.h>`, `<mach-o/nlist.h>`, `<mach-o/fat.h>`

### Этап 4 — XPC Explorer (ObjC)
- Сканировать `/System/Library/LaunchDaemons/` и `/Library/LaunchDaemons/`
- Парсить plist: MachServices, Label, ProgramArguments
- Попробовать `xpc_connection_create_mach_service()` — проверить доступность
- Показать какие сервисы отвечают без аутентификации

### Этап 5 — IOKit Browser (ObjC)
- `IORegistryGetRootEntry()` → рекурсивный обход дерева
- Показать классы, свойства каждого IOService
- Поиск по имени/классу
- **Фреймворк**: `<IOKit/IOKitLib.h>`

## Стиль кода
- C/C++ код — чистый, с комментариями на английском
- Swift UI — минималистичный, тёмная тема
- ObjC bridging — через Bridging Header
- Обработка ошибок: kern_return_t проверять всегда, показывать юзеру readable ошибки
- Никаких force unwrap в Swift

## Важно
- Это **исследовательский инструмент** для изучения iOS internals
- Приложение только читает и отображает системную информацию
- Не модифицирует память других процессов
- Не инжектит код
- Read-only exploration tool

## Порядок работы
1. Начни с создания Xcode проекта и базовой структуры
2. Реализуй Этап 1 (Process List) полностью, протестируй
3. Затем по порядку остальные этапы
4. Каждый этап — отдельный коммит с описанием
