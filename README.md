# SysSnap
## Linux System & Network Management Script

SysSnap is a bash shell script that provides an interactive dialog-based GUI to manage system updates, Snap packages, and network/system information. It’s designed for Linux systems (tested on Linux Mint) and uses dialog for menus and information display.


### 📋 SysSnap Main Menu
```
├── 0) Show Disk Space
├── 1) System Info
│    ├── 1) Memory usage
│    ├── 2) CPU info
│    ├── 3) System load
│    └── 4) Back
├── 2) Network Tools
│    ├── 1) View my Public IP
│    ├── 2) View Active Connections
│    ├── 3) Show Local IPs(All Connected Profiles)
│    └── 4) Back
├── 3) Fetch System Updates
│    ├── 1) Fetch System Updates
│    ├── 2) List/Update Available Systems Updates
│    └── 3) Back
├── 4) Snap Management
│    ├── 1) Show All Snap Versions
│    ├── 2) Remove Disabled Snaps
│    └── 3) Empty Snap Cache Directory
│    └── 4) Back
└── 5) Exit
```

### ⚙️ Requirements

* dialog package installed
* nmcli (NetworkManager CLI) for network info
* curl (for public IP)
* sudo privileges for system updates