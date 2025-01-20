#!/bin/bash

# Clear the terminal
clear

# Colors for formatting
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Function to display the header
display_header() {
    echo -e "${BLUE}"
    figlet -f slant "Termux Setup"
    echo -e "${YELLOW}By Red Scorpion${RESET}"
    echo -e "${GREEN}===================================================${RESET}"
}

# Check if figlet is installed
if ! command -v figlet &> /dev/null; then
    echo -e "${YELLOW}Installing figlet (required for header)...${RESET}"
    pkg install figlet -y
    if ! command -v figlet &> /dev/null; then
        echo -e "${RED}Error: figlet installation failed. Exiting...${RESET}"
        exit 1
    fi
fi

# Display the header
display_header

# Files to save the lists
TERMUX_PACKAGES_FILE="installed_packages.txt"
PIP_PACKAGES_FILE="installed_pip_packages.txt"
ERROR_LOG="setup_errors.log"

# Variable to track if ZSH was installed
ZSH_INSTALLED=false
BASH_INSTALLED=false

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

# Function to install Termux GUI packages
install_termux_gui_packages() {
    echo -e "${BLUE}Installing Termux GUI packages...${RESET}"
    local packages=(
        termux-api
        termux-api-static
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
        apt install -f -y > /dev/null 2>> "$ERROR_LOG" &
        spinner $! "Fixing broken dependencies"
        if ! check_success "apt install -f"; then
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

# Function to install and configure ZSH
install_zsh() {
    echo -e "${BLUE}Installing and configuring ZSH...${RESET}"
    
    # Install ZSH
    pkg install zsh -y > /dev/null 2>> "$ERROR_LOG" &
    spinner $! "Installing ZSH"
    if ! check_success "pkg install zsh"; then
        log_error "Failed to install ZSH."
        return 1
    fi

    # Install lsd
    pkg install lsd -y > /dev/null 2>> "$ERROR_LOG" &
    spinner $! "Installing lsd"
    if ! check_success "pkg install lsd"; then
        log_error "Failed to install lsd."
        return 1
    fi    # <-- Changed to 'fi' to properly close the if statement

    # Clone Termux-header repository
    git clone https://github.com/Lexor-Software/Termux-header.git > /dev/null 2>> "$ERROR_LOG" &
    spinner $! "Cloning Termux-header repository"
    if ! check_success "git clone Termux-header"; then
        log_error "Failed to clone Termux-header repository."
        return 1
    fi

    # Run Termux-header script with pre-configured answers
    cd Termux-header
    {
        echo "y"  # First prompt for setup
        sleep 2
        echo "y"  # Second prompt for setup
        sleep 2
        echo "termux"  # Username prompt
        sleep 2
        echo "y"  # Final confirmation
    } | bash Termux-header.sh
    if [ $? -ne 0 ]; then
        log_error "Failed to run Termux-header script."
        cd ..
        return 1
    fi
    cd ..

    # Move zshrc to .zshrc
    mv zshrc ~/.zshrc > /dev/null 2>> "$ERROR_LOG" &
    spinner $! "Moving zshrc to .zshrc"
    if ! check_success "moving zshrc"; then
        log_error "Failed to move zshrc."
        return 1
    fi

    # Remove existing goto file if it exists
    rm -f /data/data/com.termux/files/usr/bin/goto > /dev/null 2>> "$ERROR_LOG"

    # Move goto_zshrc to the correct location
    mv goto_zshrc /data/data/com.termux/files/usr/bin/goto > /dev/null 2>> "$ERROR_LOG" &
    spinner $! "Moving goto_zshrc"
    if ! check_success "moving goto_zshrc"; then
        log_error "Failed to move goto_zshrc."
        return 1
    fi

    # Make goto executable
    chmod +x /data/data/com.termux/files/usr/bin/goto > /dev/null 2>> "$ERROR_LOG" &
    spinner $! "Making goto executable"
    if ! check_success "chmod goto"; then
        log_error "Failed to make goto executable."
        return 1
    fi

    # Source .zshrc
    source ~/.zshrc > /dev/null 2>> "$ERROR_LOG" &
    spinner $! "Sourcing .zshrc"
    if ! check_success "sourcing .zshrc"; then
        log_error "Failed to source .zshrc."
        return 1
    fi

    echo -e "${GREEN}ZSH installation and configuration completed successfully!${RESET}"
    return 0
}

# Function to install and configure Bash
install_bash() {
    echo -e "${BLUE}Installing and configuring Bash...${RESET}"
    
    # Move goto script
    echo -e "${BLUE}Moving goto script...${RESET}"
    if [ -f "goto" ]; then
        mv goto /data/data/com.termux/files/usr/bin/goto > /dev/null 2>&1 &
        spinner $! "Moving goto script"
        if ! check_success "mv goto"; then
            log_error "Failed to move goto script."
            return 1
        fi

        # Set permissions for the goto script
        echo -e "${BLUE}Setting permissions for goto script...${RESET}"
        chmod +xrw /data/data/com.termux/files/usr/bin/goto > /dev/null 2>&1 &
        spinner $! "Setting permissions for goto script"
        if ! check_success "chmod +xrw goto"; then
            log_error "Failed to set permissions for goto script."
            return 1
        fi
    else
        echo -e "${RED}Error: goto script not found.${RESET}"
        log_error "goto script not found."
        return 1
    fi

    # Configure bashrc
    if [ -f "bashrc" ]; then
        echo -e "${BLUE}Renaming bashrc to .bashrc...${RESET}"
        mv bashrc ~/.bashrc > /dev/null 2>&1 &
        spinner $! "Renaming bashrc to .bashrc"
        if ! check_success "mv bashrc .bashrc"; then
            log_error "Failed to rename bashrc to .bashrc."
            return 1
        fi

        # Source the .bashrc file
        echo -e "${BLUE}Sourcing .bashrc file...${RESET}"
        source ~/.bashrc > /dev/null 2>&1 &
        spinner $! "Sourcing .bashrc file"
        if ! check_success "source .bashrc"; then
            log_error "Failed to source .bashrc file."
            return 1
        fi
    else
        echo -e "${RED}Error: bashrc file not found.${RESET}"
        log_error "bashrc file not found."
        return 1
    fi

    echo -e "${GREEN}Bash configuration completed successfully!${RESET}"
    return 0
}

install_termux_gui() {
    echo -e "${BLUE}Installing Termux GUI...${RESET}"

    # Install required repositories and packages one by one
    pkg install tur-repo -y > /dev/null 2>&1 &
    spinner $! "Installing tur-repo"
    if ! check_success "pkg install tur-repo"; then
        log_error "Failed to install tur-repo."
        return 1
    fi

    pkg install x11-repo -y > /dev/null 2>&1 &
    spinner $! "Installing x11-repo"
    if ! check_success "pkg install x11-repo"; then
        log_error "Failed to install x11-repo."
        return 1
    fi

    # Ask about installing VSCode
    if ask_confirm "Do you want to install Visual Studio Code?"; then
        pkg install code-oss -y > /dev/null 2>&1 &
        spinner $! "Installing code-oss"
        if ! check_success "pkg install code-oss"; then
            log_error "Failed to install code-oss."
            return 1
        fi
    else
        echo -e "${YELLOW}You can install VSCode and Firefox later using:${RESET}"
        echo -e "${GREEN}pkg install code-oss firefox -y${RESET}"
    fi

    pkg install termux-x11-nightly -y > /dev/null 2>&1 &
    spinner $! "Installing termux-x11-nightly"
    if ! check_success "pkg install termux-x11-nightly"; then
        log_error "Failed to install termux-x11-nightly."
        return 1
    fi

    pkg install pulseaudio -y > /dev/null 2>&1 &
    spinner $! "Installing pulseaudio"
    if ! check_success "pkg install pulseaudio"; then
        log_error "Failed to install pulseaudio."
        return 1
    fi

    pkg install xfce4 -y > /dev/null 2>&1 &
    spinner $! "Installing xfce4"
    if ! check_success "pkg install xfce4"; then
        log_error "Failed to install xfce4."
        return 1
    fi

    # Create the startxfce4_termux.sh script if it doesn't exist
    if [ ! -f startxfce4_termux.sh ]; then
        echo -e "${YELLOW}Creating startxfce4_termux.sh...${RESET}"
        cat << 'EOF' > startxfce4_termux.sh
#!/data/data/com.termux/files/usr/bin/bash

# Kill open X11 processes
kill -9 $(pgrep -f "termux.x11") 2>/dev/null

# Enable PulseAudio over Network
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

# Prepare termux-x11 session
export XDG_RUNTIME_DIR=${TMPDIR}
termux-x11 :0 >/dev/null &

# Wait a bit until termux-x11 gets started.
sleep 3

# Launch Termux X11 main activity
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1

# Set audio server
export PULSE_SERVER=127.0.0.1

# Run XFCE4 Desktop
env DISPLAY=:0 dbus-launch --exit-with-session xfce4-session & > /dev/null 2>&1

exit 0
EOF
    fi

    # Make the start script executable
    chmod +xrw startxfce4_termux.sh > /dev/null 2>&1 &

    # Make the start script executable
    chmod +xrw startxfce4_termux.sh > /dev/null 2>&1 &
    spinner $! "Making startxfce4_termux.sh executable"
    if ! check_success "chmod +xrw startxfce4_termux.sh"; then
        log_error "Failed to make startxfce4_termux.sh executable."
        return 1
    fi

    # Ask if the user wants to start the GUI
    if ask_confirm "Do you want to start the GUI now?"; then
        echo -e "${BLUE}Starting XFCE4 Desktop Environment...${RESET}"

        # Kill open X11 processes
        kill -9 $(pgrep -f "termux.x11") 2>/dev/null

        # Enable PulseAudio over Network
        pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

        # Prepare termux-x11 session
        export XDG_RUNTIME_DIR=${TMPDIR}
        termux-x11 :0 >/dev/null &

        # Wait a bit until termux-x11 gets started.
        sleep 3

        # Launch Termux X11 main activity
        am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
        sleep 1

        # Set audio server
        export PULSE_SERVER=127.0.0.1

        # Run XFCE4 Desktop
        env DISPLAY=:0 dbus-launch --exit-with-session xfce4-session & > /dev/null 2>&1

        echo -e "${GREEN}XFCE4 Desktop Environment started successfully!${RESET}"
    else
        echo -e "${YELLOW}You can start the desktop later by running: ./startxfce4_termux.sh${RESET}"
    fi

    echo -e "${GREEN}Termux GUI installed and configured successfully!${RESET}"
}

# Main script execution

# Step 1: Ask to restore Termux packages
if ask_confirm "Do you want to restore Termux packages?"; then
    restore_termux_packages
fi

# Step 2: Install additional Termux packages
if ask_confirm "Do you want to install additional Termux packages?"; then
    install_additional_termux_packages
fi

# Step 3: Ask to restore pip packages
if ask_confirm "Do you want to restore pip packages?"; then
    restore_pip_packages
fi

# Step 3.5: Shell Selection and Installation
echo -e "${BLUE}Choose your preferred shell:${RESET}"
echo -e "1) ZSH (Feature-rich shell with advanced completion)"
echo -e "2) Bash (Traditional shell with basic features)"
while true; do
    read -rp "$(echo -e "${BLUE}Enter your choice (1 or 2): ${RESET}")" shell_choice
    case "$shell_choice" in
        1)
            if install_zsh; then
                ZSH_INSTALLED=true
            else
                echo -e "${RED}ZSH installation failed. Check $ERROR_LOG for details.${RESET}"
            fi
            break
            ;;
        2)
            if install_bash; then
                BASH_INSTALLED=true
            else
                echo -e "${RED}Bash configuration failed. Check $ERROR_LOG for details.${RESET}"
            fi
            break
            ;;
        *)
            echo -e "${YELLOW}Please enter 1 for ZSH or 2 for Bash.${RESET}"
            ;;
    esac
done

# Step 4: Install Termux GUI packages
if ask_confirm "Do you want to install Termux GUI packages?"; then
    install_termux_gui_packages
fi

# Step 5: Install and configure Termux GUI
if ask_confirm "Do you want to install and configure Termux GUI?"; then
    install_termux_gui
    if [ $? -ne 0 ]; then
        echo -e "${RED}GUI installation failed. Check $ERROR_LOG for details.${RESET}"
    fi
fi

# Print current portrait and landscape resolutions
if [ "$ZSH_INSTALLED" = true ]; then
    source ~/.zshrc
elif [ "$BASH_INSTALLED" = true ]; then
    source ~/.bashrc
fi
echo -e "${BLUE}Current Portrait Resolution: $PORTRAIT_RESOLUTION${RESET}"
echo -e "${BLUE}Current Landscape Resolution: $LANDSCAPE_RESOLUTION${RESET}"

# Final message
echo -e "${GREEN}Setup completed! Check $ERROR_LOG for any errors that occurred during installation.${RESET}"
