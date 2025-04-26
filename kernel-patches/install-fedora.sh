#!/bin/bash

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
