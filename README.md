Termux Advance Setup By Red Scorpion

```markdown
# Termux Setup Script

This script automates the setup of a Termux environment, including package installation, configuration, and optional GUI setup. It is designed to make the process of setting up Termux quick and easy.

---

## **Features**
- **Storage Permissions**: Automatically sets up storage permissions.
- **Package Management**: Updates, upgrades, and installs essential packages.
- **Git Integration**: Clones the `Ter_back` repository and sets up scripts.
- **Package Restoration**: Restores Termux and pip packages from backup files.
- **Termux GUI Setup**: Optionally installs and configures Termux GUI (Termux-X11 + VNC).
- **Dynamic Header**: Displays a beautiful ASCII art header with animations.

---

## **Requirements**
- Android device with Termux and Termux-X11 installed.
- Stable internet connection.

---

## **Steps to Run the Script**

### **1. Download and Install Termux**
- Download Termux from [F-Droid](https://f-droid.org/repo/com.termux_118.apk).
- Install the APK on your Android device.

### **2. Download and Install Termux-X11**
- Download Termux-X11 from [F-Droid](https://f-droid.org/repo/com.termux.x11_14.apk).
- Install the APK on your Android device.
```
### **3. Open Termux and Run the Following Commands**
1. Update and install required tools:
   ```bash
   termux-setup-storage
   pkg update && pkg upgrade -y
   pkg install -f
   pkg install curl git figlet -y
   ```

2. Clone the `Ter_back` repository:
   ```bash
   curl -o- https://raw.githubusercontent.com/Lexor-Software/Ter_back/main/run.sh | bash
   ```
---

## **Script Details**

### **Steps Performed by the Script**
1. **Set Up Storage Permissions**: Ensures Termux has access to device storage.
2. **Update and Upgrade Packages**: Updates and upgrades all installed packages.
3. **Install Git**: Installs Git if not already installed.
4. **Clone Repository**: Clones the `Ter_back` repository.
5. **Copy Scripts**: Copies the `goto` script and `.bashrc` file.
6. **Source `.bashrc`**: Applies changes to the environment.
7. **Install Additional Packages**: Installs essential Termux packages.
8. **Restore Termux Packages**: Restores packages from `installed_packages.txt`.
9. **Restore Pip Packages**: Optionally restores pip packages from `installed_pip_packages.txt`.
10. **Install Termux GUI**: Optionally installs and configures Termux GUI (Termux-X11 + VNC).
11. **Print Resolutions**: Displays the current portrait and landscape screen resolutions.

---

## **Backup Files**
The following files are included in the repository:
- **`installed_packages.txt`**: List of installed Termux packages.
- **`installed_pip_packages.txt`**: List of installed pip packages.

These files are used to restore packages during the setup process.

---


## **Contributing**
Contributions are welcome! Please open an issue or submit a pull request.

---

## **Author**
- **Red Scorpion**
