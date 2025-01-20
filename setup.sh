#!/bin/bash

# Files to save the lists
TERMUX_PACKAGES_FILE="installed_packages.txt"
PIP_PACKAGES_FILE="installed_pip_packages.txt"
ERROR_LOG="setup_errors.log"

# Colors for formatting
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Spinner characters
SPINNER=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

# Check for ncurses (required for tput)
if ! command -v tput &> /dev/null; then
    echo -e "${YELLOW}Installing ncurses-utils (required for tput)...${RESET}"
    pkg install ncurses-utils -y
    if ! command -v tput &> /dev/null; then
        echo -e "${RED}Error: ncurses-utils installation failed. Exiting...${RESET}"
        exit 1
    fi
fi

# Function to display a spinner while a command is running
spinner() {
    local pid=$1
    local message="$2"
    local delay=0.1
    local i=0

    # Hide the cursor
    tput civis

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % 10 ))
        printf "\r${BLUE}%s ${SPINNER[$i]}${RESET}" "$message"
        sleep "$delay"
    done

    # Clear the spinner and show the cursor
    printf "\r\033[K"
    tput cnorm
}

# Function to check if a command was successful
check_success() {
    if [ $? -ne 0 ]; then
        echo -e "\r${RED}Error: $1 failed.${RESET}"
        return 1
    else
        echo -e "\r${GREEN}Success: $1 completed.${RESET}"
    fi
}

# Function to log errors
log_error() {
    echo -e "${RED}Error: $1${RESET}" >> "$ERROR_LOG"
}

# Function to ask for user confirmation
ask_confirm() {
    local prompt="$1"
    while true; do
        read -rp "$(echo -e "${BLUE}$prompt (y/n): ${RESET}")" response
        case "$response" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo -e "${YELLOW}Please answer yes (y) or no (n).${RESET}" ;;
        esac
    done
}

# Function to install additional Termux packages
install_additional_termux_packages() {
    echo -e "${BLUE}Installing additional Termux packages...${RESET}"
    local packages=(
        termux-tools
    )

    for package in "${packages[@]}"; do
        apt install -y "$package" > /dev/null 2>> "$ERROR_LOG" &
        spinner $! "Installing $package"
        if ! check_success "apt install $package"; then
            echo -e "${YELLOW}Skipping $package due to errors.${RESET}"
            log_error "Failed to install $package."
        fi
    done
}

# Function to install Termux GUI packages
install_termux_gui_packages() {
    echo -e "${BLUE}Installing Termux GUI packages...${RESET}"
    local packages=(
        termux-gui-bash
        termux-gui-c
        termux-gui-package
        termux-gui-pm
        termux-am
        termux-am-socket
        termux-api
        termux-api-static
        termux-apt-repo
        termux-auth
        termux-create-package
        termux-elf-cleaner
        termux-exec
        termux-keyring
        termux-licenses
        termux-services
    )

    for package in "${packages[@]}"; do
        apt install -y "$package" > /dev/null 2>> "$ERROR_LOG" &
        spinner $! "Installing $package"
        if ! check_success "apt install $package"; then
            echo -e "${YELLOW}Skipping $package due to errors.${RESET}"
            log_error "Failed to install $package."
        fi
    done
}

# Function to restore Termux packages
restore_termux_packages() {
    echo -e "${BLUE}Restoring Termux packages...${RESET}"
    if [ -f "$TERMUX_PACKAGES_FILE" ]; then
        while read -r package; do
            apt install -y "$package" > /dev/null 2>> "$ERROR_LOG" &
            spinner $! "Installing $package"
            if ! check_success "apt install $package"; then
                echo -e "${YELLOW}Skipping $package due to errors.${RESET}"
                log_error "Failed to install $package."
            fi
        done < "$TERMUX_PACKAGES_FILE"

        # Attempt to fix broken dependencies
        apt-get install -f -y > /dev/null 2>> "$ERROR_LOG" &
        spinner $! "Fixing broken dependencies"
        if ! check_success "apt-get install -f"; then
            log_error "Failed to fix broken dependencies."
        fi
    else
        echo -e "${RED}Error: $TERMUX_PACKAGES_FILE not found. Please ensure the backup file exists.${RESET}"
        log_error "$TERMUX_PACKAGES_FILE not found."
    fi
}

# Function to restore pip packages
restore_pip_packages() {
    echo -e "${BLUE}Restoring pip packages...${RESET}"
    if [ -f "$PIP_PACKAGES_FILE" ]; then
        pip install -r "$PIP_PACKAGES_FILE" > /dev/null 2>> "$ERROR_LOG" &
        spinner $! "Restoring pip packages"
        if ! check_success "pip install -r $PIP_PACKAGES_FILE"; then
            log_error "Failed to restore pip packages."
        fi
    else
        echo -e "${RED}Error: $PIP_PACKAGES_FILE not found. Please ensure the backup file exists.${RESET}"
        log_error "$PIP_PACKAGES_FILE not found."
    fi
}

# Function to install and configure Termux GUI
install_termux_gui() {
    echo -e "${BLUE}Installing Termux GUI...${RESET}"

    # Install required packages
    pkg install termux-x11 tigervnc -y > /dev/null 2>&1 &
    spinner $! "Installing termux-x11 and tigervnc"
    if ! check_success "pkg install termux-x11 tigervnc"; then
        log_error "Failed to install termux-x11 and tigervnc."
        return 1
    fi

    # Get phone's portrait resolution
    PORTRAIT_RESOLUTION=$(termux-wallpaper -f 2>&1 | grep -oP 'Resolution: \K[0-9]+x[0-9]+')
    if [ -z "$PORTRAIT_RESOLUTION" ]; then
        echo -e "${YELLOW}Failed to detect portrait resolution. Using default 1080x1920.${RESET}"
        PORTRAIT_RESOLUTION="1080x1920"
    fi
    echo -e "${GREEN}Detected portrait resolution: $PORTRAIT_RESOLUTION${RESET}"

    # Calculate landscape resolution (swap width and height)
    LANDSCAPE_RESOLUTION=$(echo "$PORTRAIT_RESOLUTION" | awk -F'x' '{print $2 "x" $1}')
    echo -e "${GREEN}Calculated landscape resolution: $LANDSCAPE_RESOLUTION${RESET}"

    # Configure VNC
    mkdir -p ~/.vnc
    echo "geometry=$PORTRAIT_RESOLUTION" > ~/.vnc/config
    echo "localhost:1" > ~/.vnc/display

    # Start VNC server
    vncserver :1 -geometry "$PORTRAIT_RESOLUTION" -depth 24 > /dev/null 2>&1 &
    spinner $! "Starting VNC server"
    if ! check_success "vncserver :1"; then
        log_error "Failed to start VNC server."
        return 1
    fi

    echo -e "${GREEN}Termux GUI installed and configured successfully!${RESET}"
    echo -e "${BLUE}You can connect to the VNC server at localhost:1.${RESET}"
}

# Initialize error log
> "$ERROR_LOG"

# Step 1: Check and set up storage permissions
echo -e "${BLUE}Checking storage permissions...${RESET}"
if [ -d ~/storage ]; then
    echo -e "${YELLOW}Storage permissions already granted. Skipping termux-setup-storage.${RESET}"
else
    termux-setup-storage > /dev/null 2>&1 &
    spinner $! "Setting up storage permissions"
    if ! check_success "termux-setup-storage"; then
        log_error "termux-setup-storage failed."
    fi
fi

# Wait for storage to be mounted
echo -e "${BLUE}Waiting for storage to be ready...${RESET}"
while [ ! -d ~/storage ]; do
    sleep 1
done
echo -e "${GREEN}Storage is ready.${RESET}"

# Step 2: Update and upgrade packages
apt update > /dev/null 2>&1 && apt upgrade -y > /dev/null 2>&1 &
spinner $! "Updating and upgrading packages"
if ! check_success "apt update && apt upgrade"; then
    log_error "apt update && apt upgrade failed."
fi

# Step 3: Install git
apt install git -y > /dev/null 2>&1 &
spinner $! "Installing git"
if ! check_success "apt install git"; then
    log_error "apt install git failed."
fi

# Step 4: Clone the Ter_back repository
if [ -d "Ter_back" ]; then
    echo -e "${YELLOW}Ter_back directory already exists. Skipping clone.${RESET}"
else
    git clone https://github.com/Lexor-Software/Ter_back.git > /dev/null 2>&1 &
    spinner $! "Cloning Ter_back repository"
    if ! check_success "git clone"; then
        log_error "git clone failed."
    fi
fi

# Step 5: Change to the Ter_back directory
cd Ter_back || { echo -e "${RED}Failed to change directory. Exiting...${RESET}"; exit 1; }

# Step 6: Copy the goto script
if [ -f "goto" ]; then
    cp goto /data/data/com.termux/files/usr/bin/goto > /dev/null 2>&1 &
    spinner $! "Copying goto script"
    if ! check_success "cp goto"; then
        log_error "cp goto failed."
    fi
else
    echo -e "${RED}Error: goto script not found in Ter_back directory.${RESET}"
    log_error "goto script not found."
fi

# Step 7: Copy the .bashrc file
if [ -f ".bashrc" ]; then
    cp .bashrc ~/.bashrc > /dev/null 2>&1 &
    spinner $! "Copying .bashrc file"
    if ! check_success "cp .bashrc"; then
        log_error "cp .bashrc failed."
    fi
else
    echo -e "${RED}Error: .bashrc file not found in Ter_back directory.${RESET}"
    log_error ".bashrc file not found."
fi

# Step 8: Source the .bashrc file
source ~/.bashrc > /dev/null 2>&1 &
spinner $! "Sourcing .bashrc file"
if ! check_success "source .bashrc"; then
    log_error "source .bashrc failed."
fi

# Step 9: Install additional Termux packages
install_additional_termux_packages

# Step 10: Restore Termux packages
restore_termux_packages

# Step 11: Ask to restore pip packages
if ask_confirm "Do you want to restore pip packages?"; then
    restore_pip_packages

    # Step 12: Install Termux GUI packages after pip packages are restored successfully
    if [ $? -eq 0 ]; then
        install_termux_gui_packages
    fi
else
    echo -e "${YELLOW}Skipping pip package restoration.${RESET}"
fi

# Step 13: Ask to install Termux GUI
if ask_confirm "Do you want to install Termux GUI (termux-x11 + VNC)?"; then
    install_termux_gui
else
    echo -e "${YELLOW}Skipping Termux GUI installation.${RESET}"
fi

# Step 14: Print setup completion status and resolutions
if [ -s "$ERROR_LOG" ]; then
    echo -e "${RED}Setup completed with errors. Check $ERROR_LOG for details.${RESET}"
else
    echo -e "${GREEN}Setup completed successfully!${RESET}"
fi

# Print current portrait and landscape resolutions
echo -e "${BLUE}Current Portrait Resolution: $PORTRAIT_RESOLUTION${RESET}"
echo -e "${BLUE}Current Landscape Resolution: $LANDSCAPE_RESOLUTION${RESET}"
