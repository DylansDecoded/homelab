#!/bin/bash
set -e

GO_VERSION="1.22.3"
GO_URL="https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
# EXPECTED_CHECKSUM="b945ae2bb5db01a0fb4786afde64e6fbab50b67f6fa0eb6cfa4924f16a7ff1eb"

# Log output of script
exec > >(tee -i /home/ubuntu/install.log)
exec 2>&1

echo "Updating package manager and installing necessary packages..."
# sudo apt update && sudo apt upgrade -y
# sudo apt install -y git make

# Set home and cache directories
export HOME=/home/ubuntu
export GOCACHE=$HOME/.cache

if ! go version | grep -q "${GO_VERSION}" ; then
  echo "Downloading and installing Go..."
  # Download the Go binary
  curl -OL ${GO_URL}
  # Verify the checksum
#   ACTUAL_CHECKSUM=$(sha256sum go${GO_VERSION}.linux-amd64.tar.gz | awk '{print $1}')
  # if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    # echo "Checksum verification failed. Aborting installation."
    # exit 1
  fi
  # Remove existing Go installation if it exists
  if [ -d "/usr/local/go" ]; then
    sudo rm -rf /usr/local/go
  fi
  # Extract the tarball
  sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
  # Remove the downloaded tarball
  rm go${GO_VERSION}.linux-amd64.tar.gz
  echo "Setting up Go environment..."
  # Add Go to the PATH environment variable for ubuntu user
  if ! grep -q 'export PATH=$PATH:/usr/local/go/bin' /root/.profile ; then
    echo "export PATH=\$PATH:/usr/local/go/bin" >> /root/.profile
  fi
  # Add Go to the PATH environment variable for current script
  export PATH=$PATH:/usr/local/go/bin

echo "Enabling byobu..."
byobu-enable

echo "Modifying systemd-resolved configuration..."
sudo sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

echo "Cloning evilginx repository..."
if [ ! -d "/home/ubuntu/src-evilginx" ]; then
    git clone https://github.com/kgretzky/evilginx2 /root/src-evilginx
fi

echo "Removing evilginx indicator (X-Evilginx header)..."
sed -i 's/req.Header.Set(p.getHomeDir(), o_host)/\/\/req.Header.Set(p.getHomeDir(), o_host)/' /root/src-evilginx/core/http_proxy.go
sed -i 's/o_host := req.Host/\/\/o_host := req.Host/' /root/src-evilginx/core/http_proxy.go

echo "Building evilginx repository..."
cd /root/src-evilginx
go build
make

echo "Setting up evilginx directory..."
mkdir -p /root/evilginx
cp /root/src-evilginx/build/evilginx /root/evilginx/
cd /root/evilginx
mkdir -p phishlets redirectors

echo "Setting permissions to allow evilginx to bind to privileged ports..."
sudo setcap CAP_NET_BIND_SERVICE=+eip evilginx

echo "Removing the src-evilginx directory"
rm -rf /root/src-evilginx

echo "Done"
exit 0