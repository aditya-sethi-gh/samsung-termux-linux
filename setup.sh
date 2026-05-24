#!/data/data/com.termux/files/usr/bin/bash

# ============== CONFIGURATION ==============
TOTAL_STEPS=13
CURRENT_STEP=0
DE_CHOICE="1"
DE_NAME="XFCE4"

# ============== COLORS ==============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'

# ============== PROGRESS FUNCTIONS ==============
update_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    
    FILLED=$((PERCENT / 5))
    EMPTY=$((20 - FILLED))
    
    BAR="${GREEN}"
    for ((i=0; i<FILLED; i++)); do BAR+="█"; done
    BAR+="${GRAY}"
    for ((i=0; i<EMPTY; i++)); do BAR+="░"; done
    BAR+="${NC}"
    
    echo ""
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  📊 PROGRESS: ${WHITE}Step ${CURRENT_STEP}/${TOTAL_STEPS}${NC} ${BAR} ${WHITE}${PERCENT}%${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r  ${YELLOW}⏳${NC} ${message} ${CYAN}${spin:$i:1}${NC}  "
        sleep 0.1
    done
    
    wait $pid
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        printf "\r  ${GREEN}✓${NC} ${message}                    \n"
    else
        printf "\r  ${RED}✗${NC} ${message} ${RED}(failed)${NC}     \n"
    fi
    
    return $exit_code
}

install_pkg() {
    local pkg=$1
    local name=${2:-$pkg}
    (yes | pkg install $pkg -y > /dev/null 2>&1) &
    spinner $! "Installing ${name}"
}

# ============== HARDWARE DETECTION ==============
detect_hardware() {
    echo -e "${PURPLE}[*] Analyzing system hardware...${NC}"
    echo ""
    
    DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
    DEVICE_BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
    ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    CPU_ABI=$(getprop ro.product.cpu.abi 2>/dev/null || echo "arm64-v8a")
    CHIPSET=$(getprop ro.hardware.chipname 2>/dev/null || echo "")
    GPU_VENDOR=$(getprop ro.hardware.egl 2>/dev/null || echo "")
    
    echo -e "  ${GREEN}📱${NC} Device: ${WHITE}${DEVICE_BRAND} ${DEVICE_MODEL}${NC}"
    echo -e "  ${GREEN}🤖${NC} Android: ${WHITE}${ANDROID_VERSION}${NC}"
    echo -e "  ${GREEN}⚙️${NC}  CPU: ${WHITE}${CPU_ABI}${NC}"
    
    if [[ "$GPU_VENDOR" == *"adreno"* ]] || [[ "$CHIPSET" == *"sm"* ]] || [[ "$CHIPSET" == *"kalama"* ]] || [[ "$CHIPSET" == *"taro"* ]] || [[ "$CHIPSET" == *"lahaina"* ]]; then
        GPU_DRIVER="freedreno"
        echo -e "  ${GREEN}🎮${NC} GPU: ${WHITE}Adreno — Turnip HW acceleration available ✓${NC}"
    elif [[ "$CHIPSET" == *"exynos"* ]] || [[ "$CHIPSET" == *"s5e"* ]] || [[ "$GPU_VENDOR" == *"mali"* ]]; then
        GPU_DRIVER="swrast"
        echo -e "  ${YELLOW}🎮${NC} GPU: ${WHITE}Mali — Falling back to software rendering${NC}"
        echo -e "    ${YELLOW}⚠ Turnip GPU acceleration is unavailable on this architecture.${NC}"
    else
        GPU_DRIVER="freedreno"
        echo -e "  ${GREEN}🎮${NC} GPU: ${WHITE}Defaulting to Adreno driver configuration ✓${NC}"
    fi
    
    echo ""
    sleep 1
}

# ============== DESKTOP ENVIRONMENT SELECTION ==============
choose_desktop() {
    echo -e "${CYAN}📺 Select Desktop Environment:${NC}"
    echo ""
    echo -e "  ${WHITE}1) XFCE4${NC}       ${GREEN}(Recommended)${NC} — Performance optimized"
    echo -e "  ${WHITE}2) LXQt${NC}         — Lightweight allocation layout"
    echo -e "  ${WHITE}3) MATE${NC}         — Traditional UI layout"
    echo -e "  ${WHITE}4) KDE Plasma${NC}  — Expanded resource configuration"
    echo ""
    
    while true; do
        read -p "  Enter selection (1-4) [default: 1]: " DE_INPUT < /dev/tty
        DE_INPUT=${DE_INPUT:-1}
        if [[ "$DE_INPUT" =~ ^[1-4]$ ]]; then
            DE_CHOICE="$DE_INPUT"
            break
        else
            echo "  Invalid input. Select 1, 2, 3, or 4."
        fi
    done
    
    case $DE_CHOICE in
        1) DE_NAME="XFCE4";;
        2) DE_NAME="LXQt";;
        3) DE_NAME="MATE";;
        4) DE_NAME="KDE Plasma";;
    esac
    
    echo ""
    echo -e "  ${GREEN}✓ Selected: ${WHITE}${DE_NAME}${NC}"
    echo ""
    sleep 1
}

# ============== STEP 1: UPDATE SYSTEM ==============
step_update() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Syncing package lists...${NC}"
    echo ""
    
    (yes | pkg update -y > /dev/null 2>&1) &
    spinner $! "Updating repository index"
    
    (yes | pkg upgrade -y > /dev/null 2>&1) &
    spinner $! "Upgrading core packages"
}

# ============== STEP 2: INSTALL REPOSITORIES ==============
step_repos() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Adding extra repositories...${NC}"
    echo ""
    
    install_pkg "x11-repo" "X11 Repository"
    install_pkg "tur-repo" "TUR Repository"
}

# ============== STEP 3: INSTALL TERMUX-X11 ==============
step_x11() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Setting up display layer...${NC}"
    echo ""
    
    install_pkg "termux-x11-nightly" "Termux-X11 Server"
    install_pkg "xorg-xrandr" "XRandR Utility"
}

# ============== STEP 4: INSTALL DESKTOP ENVIRONMENT ==============
step_desktop() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Supplying ${DE_NAME} environment files...${NC}"
    echo ""
    
    if [ "$DE_CHOICE" == "1" ]; then
        install_pkg "xfce4" "XFCE4 Base"
        install_pkg "xfce4-terminal" "XFCE4 Terminal"
        install_pkg "xfce4-whiskermenu-plugin" "Whisker Menu"
        install_pkg "plank-reloaded" "Plank"
        install_pkg "thunar" "Thunar"
        install_pkg "mousepad" "Mousepad"
    elif [ "$DE_CHOICE" == "2" ]; then
        install_pkg "lxqt" "LXQt Base"
        install_pkg "qterminal" "QTerminal"
        install_pkg "pcmanfm-qt" "PCManFM-Qt"
        install_pkg "featherpad" "FeatherPad"
    elif [ "$DE_CHOICE" == "3" ]; then
        install_pkg "mate" "MATE Base"
        install_pkg "mate-tweak" "MATE Tweak"
        install_pkg "mate-terminal" "MATE Terminal"
        install_pkg "plank-reloaded" "Plank"
    elif [ "$DE_CHOICE" == "4" ]; then
        install_pkg "plasma-desktop" "KDE Plasma Base"
        install_pkg "konsole" "Konsole"
        install_pkg "dolphin" "Dolphin"
    fi
}

# ============== STEP 5: INSTALL GPU DRIVERS ==============
step_gpu() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Deploying rendering drivers...${NC}"
    echo ""
    
    install_pkg "mesa-zink" "Mesa Zink"
    
    if [ "$GPU_DRIVER" == "freedreno" ]; then
        install_pkg "mesa-vulkan-icd-freedreno" "Turnip Driver"
    else
        install_pkg "mesa-vulkan-icd-swrast" "Software Vulkan"
    fi
    
    install_pkg "vulkan-loader-android" "Vulkan Loader"
}

# ============== STEP 6: INSTALL AUDIO ==============
step_audio() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Setting up sound service...${NC}"
    echo ""
    
    install_pkg "pulseaudio" "PulseAudio Server"
}

# ============== STEP 7: INSTALL BROWSERS & DEV APPS ==============
step_apps() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Provisioning base applications...${NC}"
    echo ""
    
    install_pkg "firefox" "Firefox"
    install_pkg "code-oss" "VS Code"
    install_pkg "vlc" "VLC Player"
    install_pkg "git" "Git"
    install_pkg "wget" "Wget"
    install_pkg "curl" "cURL"
}

# ============== STEP 8: INSTALL PYTHON ==============
step_python() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Initializing Python subsystem...${NC}"
    echo ""
    
    install_pkg "python" "Python 3"
    
    (pip install flask requests beautifulsoup4 > /dev/null 2>&1) &
    spinner $! "Installing basic wheel libraries"
    
    mkdir -p ~/demo_python
    cat > ~/demo_python/app.py << 'PYEOF'
from flask import Flask, render_template_string
app = Flask(__name__)
@app.route("/")
def hello():
    return render_template_string("""
    <html>
        <body style="background-color:#0d1117;color:#58a6ff;font-family:sans-serif;text-align:center;padding:50px">
            <h1>Environment Active</h1>
            <h3>Python environment ready.</h3>
        </body>
    </html>
    """)
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
PYEOF
}

# ============== STEP 9: PLATFORM DEPLOYMENTS ==============
step_metasploit() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Allocating core platform packages...${NC}"
    echo ""
    install_pkg "metasploit" "Framework Base"
    (msfdb init > /dev/null 2>&1) &
    spinner $! "Initializing package runtime database"
}

# ============== STEP 10: ARCHITECTURE RUNTIMES ==============
step_wine() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Processing compatibility translation layers...${NC}"
    echo ""
    
    (pkg remove wine-stable -y > /dev/null 2>&1) &
    spinner $! "Pruning obsolete binaries"
    
    install_pkg "hangover-wine" "Wine Translation Module"
    install_pkg "hangover-wowbox64" "Box64 Subsystem"
    
    ln -sf /data/data/com.termux/files/usr/opt/hangover-wine/bin/wine /data/data/com.termux/files/usr/bin/wine
    ln -sf /data/data/com.termux/files/usr/opt/hangover-wine/bin/winecfg /data/data/com.termux/files/usr/bin/winecfg
    
    wine reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f > /dev/null 2>&1
}

# ============== STEP 11: LAUNCHER ASSETS ==============
step_launchers() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Generating launch configurations...${NC}"
    echo ""
    
    mkdir -p ~/.config
    XDG_INJECT='export XDG_DATA_DIRS=/data/data/com.termux/files/usr/share:${XDG_DATA_DIRS}
export XDG_CONFIG_DIRS=/data/data/com.termux/files/usr/etc/xdg:${XDG_CONFIG_DIRS}'
    
    if [ "$DE_CHOICE" == "4" ]; then
        mkdir -p ~/.config/plasma-workspace/env
        cat > ~/.config/plasma-workspace/env/xdg_fix.sh << KDEXDG
#!/data/data/com.termux/files/usr/bin/bash
${XDG_INJECT}
KDEXDG
        chmod +x ~/.config/plasma-workspace/env/xdg_fix.sh
    fi
    
    cat > ~/.config/hacklab-gpu.sh << 'GPUEOF'
export MESA_NO_ERROR=1
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_GLES_VERSION_OVERRIDE=3.2
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export TU_DEBUG=noconform
export MESA_VK_WSI_PRESENT_MODE=immediate
export ZINK_DESCRIPTORS=lazy
GPUEOF
    if [ "$DE_CHOICE" == "4" ]; then
        echo "export KWIN_COMPOSE=O2ES" >> ~/.config/hacklab-gpu.sh
    else
        echo "${XDG_INJECT}" >> ~/.config/hacklab-gpu.sh
    fi
    
    if ! grep -q "hacklab-gpu.sh" ~/.bashrc 2>/dev/null; then
        echo 'source ~/.config/hacklab-gpu.sh 2>/dev/null' >> ~/.bashrc
    fi
    
    if [ "$DE_CHOICE" == "1" ] || [ "$DE_CHOICE" == "3" ]; then
        mkdir -p ~/.config/autostart
        cat > ~/.config/autostart/plank.desktop << 'PLANKEOF'
[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank
PLANKEOF
    else
        rm -f ~/.config/autostart/plank.desktop 2>/dev/null
    fi
    
    cat > ~/start-hacklab.sh << 'LAUNCHEREOF'
#!/data/data/com.termux/files/usr/bin/bash

export XDG_DATA_DIRS=/data/data/com.termux/files/usr/share:${XDG_DATA_DIRS}
export XDG_CONFIG_DIRS=/data/data/com.termux/files/usr/etc/xdg:${XDG_CONFIG_DIRS}

DESKTOPS=()
declare -A EXEC_CMDS
declare -A KILL_CMDS

if command -v startxfce4 >/dev/null 2>&1; then
    DESKTOPS+=("XFCE4")
    EXEC_CMDS["XFCE4"]="exec startxfce4"
    KILL_CMDS["XFCE4"]="pkill -9 xfce4-session; pkill -9 plank"
fi

if command -v startlxqt >/dev/null 2>&1; then
    DESKTOPS+=("LXQt")
    EXEC_CMDS["LXQt"]="exec startlxqt"
    KILL_CMDS["LXQt"]="pkill -9 lxqt-session"
fi

if command -v mate-session >/dev/null 2>&1; then
    DESKTOPS+=("MATE")
    EXEC_CMDS["MATE"]="exec mate-session"
    KILL_CMDS["MATE"]="pkill -9 mate-session; pkill -9 plank"
fi

if command -v startplasma-x11 >/dev/null 2>&1; then
    DESKTOPS+=("KDE Plasma")
    EXEC_CMDS["KDE Plasma"]="(sleep 5 && pkill -9 plasmashell && plasmashell) > /dev/null 2>&1 & exec startplasma-x11"
    KILL_CMDS["KDE Plasma"]="pkill -9 startplasma-x11; pkill -9 kwin_x11; pkill -9 plasmashell"
fi

if [ ${#DESKTOPS[@]} -eq 0 ]; then
    echo "❌ Missing desktop configuration assets."
    exit 1
fi

SELECTED_DE=""

if [ ${#DESKTOPS[@]} -eq 1 ]; then
    SELECTED_DE="${DESKTOPS[0]}"
else
    echo "📺 Select target desktop session to initialize:"
    echo ""
    for i in "${!DESKTOPS[@]}"; do
        echo "   $((i+1))) ${DESKTOPS[$i]}"
    done
    echo ""
    while true; do
        read -p "Selection (1-${#DESKTOPS[@]}): " DE_INPUT
        if [[ "$DE_INPUT" =~ ^[0-9]+$ ]] && [ "$DE_INPUT" -ge 1 ] && [ "$DE_INPUT" -le "${#DESKTOPS[@]}" ]; then
            SELECTED_DE="${DESKTOPS[$((DE_INPUT-1))]}"
            break
        else
            echo "Invalid entry."
        fi
    done
fi

source ~/.config/hacklab-gpu.sh 2>/dev/null

pkill -9 -f "termux.x11" 2>/dev/null
eval "${KILL_CMDS["${SELECTED_DE}"]}" 2>/dev/null
pkill -9 -f "dbus" 2>/dev/null

unset PULSE_SERVER
pulseaudio --kill 2>/dev/null
sleep 0.5
pulseaudio --start --exit-idle-time=-1
sleep 1
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null
export PULSE_SERVER=127.0.0.1

termux-x11 :0 -ac &
sleep 3
export DISPLAY=:0

eval "${EXEC_CMDS["${SELECTED_DE}"]}"
LAUNCHEREOF
    chmod +x ~/start-hacklab.sh
    
    cat > ~/hacktools.sh << 'TOOLSEOF'
#!/data/data/com.termux/files/usr/bin/bash
while true; do
    clear
    echo "╔═══════════════════════════════════════════════╗"
    echo "║              Utility Interface                ║"
    echo "╠═══════════════════════════════════════════════╣"
    echo "║                                               ║"
    echo "║   1) Core Shell Console                       ║"
    echo "║   2) Run Display Server Connection            ║"
    echo "║   3) Audit Graphics Module Parameters         ║"
    echo "║   0) Exit                                     ║"
    echo "║                                               ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo ""
    read -p "  Select index: " choice
    
    case $choice in
        1) 
            msfconsole
            ;;
        2) 
            bash ~/start-hacklab.sh
            ;;
        3)
            echo ""
            glxinfo 2>/dev/null | grep -i "renderer\|vendor\|version" || echo "mesa-utils package required for query."
            echo ""
            vulkaninfo 2>/dev/null | head -20 || echo "Vulkan module diagnostic omitted."
            echo ""
            read -p "  Press Return to clean buffer..."
            ;;
        0) 
            exit 0
            ;;
        *)
            sleep 1
            ;;
    esac
done
TOOLSEOF
    chmod +x ~/hacktools.sh

    cat > ~/stop-hacklab.sh << 'STOPEOF'
#!/data/data/com.termux/files/usr/bin/bash
pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 -f "pulseaudio" 2>/dev/null
pkill -9 xfce4-session 2>/dev/null
pkill -9 plank 2>/dev/null
pkill -9 lxqt-session 2>/dev/null
pkill -9 mate-session 2>/dev/null
pkill -9 startplasma-x11 2>/dev/null
pkill -9 kwin_x11 2>/dev/null
pkill -9 plasmashell 2>/dev/null
pkill -9 -f "dbus" 2>/dev/null
STOPEOF
    chmod +x ~/stop-hacklab.sh
}

# ============== STEP 12: SHORTCUT ASSETS ==============
step_shortcuts() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Compiling system entry shortcuts...${NC}"
    echo ""
    
    mkdir -p ~/Desktop
    
    case $DE_CHOICE in
        1) TERM_CMD="xfce4-terminal"; TERM_EXEC_FLAG="-e";;
        2) TERM_CMD="qterminal"; TERM_EXEC_FLAG="-e";;
        3) TERM_CMD="mate-terminal"; TERM_EXEC_FLAG="-e";;
        4) TERM_CMD="konsole"; TERM_EXEC_FLAG="-e";;
    esac
    
    cat > ~/Desktop/Firefox.desktop << 'EOF'
[Desktop Entry]
Name=Firefox
Exec=firefox
Icon=firefox
Type=Application
Categories=Network;WebBrowser;
EOF
    
    cat > ~/Desktop/VSCode.desktop << 'EOF'
[Desktop Entry]
Name=VS Code
Exec=code-oss --no-sandbox
Icon=code-oss
Type=Application
Categories=Development;
EOF
    
    cat > ~/Desktop/VLC.desktop << 'EOF'
[Desktop Entry]
Name=VLC Media Player
Exec=vlc
Icon=vlc
Type=Application
Categories=AudioVideo;
EOF
    
    cat > ~/Desktop/Terminal.desktop << EOF
[Desktop Entry]
Name=Terminal
Exec=${TERM_CMD}
Icon=utilities-terminal
Type=Application
Categories=System;TerminalEmulator;
EOF
    
    cat > ~/Desktop/Console.desktop << EOF
[Desktop Entry]
Name=Console
Exec=${TERM_CMD} ${TERM_EXEC_FLAG} msfconsole
Icon=utilities-terminal
Type=Application
Categories=Security;
EOF
    
    cat > ~/Desktop/Windows_Explorer.desktop << 'EOF'
[Desktop Entry]
Name=Windows File Management
Exec=wine winefile
Icon=folder-windows
Type=Application
Categories=System;
EOF
    
    cat > ~/Desktop/Wine_Config.desktop << 'EOF'
[Desktop Entry]
Name=Wine Subsystem Configuration
Exec=wine winecfg
Icon=wine
Type=Application
Categories=Settings;
EOF
    
    chmod +x ~/Desktop/*.desktop 2>/dev/null
}

# ============== STEP 13: RESOURCE FINALIZATION ==============
step_finalize() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Cleaning deployment file permission configurations...${NC}"
    echo ""
    
    chmod -R 755 ~/Desktop 2>/dev/null
    source ~/.config/hacklab-gpu.sh 2>/dev/null
}

# ============== COMPLETION VIEW ==============
show_completion() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "                   INITIALIZATION COMPLETE                  "
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}  Execution Shortcuts Available:${NC}"
    echo -e "    Start Session:   ${GREEN}bash ~/start-hacklab.sh${NC}"
    echo -e "    Stop Session:    ${GREEN}bash ~/stop-hacklab.sh${NC}"
    echo -e "    Utility Menu:    ${GREEN}bash ~/hacktools.sh${NC}"
    echo ""
}

# ============== ENTRY POINT ==============
main() {
    echo -e "${WHITE}  Preparing execution layout profile setup...${NC}"
    echo ""
    
    detect_hardware
    choose_desktop
    
    step_update        # Step 1
    step_repos         # Step 2
    step_x11           # Step 3
    step_desktop       # Step 4
    step_gpu           # Step 5
    step_audio         # Step 6
    step_apps          # Step 7
    step_python        # Step 8
    step_metasploit    # Step 9
    step_wine          # Step 10
    step_launchers     # Step 11
    step_shortcuts     # Step 12
    step_finalize      # Step 13
    
    show_completion
}

main
