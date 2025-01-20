#!/bin/bash

# Clear the terminal
clear

# Colors for formatting
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Files to save the lists
ERROR_LOG="initial_setup_errors.log"

# Initialize error log
> "$ERROR_LOG"

# Step 1: Set up storage permissions
echo -e "${BLUE}Setting up storage permissions...${RESET}"
termux-setup-storage > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: termux-setup-storage failed.${RESET}"
    log_error "termux-setup-storage failed."
else
    echo -e "${GREEN}Success: termux-setup-storage completed.${RESET}"
fi

# Step 2: Update and upgrade packages
echo -e "${BLUE}Updating and upgrading packages...${RESET}"
pkg update -y > /dev/null 2>&1 && pkg upgrade -y > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: pkg update && pkg upgrade failed.${RESET}"
    log_error "pkg update && pkg upgrade failed."
else
    echo -e "${GREEN}Success: pkg update && pkg upgrade completed.${RESET}"
fi

# Step 3: Fix broken dependencies
echo -e "${BLUE}Fixing broken dependencies...${RESET}"
pkg install -f -y > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to fix broken dependencies.${RESET}"
    log_error "Failed to fix broken dependencies."
else
    echo -e "${GREEN}Success: pkg install -f completed.${RESET}"
fi

# Step 4: Install required packages (ncurses-utils and figlet)
echo -e "${BLUE}Installing required packages...${RESET}"
pkg install ncurses-utils git figlet -y > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to install required packages.${RESET}"
    log_error "Failed to install ncurses-utils, git, and figlet."
else
    echo -e "${GREEN}Success: pkg install ncurses-utils git figlet completed.${RESET}"
fi

# Step 5: Display the header (now that figlet is installed)
display_header() {
    echo -e "${BLUE}"
    figlet -f slant "Initial Setup"
    echo -e "${YELLOW}By Red Scorpion${RESET}"
    echo -e "${GREEN}===================================================${RESET}"
}

# Display the header
display_header

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

# Step 6: Clone the Ter_back repository
echo -e "${BLUE}Cloning Ter_back repository...${RESET}"
git clone https://github.com/Lexor-Software/Ter_back.git > /dev/null 2>&1 &
spinner $! "Cloning Ter_back repository"
if ! check_success "git clone"; then
    log_error "Failed to clone Ter_back repository."
fi

# Step 7: Move contents of Ter_back to the current directory
echo -e "${BLUE}Moving contents of Ter_back...${RESET}"
mv Ter_back/* . > /dev/null 2>&1 &
spinner $! "Moving contents of Ter_back"
if ! check_success "mv Ter_back/* ."; then
    log_error "Failed to move contents of Ter_back."
fi

# Step 8: Make setup.sh executable
echo -e "${BLUE}Making setup.sh executable...${RESET}"
chmod +xrw setup.sh > /dev/null 2>&1 &
spinner $! "Making setup.sh executable"
if ! check_success "chmod +xrw setup.sh"; then
    log_error "Failed to make setup.sh executable."
fi

# Step 9: Print setup completion status
if [ -s "$ERROR_LOG" ]; then
    echo -e "${RED}Initial setup completed with errors. Check $ERROR_LOG for details.${RESET}"
else
    echo -e "${GREEN}Initial setup completed successfully!${RESET}"
fi

# Step 10: Execute setup.sh
echo -e "${BLUE}Executing setup.sh...${RESET}"
bash setup.sh
