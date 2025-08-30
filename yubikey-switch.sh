#!/bin/bash
# yubikey-switch.sh
# Yubikey WSL2 Switch - Switch Yubikey between Windows and WSL2
# Author: Your Name
# License: MIT

TARGET=${1:-"status"}

# usbipd実行（警告完全抑制）
run_usbipd() {
    local cmd="$1"
    local show_output="$2"
    
    if command -v usbipd.exe >/dev/null 2>&1; then
        local output=$(usbipd.exe $cmd 2>/dev/null)
    elif powershell.exe -Command "Get-Command usbipd -ErrorAction SilentlyContinue" >/dev/null 2>&1; then
        local output=$(powershell.exe -Command "usbipd $cmd" 2>/dev/null)
    else
        echo "❌ usbipd not found"
        return 1
    fi
    
    # 警告メッセージを除去
    output=$(echo "$output" | grep -v "warning:" | grep -v "Unknown USB filter")
    
    if [ "$show_output" = "show" ]; then
        echo "$output"
    fi
    
    # 成功判定
    if echo "$output" | grep -q -E "successfully|attached|detached" || [ -z "$output" ]; then
        return 0
    else
        return 1
    fi
}

get_yubikey_busid() {
    run_usbipd "list" show | grep -E "Yubico|1050:" | awk '{print $1}' | head -1
}

show_help() {
    echo "Yubikey WSL2 Switch"
    echo ""
    echo "USAGE:"
    echo "    $0 {wsl|windows|status|help}"
    echo ""
    echo "COMMANDS:"
    echo "    wsl, w       Attach Yubikey to WSL2"
    echo "    windows, win Detach Yubikey from WSL2 (back to Windows)"
    echo "    status, s    Show current attachment status"
    echo "    help, h      Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "    $0 wsl       # Switch to WSL2"
    echo "    $0 windows   # Switch to Windows" 
    echo "    $0           # Show status (default)"
    echo ""
    echo "NOTE:"
    echo "    Yubikey can only be used by Windows OR WSL2 at a time, not both."
}

show_status() {
    local busid=$(get_yubikey_busid)
    if [ -z "$busid" ]; then
        echo "❌ Yubikey not found"
        return 1
    fi
    
    local status_line=$(run_usbipd "list" show | grep "$busid")
    echo "📋 $status_line"
    
    if echo "$status_line" | grep -q "Attached"; then
        echo "🔗 Currently: WSL2"
    else
        echo "🪟 Currently: Windows"
    fi
}

case "$TARGET" in
    "wsl"|"w")
        busid=$(get_yubikey_busid)
        if [ -n "$busid" ]; then
            echo "🔄 Switching to WSL2..."
            run_usbipd "bind --busid $busid" >/dev/null 2>&1
            sleep 1
            if run_usbipd "attach --wsl --busid $busid" >/dev/null 2>&1; then
                echo "✅ Switched to WSL2"
            else
                sleep 2
                if run_usbipd "attach --wsl --busid $busid" >/dev/null 2>&1; then
                    echo "✅ Switched to WSL2"
                else
                    echo "❌ Failed to switch to WSL2"
                fi
            fi
        else
            echo "❌ Yubikey not found"
        fi
        ;;
    
    "windows"|"win")
        busid=$(get_yubikey_busid)
        if [ -n "$busid" ]; then
            echo "🔄 Switching to Windows..."
            if run_usbipd "detach --busid $busid" >/dev/null 2>&1; then
                echo "✅ Switched to Windows"
            else
                if ! run_usbipd "list" | grep "$busid" | grep -q "Attached"; then
                    echo "✅ Already on Windows"
                else
                    echo "❌ Failed to switch to Windows"
                fi
            fi
        else
            echo "❌ Yubikey not found"
        fi
        ;;
    
    "status"|"s")
        show_status
        ;;
    
    "help"|"h"|"-h"|"--help")
        show_help
        ;;
    
    *)
        echo "❌ Unknown command: $TARGET"
        echo ""
        show_help
        exit 1
        ;;
esac