#!/bin/bash

# Run this first, then run ./build-fedora.sh
# Once run for the first time, this never needs to be run again. 
#
# Initial setup script to add patches to the Fedora kernel to support
# Display Stream Compression (DSC) and add HMDs to the non-desktop list
# To manually (re)install the most recent compiled kernel (and modules),
# run ./update-fedora.sh .
# ./update-fedora.sh is run automatically as part of the ./build-fedora.sh script.


FedoraVersion=$(uname -r | awk -F. '{print $(NF-1)}' | sed -e 's/fc/f/')
BranchName=$(echo DSC-Patch-$(uname -r | awk -F. '{print $(NF-1)}' | sed -e 's/fc/f/'))

#Sometimes git cloning fails. This ensures it sucessfully clones the repo.
while true; do
  if git clone https://src.fedoraproject.org/rpms/kernel.git; then
    echo "Clone successful!"
    break
  else
    echo "Clone failed, retrying..."
  fi
done

#Make archive for the most recent 3 installed kernels
mkdir kernel-rpms
cd kernel

git switch $FedoraVersion

git checkout -b $BranchName

patch kernel.spec ../kernel.spec.patch
cp ../000* ./

git add 000*
git stage kernel.spec
git commit -m "Added & applied kernel patches"

echo "Initial setup complete. Run ./build-fedora.sh to compile and install the patched kernel."
