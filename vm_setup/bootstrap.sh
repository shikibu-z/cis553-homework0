#!/bin/bash

# Print script commands.
set -x
# Exit on errors.
set -e

BMV2_COMMIT="1.14.0"
PI_COMMIT="7b29612fe6a0f33d8668b7fce20457116179eda2"
P4C_COMMIT="772630a08803c78aa20b12d33e28f2d1ec0753d9"
PROTOBUF_COMMIT="tags/v3.6.1"
GRPC_COMMIT="tags/v1.17.2"

NUM_CORES=$((`grep -c ^processor /proc/cpuinfo` * 3))

# Mininet
echo "Starting mininet installation..." >> /home/vagrant/vagrant-cis553.log
git clone git://github.com/mininet/mininet mininet
cd mininet
sudo ./util/install.sh -nwv
cd ..

# Protobuf
echo "Starting protobuf installation..." >> /home/vagrant/vagrant-cis553.log
git clone https://github.com/google/protobuf.git
cd protobuf
git checkout ${PROTOBUF_COMMIT}
git submodule update --init --recursive
./autogen.sh
#./configure --prefix=/usr
./configure
make -j${NUM_CORES}
sudo make install
sudo ldconfig
cd python
python setup.py build
## needs to be pip install . or else we get namspace conflicts
pip install .
cd ..
make clean
cd ..

# gRPC
echo "Starting gRPC installation..." >> /home/vagrant/vagrant-cis553.log
git clone https://github.com/grpc/grpc.git
cd grpc
git checkout ${GRPC_COMMIT}
git submodule update --init --recursive
make -j${NUM_CORES}
sudo make install
sudo ldconfig
make clean
cd ..
# Install gRPC Python Package
sudo pip install grpcio

# BMv2 deps (needed by PI)
echo "Starting BMv2 dependency installation..." >> /home/vagrant/vagrant-cis553.log
git clone https://github.com/p4lang/behavioral-model.git
cd behavioral-model
git checkout ${BMV2_COMMIT}
./install_deps.sh
./autogen.sh
./configure --enable-debugger
cd ..

# PI/P4Runtime
echo "Starting PI installation..." >> /home/vagrant/vagrant-cis553.log
git clone https://github.com/p4lang/PI.git
cd PI
git checkout ${PI_COMMIT}
git submodule update --init --recursive
./autogen.sh
./configure --with-proto
make -j${NUM_CORES}
sudo make install
sudo ldconfig
make clean
cd ..

# Bmv2
echo "Starting BMv2 installation..." >> /home/vagrant/vagrant-cis553.log
cd behavioral-model
./autogen.sh
./configure --enable-debugger --with-pi
make -j${NUM_CORES}
sudo make install
sudo ldconfig
# Simple_switch_grpc target
cd targets/simple_switch_grpc
./autogen.sh
./configure
make -j${NUM_CORES}
sudo make install
sudo ldconfig
cd ../..
make clean
cd ..

# P4C
echo "Starting P4C installation..." >> /home/vagrant/vagrant-cis553.log
git clone https://github.com/p4lang/p4c
cd p4c
git checkout ${P4C_COMMIT}
git submodule update --init --recursive
mkdir -p build
cd build
cmake ..
make -j${NUM_CORES}
sudo make install
sudo ldconfig
cd ..
cd ..
