#!/data/data/com.termux/files/usr/bin/bash

# ============== CONFIGURATION ==============
TOTAL_STEPS=6
CURRENT_STEP=0
DE_NAME="GNOME"

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
        printf "\r  ${GREEN}✓${NC} ${message}                                        \n"
    else
        printf "\r  ${RED}✗${NC} ${message} ${RED}(failed)${NC}                         \n"
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
    echo -e "${PURPLE}[*] Analyzing system architecture...${NC}"
    echo ""
    
    DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
    DEVICE_BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
    CPU_ABI=$(getprop ro.product.cpu.abi 2>/dev/null || echo "arm64-v8a")
    
    echo -e "  ${GREEN}📱${NC} Device: ${WHITE}${DEVICE_BRAND} ${DEVICE_MODEL}${NC}"
    echo -e "  ${GREEN}⚙️${NC}  CPU: ${WHITE}${CPU_ABI}${NC}"
    echo ""
    sleep 1
}

# ============== STEP 1: TERMUX DISPLAY & AUDIO LAYER ==============
step_termux_layer() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Configuring native Termux host environment...${NC}"
    echo ""
    
    (yes | pkg update -y > /dev/null 2>&1 && yes | pkg upgrade -y > /dev/null 2>&1) &
    spinner $! "Syncing Termux repositories"
    
    install_pkg "x11-repo" "X11 Package Repository"
    install_pkg "termux-x11-nightly" "Termux-X11 Display Server"
    install_pkg "pulseaudio" "PulseAudio Sound Server"
    install_pkg "proot-distro" "PRoot Subsystem"
}

# ============== STEP 2: DEPLOY UBUNTU ROOTFS ==============
step_ubuntu() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Deploying Ubuntu LTS Filesystem...${NC}"
    echo ""
    
    echo -e "  ${YELLOW}💡 Extracting filesystem. This may take a few minutes.${NC}"
    
    if proot-distro list | grep -q "ubuntu.*installed"; then
        echo -e "  ${YELLOW}⚠ Existing Ubuntu PRoot detected. Resetting to clean state...${NC}"
        (proot-distro reset ubuntu --assume-yes > /dev/null 2>&1) &
        spinner $! "Resetting existing Ubuntu RootFS"
    else
        (proot-distro install ubuntu > /dev/null 2>&1) &
        spinner $! "Downloading and extracting Ubuntu RootFS"
    fi
}

# ============== STEP 3: PROVISION UBUNTU GUI (GNOME) ==============
step_provision_gui() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing ${DE_NAME} inside Ubuntu...${NC}"
    echo ""
    
    echo -e "  ${YELLOW}💡 Downloading GNOME packages. This is a very heavy operation and will take time.${NC}"
    
    # We use gnome-core instead of ubuntu-desktop to avoid pulling in massive amounts of bloat.
    local PROVISION_CMD="DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get update -yq && \
                         DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get upgrade -yq && \
                         DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -yq sudo nano wget curl dbus-x11 gnome-session gnome-terminal nautilus gnome-tweaks adwaita-icon-theme-full"
                         
    (proot-distro login ubuntu -- bash -c "$PROVISION_CMD" > /dev/null 2>&1) &
    spinner $! "Installing GNOME Session, DBUS, and Core Utilities"
}

# ============== STEP 4: GENERATE BRIDGED LAUNCHER ==============
step_launchers() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Generating bridged launch configurations...${NC}"
    echo ""
    
    cat > ~/start-ubuntu-gnome.sh << 'LAUNCHEREOF'
#!/data/data/com.termux/files/usr/bin/bash

echo "🚀 Booting Ubuntu LTS with GNOME Desktop..."
echo "🔄 Cleaning up active background sessions..."

# Kill existing servers
pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 -f "pulseaudio" 2>/dev/null

# Start Audio Server
echo "🔊 Initializing PulseAudio bridge..."
pulseaudio --start --exit-idle-time=-1
sleep 1
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null

# Start Display Server
echo "📺 Initializing Termux-X11 display server..."
termux-x11 :0 -ac &
sleep 3

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📱 Open the Termux-X11 app to view your Desktop."
echo "  ⚠ GNOME expects hardware acceleration and systemd."
echo "     Performance may be heavy or contain visual glitches."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Launch Ubuntu PRoot with GNOME Session, forcing X11 backend
proot-distro login ubuntu --shared-tmp -- bash -c "export DISPLAY=:0 && export PULSE_SERVER=127.0.0.1 && export XDG_CURRENT_DESKTOP=GNOME && export GDK_BACKEND=x11 && dbus-launch --exit-with-session gnome-session"

LAUNCHEREOF

    chmod +x ~/start-ubuntu-gnome.sh
    echo -e "  ${GREEN}✓${NC} Created ~/start-ubuntu-gnome.sh"
}

# ============== STEP 5: SHORTCUTS & CLEANUP ==============
step_finalize() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Finalizing deployment...${NC}"
    echo ""
    
    chmod 755 ~/start-ubuntu-gnome.sh
    echo -e "  ${GREEN}✓${NC} Permissions secured. System ready."
}

# ============== COMPLETION VIEW ==============
show_completion() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "               UBUNTU GNOME DEPLOYMENT COMPLETE             "
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}  To launch your Ubuntu Desktop:${NC}"
    echo -e "    1. Run this command:  ${GREEN}bash ~/start-ubuntu-gnome.sh${NC}"
    echo -e "    2. Switch to the ${CYAN}Termux-X11${NC} app to see the screen."
    echo ""
}

# ============== ENTRY POINT ==============
main() {
    clear
    echo -e "${WHITE}  Preparing Ubuntu LTS + GNOME execution profile...${NC}"
    echo ""
    
    detect_hardware
    
    step_termux_layer  # Step 1
    step_ubuntu        # Step 2
    step_provision_gui # Step 3
    step_launchers     # Step 4
    step_finalize      # Step 5
    
    show_completion
}

main
