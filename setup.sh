#!/bin/bash

# Files to save the lists
TERMUX_PACKAGES_FILE="installed_packages.txt"
PIP_PACKAGES_FILE="installed_pip_packages.txt"
ERROR_LOG="setup_errors.log"

# Function to check if a command was successful
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed."
        return 1
    fi
}

# Function to log errors
log_error() {
    echo "Error: $1" >> "$ERROR_LOG"
}

# Function to ask for user confirmation
ask_confirm() {
    local prompt="$1"
    while true; do
        read -rp "$prompt (y/n): " response
        case "$response" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Please answer yes (y) or no (n)." ;;
        esac
    done
}

# Function to restore Termux packages
restore_termux_packages() {
    echo "Restoring Termux packages..."
    if [ -f "$TERMUX_PACKAGES_FILE" ]; then
        while read -r package; do
            echo "Installing $package..."
            apt install -y "$package" 2>> "$ERROR_LOG"
            if ! check_success "apt install $package"; then
                echo "Skipping $package due to errors."
                log_error "Failed to install $package."
            fi
        done < "$TERMUX_PACKAGES_FILE"

        # Attempt to fix broken dependencies
        echo "Attempting to fix broken dependencies..."
        apt-get install -f -y 2>> "$ERROR_LOG"
        if ! check_success "apt-get install -f"; then
            log_error "Failed to fix broken dependencies."
        fi
    else
        echo "Error: $TERMUX_PACKAGES_FILE not found. Please ensure the backup file exists."
        log_error "$TERMUX_PACKAGES_FILE not found."
    fi
}

# Function to restore pip packages
restore_pip_packages() {
    echo "Restoring pip packages..."
    if [ -f "$PIP_PACKAGES_FILE" ]; then
        pip install -r "$PIP_PACKAGES_FILE" 2>> "$ERROR_LOG"
        if ! check_success "pip install -r $PIP_PACKAGES_FILE"; then
            log_error "Failed to restore pip packages."
        fi
    else
        echo "Error: $PIP_PACKAGES_FILE not found. Please ensure the backup file exists."
        log_error "$PIP_PACKAGES_FILE not found."
    fi
}

# Initialize error log
> "$ERROR_LOG"

# Step 1: Set up storage permissions
echo "Setting up storage permissions..."
termux-setup-storage
if ! check_success "termux-setup-storage"; then
    log_error "termux-setup-storage failed."
fi

# Wait for storage to be mounted
echo "Waiting for storage to be ready..."
while [ ! -d ~/storage ]; do
    sleep 1
done
echo "Storage is ready."

# Step 2: Update package list
echo "Updating package list..."
apt update
if ! check_success "apt update"; then
    log_error "apt update failed."
fi

# Step 3: Install git
echo "Installing git..."
apt install git -y
if ! check_success "apt install git"; then
    log_error "apt install git failed."
fi

# Step 4: Clone the Ter_back repository
echo "Cloning Ter_back repository..."
if [ -d "Ter_back" ]; then
    echo "Ter_back directory already exists. Skipping clone."
else
    git clone https://github.com/Lexor-Software/Ter_back.git
    if ! check_success "git clone"; then
        log_error "git clone failed."
    fi
fi

# Step 5: Change to the Ter_back directory
echo "Changing to Ter_back directory..."
cd Ter_back || { echo "Failed to change directory. Exiting..."; exit 1; }

# Step 6: Copy the goto script
echo "Copying goto script..."
if [ -f "goto" ]; then
    cp goto /data/data/com.termux/files/usr/bin/goto
    if ! check_success "cp goto"; then
        log_error "cp goto failed."
    fi
else
    echo "Error: goto script not found in Ter_back directory."
    log_error "goto script not found."
fi

# Step 7: Copy the .bashrc file
echo "Copying .bashrc file..."
if [ -f ".bashrc" ]; then
    cp .bashrc ~/.bashrc
    if ! check_success "cp .bashrc"; then
        log_error "cp .bashrc failed."
    fi
else
    echo "Error: .bashrc file not found in Ter_back directory."
    log_error ".bashrc file not found."
fi

# Step 8: Source the .bashrc file
echo "Sourcing .bashrc file..."
source ~/.bashrc
if ! check_success "source .bashrc"; then
    log_error "source .bashrc failed."
fi

# Step 9: Restore Termux packages
restore_termux_packages

# Step 10: Ask to restore pip packages
if ask_confirm "Do you want to restore pip packages?"; then
    restore_pip_packages
else
    echo "Skipping pip package restoration."
fi

# Check if any errors occurred
if [ -s "$ERROR_LOG" ]; then
    echo "Setup completed with errors. Check $ERROR_LOG for details."
else
    echo "Setup completed successfully!"
fi
