# Yubikey WSL2 Switch

A simple bash script to easily switch Yubikey USB devices between Windows and WSL2 environments.

## Problem

When using Yubikey with WSL2, the device can only be accessed by either Windows OR WSL2 at a time. This creates friction when you need to:
- Use Yubikey for 2FA/Windows Hello on Windows side
- Generate SSH keys with hardware security keys in WSL2
- Switch between these use cases frequently

## Solution

This script provides a simple command-line interface to switch Yubikey attachment between Windows and WSL2.

## Prerequisites

1. **Windows 10/11** with WSL2 installed
2. **usbipd-win** installed:
   ```powershell
   winget install --interactive --exact dorssel.usbipd-win
   ```
3. **WSL2 environment** with required packages:
   ```bash
   sudo apt update
   sudo apt install libfido2-dev libfido2-1 fido2-tools
   ```

## Installation

### 1. Download the script
```bash
wget https://raw.githubusercontent.com/ngc-shj/yubikey-wsl2-switch/main/yubikey-switch.sh
chmod +x yubikey-switch.sh
```

### 2. Set up udev rules (WSL2 side)
```bash
sudo nano /etc/udev/rules.d/70-u2f.rules
```

Add the following content:
```
# Yubico YubiKey Touch U2F Security Key (idProduct=0120)
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0120", GROUP="plugdev", MODE="0664", TAG+="uaccess"

# Yubico YubiKey OTP+FIDO+CCID (idProduct=0407)
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", GROUP="plugdev", MODE="0664", TAG+="uaccess"

# Yubico devices - generic rule
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", GROUP="plugdev", MODE="0664", TAG+="uaccess"

# USB device permissions
SUBSYSTEM=="usb", ATTR{idVendor}=="1050", ATTR{idProduct}=="0120", GROUP="plugdev", MODE="0664"
SUBSYSTEM=="usb", ATTR{idVendor}=="1050", ATTR{idProduct}=="0407", GROUP="plugdev", MODE="0664"
```

### 3. Apply udev rules
```bash
# Add user to plugdev group
sudo usermod -a -G plugdev $USER

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Activate new group permissions
newgrp plugdev
```

## Usage

### Basic Commands
```bash
# Show current status (default)
./yubikey-switch.sh
./yubikey-switch.sh status

# Switch to WSL2 (for SSH key generation)
./yubikey-switch.sh wsl

# Switch to Windows (for 2FA, Windows Hello)
./yubikey-switch.sh windows

# Show help
./yubikey-switch.sh help
```

### Short Commands
```bash
./yubikey-switch.sh w    # WSL2
./yubikey-switch.sh win  # Windows
./yubikey-switch.sh s    # Status
./yubikey-switch.sh h    # Help
```

## Typical Workflow

1. **Development work**: `./yubikey-switch.sh wsl`
   ```bash
   # Generate SSH key with hardware security
   ssh-keygen -t ecdsa-sk -f ~/.ssh/id_ecdsa_sk
   
   # Verify Yubikey is accessible
   fido2-token -L
   ```

2. **2FA/Windows authentication**: `./yubikey-switch.sh windows`
   - Use for browser 2FA
   - Windows Hello authentication
   - Other Windows applications

3. **Check status anytime**: `./yubikey-switch.sh`

## Supported Yubikey Models

- YubiKey Touch U2F Security Key (idProduct: 0120)
- YubiKey OTP+FIDO+CCID (idProduct: 0407)
- Other Yubico devices (idVendor: 1050)

## Troubleshooting

### Yubikey not found
```bash
# Check if Yubikey is connected
lsusb | grep 1050

# On Windows side, verify usbipd can see the device
usbipd list | grep -i yubico
```

### Permission denied in WSL2
```bash
# Check device permissions
ls -la /dev/hidraw*

# Re-apply udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### usbipd not found
Make sure usbipd-win is installed:
```powershell
winget install --interactive --exact dorssel.usbipd-win
```

## Contributing

Issues and pull requests are welcome! Please feel free to contribute improvements.

## Author

Created by NOGUCHI Shoji ([@ngc-shj](https://github.com/ngc-shj))

## License

MIT License - see [LICENSE](LICENSE) for details.

## Notes

- Yubikey can only be accessed by Windows OR WSL2 at a time, not both simultaneously
- Physical disconnection of the Yubikey requires re-running the script
- Script automatically handles multiple hidraw device numbers (hidraw0, hidraw1, etc.)
