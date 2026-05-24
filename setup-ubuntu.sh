#!/data/data/com.termux/files/usr/bin/bash

# ============== CONFIGURATION ==============
TOTAL_STEPS=6
CURRENT_STEP=0

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
    
    echo -e "  ${GREEN}📱${NC} Device: ${WHITE}${DEVICE_BRAND} ${DEVICE_MODEL}${NC}"
    echo -e "  ${GREEN}🤖${NC} Android: ${WHITE}${ANDROID_VERSION}${NC}"
    echo -e "  ${GREEN}⚙️${NC}  CPU: ${WHITE}${CPU_ABI}${NC}"
    echo ""
    sleep 1
}

# ============== STEP 1: UPDATE TERMUX ==============
step_update() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Syncing Termux package lists...${NC}"
    echo ""
    
    (yes | pkg update -y > /dev/null 2>&1) &
    spinner $! "Updating repository index"
    
    (yes | pkg upgrade -y > /dev/null 2>&1) &
    spinner $! "Upgrading core packages"
}

# ============== STEP 2: INSTALL PROOT SUBSYSTEM ==============
step_proot() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing PRoot Distribution Subsystem...${NC}"
    echo ""
    
    install_pkg "proot-distro" "PRoot Environment"
}

# ============== STEP 3: DEPLOY UBUNTU ROOTFS ==============
step_ubuntu() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Deploying Ubuntu LTS RootFS...${NC}"
    echo ""
    
    echo -e "  ${YELLOW}💡 This step downloads a large file and may take a few minutes depending on network speed.${NC}"
    
    # Check if ubuntu is already installed to prevent overwriting without warning
    if proot-distro list | grep -q "ubuntu.*installed"; then
        echo -e "  ${YELLOW}⚠ Ubuntu PRoot is already installed. Resetting environment...${NC}"
        (proot-distro reset ubuntu --assume-yes > /dev/null 2>&1) &
        spinner $! "Resetting existing Ubuntu RootFS"
    else
        (proot-distro install ubuntu > /dev/null 2>&1) &
        spinner $! "Downloading and extracting Ubuntu RootFS"
    fi
}

# ============== STEP 4: PROVISION UBUNTU ==============
step_provision() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Provisioning Ubuntu internal packages...${NC}"
    echo ""
    
    # Run a command inside the proot environment to update it and install basic tools
    (proot-distro login ubuntu -- bash -c "apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && DEBIAN_FRONTEND=noninteractive apt-get install sudo nano curl wget tzdata -y" > /dev/null 2>&1) &
    spinner $! "Installing apt utilities (sudo, nano, curl, wget)"
}

# ============== STEP 5: LAUNCHER ASSETS ==============
step_launchers() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Generating launch configurations...${NC}"
    echo ""
    
    cat > ~/start-ubuntu.sh << 'LAUNCHEREOF'
#!/data/data/com.termux/files/usr/bin/bash
clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 Starting Ubuntu LTS Subsystem..."
echo "  Type 'exit' to return to Termux."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
proot-distro login ubuntu
LAUNCHEREOF

    chmod +x ~/start-ubuntu.sh
    echo -e "  ${GREEN}✓${NC} Created ~/start-ubuntu.sh"
}

# ============== STEP 6: RESOURCE FINALIZATION ==============
step_finalize() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Finalizing deployment...${NC}"
    echo ""
    
    chmod 755 ~/start-ubuntu.sh
    echo -e "  ${GREEN}✓${NC} Permissions secured."
}

# ============== COMPLETION VIEW ==============
show_completion() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "                 UBUNTU DEPLOYMENT COMPLETE                 "
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}  Execution Shortcuts Available:${NC}"
    echo -e "    Start Ubuntu:    ${GREEN}bash ~/start-ubuntu.sh${NC}"
    echo ""
    echo -e "${YELLOW}  Note: You will be logged in as root within the PRoot container.${NC}"
    echo ""
}

# ============== ENTRY POINT ==============
main() {
    clear
    echo -e "${WHITE}  Preparing Ubuntu LTS deployment profile...${NC}"
    echo ""
    
    detect_hardware
    
    step_update        # Step 1
    step_proot         # Step 2
    step_ubuntu        # Step 3
    step_provision     # Step 4
    step_launchers     # Step 5
    step_finalize      # Step 6
    
    show_completion
}

main
