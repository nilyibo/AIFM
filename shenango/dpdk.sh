#!/bin/sh

set -e

# Delete old submodules
rm -rf dpdk
rm -rf spdk
rm -rf rdma-core

# Initialize dpdk module
git submodule init
git submodule update --recursive

# Apply driver patches
patch -p 1 -d dpdk/ < ixgbe_18_11.patch


if lspci | grep -q 'ConnectX-[4,5]'; then
   patch -p 1 -d dpdk/ < mlx5_18_11.patch
elif lspci | grep -q 'ConnectX-3'; then
    patch -p 1 -d dpdk/ < mlx4_18_11.patch
    sed -i 's/CONFIG_RTE_LIBRTE_MLX4_PMD=n/CONFIG_RTE_LIBRTE_MLX4_PMD=y/g' dpdk/config/common_base
fi

# patch for Linux kernel 5.3+ falls through behavior
# Source: https://inbox.dpdk.org/stable/20190729123216.64601-1-ferruh.yigit@intel.com/T/
patch -p 1 -d dpdk/ < falls_through.patch

# Configure/compile dpdk
make -C dpdk/ config T=x86_64-native-linuxapp-gcc
make -C dpdk/ -j
