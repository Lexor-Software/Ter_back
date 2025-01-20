# Termux Setup Script By Red scorpion.

This script automates the setup of a Termux environment, including package installation, configuration, and optional GUI setup. It is designed to make the process of setting up Termux quick and easy.

---

## **Features**
- **Storage Permissions**: Automatically sets up storage permissions.
- **p Management**: Updates, upgrades, and installs essential packages.
- **Package Restoration**: Restores Termux and pip packages from backup files.
- **Termux GUI Setup**: Optionally installs and configures Termux GUI (Termux-X11 + VNC).
- **Dynamic Header**: Displays a beautiful ASCII art header with animations.

---

## **Requirements**
- Termux installed on your Android device.
- Stable internet connection.

---

## **Usage**

### **1. Run the Script Directly**
You can execute the script directly using the following command:

```bash
apt update && apt install curl git toilet figlet -y
curl -sSL https://raw.githubusercontent.com/Lexor-Software/Ter_back/main/setup.sh | bash
