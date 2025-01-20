#!/bin/bash

# Step 1: Set up storage permissions
echo -e "\033[34mSetting up storage permissions...\033[0m"
termux-setup-storage

# Step 2: Update and upgrade packages
echo -e "\033[34mUpdating and upgrading packages...\033[0m"
pkg update -y && pkg upgrade -y

# Step 3: Fix broken dependencies
echo -e "\033[34mFixing broken dependencies...\033[0m"
pkg install -f -y

# Step 4: Install required packages
echo -e "\033[34mInstalling required packages...\033[0m"
pkg install ncurses-utils curl git figlet -y

# Step 5: Clone the Ter_back repository
echo -e "\033[34mCloning Ter_back repository...\033[0m"
git clone https://github.com/Lexor-Software/Ter_back.git

# Step 6: Move contents of Ter_back to the current directory
echo -e "\033[34mMoving contents of Ter_back...\033[0m"
mv Ter_back/* .

# Step 7: Make setup.sh executable
echo -e "\033[34mMaking setup.sh executable...\033[0m"
chmod +xrw setup.sh

# Step 8: Exit and execute setup.sh
echo -e "\033[34mExiting and executing setup.sh...\033[0m"
exit
bash setup.sh