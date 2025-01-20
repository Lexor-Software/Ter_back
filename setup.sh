#!/bin/bash

# Clear the terminal
clear

# Colors for formatting
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Function to log errors
log_error() {
    echo -e "${RED}Error: $1${RESET}" >> "$ERROR_LOG"
}

# Files to save the lists
TERMUX_PACKAGES_FILE="installed_packages.txt"
PIP_PACKAGES_FILE="installed_pip_packages.txt"
ERROR_LOG="setup_errors.log"

# Initialize error log
> "$ERROR_LOG"

# Spinner characters
SPINNER=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

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

# Step 1: Move the goto script
echo -e "${BLUE}Moving goto script...${RESET}"
if [ -f "goto" ]; then
    mv goto /data/data/com.termux/files/usr/bin/goto > /dev/null 2>&1 &
    spinner $! "Moving goto script"
    if ! check_success "mv goto"; then
        log_error "Failed to move goto script."
    else
        # Set permissions for the goto script
        echo -e "${BLUE}Setting permissions for goto script...${RESET}"
        chmod +xrw /data/data/com.termux/files/usr/bin/goto > /dev/null 2>&1 &
        spinner $! "Setting permissions for goto script"
        if ! check_success "chmod +xrw goto"; then
            log_error "Failed to set permissions for goto script."
        fi
    fi
else
    echo -e "${RED}Error: goto script not found.${RESET}"
    log_error "goto script not found."
fi

# Step 2: Move the .bashrc file
echo -e "${BLUE}Moving .bashrc file...${RESET}"
if [ -f ".bashrc" ]; then
    mv .bashrc ~/.bashrc > /dev/null 2>&1 &
    spinner $! "Moving .bashrc file"
    if ! check_success "mv .bashrc"; then
        log_error "Failed to move .bashrc file."
    fi
else
    echo -e "${RED}Error: .bashrc file not found.${RESET}"
    log_error ".bashrc file not found."
fi

# Step 3: Source the .bashrc file
echo -e "${BLUE}Sourcing .bashrc file...${RESET}"
source ~/.bashrc > /dev/null 2>&1 &
spinner $! "Sourcing .bashrc file"
if ! check_success "source .bashrc"; then
    log_error "Failed to source .bashrc file."
fi

# Step 4: Install additional Termux packages
install_additional_termux_packages() {
    echo -e "${BLUE}Installing additional Termux packages...${RESET}"
    local packages=(
        htop
    )

    for package in "${packages[@]}"; do
        pkg install -y "$package" > /dev/null 2>> "$ERROR_LOG" &
        spinner $! "Installing $package"
        if ! check_success "pkg install $package"; then
            echo -e "${YELLOW}Skipping $package due to errors.${RESET}"
            log_error "Failed to install $package."
        fi
    done
}

# Step 5: Restore Termux packages
restore_termux_packages() {
    echo -e "${BLUE}Restoring Termux packages...${RESET}"
    if [ -f "$TERMUX_PACKAGES_FILE" ]; then
        while read -r package; do
            pkg install -y "$package" > /dev/null 2>> "$ERROR_LOG" &
            spinner $! "Installing $package"
            if ! check_success "pkg install $package"; then
                echo -e "${YELLOW}Skipping $package due to errors.${RESET}"
                log_error "Failed to install $package."
            fi
        done < "$TERMUX_PACKAGES_FILE"

        # Attempt to fix broken dependencies
        pkg install -f -y > /dev/null 2>> "$ERROR_LOG" &
        spinner $! "Fixing broken dependencies"
        if ! check_success "pkg install -f"; then
            log_error "Failed to fix broken dependencies."
        fi
    else
        echo -e "${RED}Error: $TERMUX_PACKAGES_FILE not found. Please ensure the backup file exists.${RESET}"
        log_error "$TERMUX_PACKAGES_FILE not found."
    fi
}

# Step 6: Restore pip packages
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

# Step 7: Install and configure Termux GUI
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

# Step 8: Install additional Termux packages
install_additional_termux_packages

# Step 9: Restore Termux packages
restore_termux_packages

# Step 10: Ask to restore pip packages
if ask_confirm "Do you want to restore pip packages?"; then
    restore_pip_packages
else
    echo -e "${YELLOW}Skipping pip package restoration.${RESET}"
fi

# Step 11: Ask to install Termux GUI
if ask_confirm "Do you want to install Termux GUI (termux-x11 + VNC)?"; then
    install_termux_gui
else
    echo -e "${YELLOW}Skipping Termux GUI installation.${RESET}"
fi

# Step 12: Print setup completion status
if [ -s "$ERROR_LOG" ]; then
    echo -e "${RED}Setup completed with errors. Check $ERROR_LOG for details.${RESET}"
else
    echo -e "${GREEN}Setup completed successfully!${RESET}"
fi
