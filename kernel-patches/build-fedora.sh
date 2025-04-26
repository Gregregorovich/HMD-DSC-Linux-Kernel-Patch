#!/bin/bash

KERNEL_BRANCH=$(uname -r | awk -F. '{print $(NF-1)}' | sed -e 's/fc/f/')

clear

# Change working directory to script's directory
cd $(dirname "$0")

# Change to the kernel source directory and update
cd kernel || { echo "Cannot change directory to kernel"; exit 1; }

echo "Updating repo to latest kernel release version..."
git pull origin $KERNEL_BRANCH --rebase
echo "Updated repo to latest kernel release version"
echo

# Build the local kernel packages for release “f41”
echo "Compiling kernel..."
fedpkg --release $KERNEL_BRANCH local
echo
echo "Kernel compiled"
echo

# Extract the kernel version from one of the RPM filenames
KERNEL_RPM=$(ls x86_64/kernel-*.rpm 2>/dev/null | head -n 1)
if [[ -z "$KERNEL_RPM" ]]; then
  echo "No kernel RPM files were found in x86_64. Exiting."
  exit 1
fi

# The regex below looks for a pattern like: kernel-<major>.<minor>.<patch>e.g. kernel-5.15.12...rpm
KERNEL_VER=$(echo "$KERNEL_RPM" | sed -E 's/.*kernel-([0-9]+\.[0-9]+\.[0-9]+-[0-9]+).*\.rpm/\1/')
if [[ -z "$KERNEL_VER" ]]; then
  echo "Could not determine kernel version from RPM name: $KERNEL_RPM"
  exit 1
fi

echo "Kernel version identified as $KERNEL_VER"

echo "Installing new kernel packages..."
echo "If sudo times out, run ./update-fedora.sh"
../update-fedora.sh
