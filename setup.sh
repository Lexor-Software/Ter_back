#!/bin/bash

   # Function to check if a command was successful
   check_success() {
       if [ $? -ne 0 ]; then
           echo "Error: $1 failed. Exiting..."
           exit 1
       fi
   }

   # Step 1: Set up storage permissions
   echo "Setting up storage permissions..."
   termux-setup-storage
   check_success "termux-setup-storage"

   # Wait for storage to be mounted
   echo "Waiting for storage to be ready..."
   while [ ! -d ~/storage ]; do
       sleep 1
   done
   echo "Storage is ready."

   # Step 2: Update package list
   echo "Updating package list..."
   apt update
   check_success "apt update"

   # Step 3: Install git
   echo "Installing git..."
   apt install git -y
   check_success "apt install git"

   # Step 4: Clone the Ter_back repository
   echo "Cloning Ter_back repository..."
   if [ -d "Ter_back" ]; then
       echo "Ter_back directory already exists. Skipping clone."
   else
       git clone https://github.com/Lexor-Software/Ter_back.git
       check_success "git clone"
   fi

   # Step 5: Change to the Ter_back directory
   echo "Changing to Ter_back directory..."
   cd Ter_back || { echo "Failed to change directory. Exiting..."; exit 1; }

   # Step 6: Copy the goto script
   echo "Copying goto script..."
   if [ -f "goto" ]; then
       cp goto /data/data/com.termux/files/usr/bin/goto
       check_success "cp goto"
   else
       echo "Error: goto script not found in Ter_back directory. Exiting..."
       exit 1
   fi

   # Step 7: Copy the .bashrc file
   echo "Copying .bashrc file..."
   if [ -f ".bashrc" ]; then
       cp .bashrc ~/.bashrc
       check_success "cp .bashrc"
   else
       echo "Error: .bashrc file not found in Ter_back directory. Exiting..."
       exit 1
   fi

   # Step 8: Source the .bashrc file
   echo "Sourcing .bashrc file..."
   source ~/.bashrc
   check_success "source .bashrc"

   # Step 9: Restore Termux packages
   echo "Restoring Termux packages..."
   if [ -f "installed_packages.txt" ]; then
       xargs -a installed_packages.txt apt install -y
       check_success "xargs apt install"
   else
       echo "Error: installed_packages.txt not found. Please ensure the backup file exists."
   fi

   echo "Setup completed successfully!"