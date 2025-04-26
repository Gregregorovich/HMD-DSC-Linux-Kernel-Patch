#!/bin/bash

# Kernel branch; e.g.: f41 / rawhide
KERNEL_BRANCH=$(uname -r | awk -F. '{print $(NF-1)}' | sed -e 's/fc/f/')
# Kernel version installed
KERNEL_INSTALLED=$(uname -r | sed -e "s/\.$(uname -r | awk -F. '{print $(NF-1)}').*//")
# Directory to check for compiled kernels
KERNEL_RPM_DIR="./kernel-rpms"
# Number of previous compiled kernels to keep
NUM_VERSIONS_TO_KEEP=4
# Kernel Version format (e.g., 5.15.10-200)
VERSION_REGEX="^.*[0-9]+\.[0-9]+\.[0-9]+-[0-9]+.*$"

# Change working directory to script's directory
cd $(dirname "$0")

# Change to the kernel source directory and update
cd kernel || { echo "Cannot change directory to kernel"; exit 1; }

# Extract the kernel version from one of the RPM filenames
KERNEL_RPM=$(ls x86_64/kernel-*.rpm 2>/dev/null | head -n 1)
if [[ -z "$KERNEL_RPM" ]]; then
  KERNEL_RPM=$(ls ../kernel-rpms/$KERNEL_INSTALLED/kernel-*.rpm 2>/dev/null | head -n 1)
  if [[ -z "$KERNEL_RPM" ]]; then
    echo "No kernel RPM files were found in x86_64. Exiting."
    exit 1
  fi
  REINSTALL=true
  read -p "Do you want to reinstall the most recent compiled kernel ($KERNEL_INSTALLED)? (y/n) " answer
  if [[ $answer != y ]] || [[ $answer != yes ]] || [[ $answer != Y ]] || [[ $answer != YES ]] || [[ $answer != Yes ]]; then
    echo "Exiting..."
    #exit 1
  fi
fi

# The regex below looks for a pattern like: kernel-<major>.<minor>.<patch>-<???>e.g. kernel-5.15.12-200...rpm
KERNEL_VER=$(echo "$KERNEL_RPM" | sed -E 's/.*kernel-([0-9]+\.[0-9]+\.[0-9]+-[0-9]+).*\.rpm/\1/')
if [[ -z "$KERNEL_VER" ]]; then
  echo "Could not determine kernel version from RPM name: $KERNEL_RPM"
  exit 1
fi

echo "Kernel version compiled: $KERNEL_VER"
echo "Kernel version installed: $KERNEL_INSTALLED"

if [[ $KERNEL_VER == $KERNEL_INSTALLED ]]; then
    echo "Reinstalling new kernel packages..."
    echo "If sudo times out, run ./update-fedora.sh"
    # Install the generated RPM packages
    sudo dnf reinstall --nogpgcheck \
        ./x86_64/kernel-[0-9]*.rpm \
        ./x86_64/kernel-{core*.rpm,modules-[0-9]*.rpm,modules-core*.rpm,modules-extra*.rpm,devel-[0-9]*.rpm,devel-matched-[0-9]*.rpm}
else
    echo "Installing new kernel packages..."
    echo "If sudo times out, run ./update-fedora.sh"
    # Install the generated RPM packages
    sudo dnf install --nogpgcheck \
        ./x86_64/kernel-[0-9]*.rpm \
        ./x86_64/kernel-{core*.rpm,modules-[0-9]*.rpm,modules-core*.rpm,modules-extra*.rpm,devel-[0-9]*.rpm,devel-matched-[0-9]*.rpm}
fi
echo "Kernel updated"
echo

# Create the destination directory named for the kernel version
DEST_DIR="../kernel-rpms/$KERNEL_VER"
ARCHIVE_DIR="../kernel-rpms"
mkdir -p "$DEST_DIR"

# Move all RPMs containing the version into the dedicated directory
if [[ $REINSTALL != true ]]; then
  mv x86_64/*"${KERNEL_VER}"*.rpm "$DEST_DIR"/
fi

# Now, delete directories in ../kernel-rpms that are older than the current plus 3 previous versions.
cd "$ARCHIVE_DIR" || { echo "Cannot change to ../kernel-rpms"; exit 1; }

    # Initialize the directories array
    declare -a directories

    # Find directories matching the regex and extract the version string
    #directories=$(
    directories=($(find ".$KERNEL_RPM_DIR" -maxdepth 1 -type d -regex "$VERSION_REGEX" |
      sed -E 's/^\./\0/' |  # Add leading dot for sort -V
      sort -V))

    # Calculate the number of directories to delete
    num_to_delete=$(( ${#directories[@]} - $NUM_VERSIONS_TO_KEEP ))
    echo "To delete: $num_to_delete old versions"

    # Delete the oldest directories
    for ((i=0; i<$num_to_delete; i++)); do
      dir_to_delete="${directories[$i]}"
      echo "Deleting directory: $dir_to_delete"
      rm -rf "$dir_to_delete"
    done

echo "Kernel updated, RPMs backed up, and old RPMs removed."
echo
read -p "Do you want to update all other packages and flatpaks on this system? (y/n) " answer
if [[ $answer == y ]] || [[ $answer == yes ]] || [[ $answer == Y ]] || [[ $answer == YES ]] || [[ $answer == Yes ]]; then
    echo "Updating remaining packages and flatpaks..."
    sudo dnf update --refresh -y --exclude=kernel,kernel-core,kernel-modules,kernel-modules-core,kernel-modules-extra,kernel-devel,kernel-devel-matched
    flatpak update -y
    echo "Updated remaining packages and flatpaks"
fi
