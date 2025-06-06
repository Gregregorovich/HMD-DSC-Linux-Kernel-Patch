#!/bin/bash

# Compiles the kernel with patches as set up in ./install-fedora.sh
# then (re)installs the new kernel by calling the ./update-fedora.sh script.
# (I.E. the patches to enable DSC and add HMDs to the non-desktop list.)
# This builds the most recent kernel pushed to release (I.E. the same
# version as could be obtained from a `dnf update`)



# Ensure the script is running as root (via sudo)
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run using sudo. Re-launching with sudo..."
    exec sudo "$0" "$@"
fi

echo "Script is running with sudo privileges as: $(whoami)"

# Determine the non-privileged user. If run via sudo, $SUDO_USER is set.
if [ -n "$SUDO_USER" ]; then
    REGULAR_USER="$SUDO_USER"
else
    # Fall back to $USER if the script was not started with sudo.
    REGULAR_USER="$USER"
fi




KERNEL_BRANCH=$(uname -r | awk -F. '{print $(NF-1)}' | sed -e 's/fc/f/')
KERNEL_ARCH=$(uname -r | awk -F. '{print $(NF)}')

clear

# Change working directory to script's directory
cd $(dirname "$0")

# Change to the kernel source directory and update
cd kernel || { echo "Cannot change directory to kernel"; exit 1; }

echo "Switching to non-root user: $REGULAR_USER for to fetch latest git repo info"

# Use su to switch to the regular user and run multiple non-elevated commands.
su - "$REGULAR_USER" <<'EOF'
    echo "Updating repo to latest kernel release version..."
    git pull origin $KERNEL_BRANCH --rebase
    echo "Updated repo to latest kernel release version"
    echo
EOF

echo "Returned to root privileges."

# Build the local kernel packages for release “f41”
KERNEL_BRANCH=$(uname -r | awk -F. '{print $(NF-1)}' | sed -e 's/fc/f/')
echo "Compiling kernel as root..."
fedpkg --release $KERNEL_BRANCH local
echo
echo "Kernel compiled"
echo

# Extract the kernel version from one of the RPM filenames
KERNEL_RPM=$(ls $KERNEL_ARCH/kernel-*.rpm 2>/dev/null | head -n 1)
if [[ -z "$KERNEL_RPM" ]]; then
  echo "No kernel RPM files were found in $KERNEL_ARCH. Exiting."
  exit 1
fi

# The regex below looks for a pattern like: kernel-<major>.<minor>.<patch>e.g. kernel-5.15.12...rpm
KERNEL_VER=$(echo "$KERNEL_RPM" | sed -E 's/.*kernel-([0-9]+\.[0-9]+\.[0-9]+-[0-9]+).*\.rpm/\1/')
if [[ -z "$KERNEL_VER" ]]; then
  echo "Could not determine kernel version from RPM name: $KERNEL_RPM"
  exit 1
fi

echo "Kernel version identified as $KERNEL_VER"
echo "Kernel architecture identified as $KERNEL_ARCH"

echo "Installing new kernel packages..."
../update-fedora.sh
