#!/bin/bash

if [ -x /usr/local/bin/rita ]; then
  echo "[V] rita is already installed"
else
  apt-get update && apt-get -y install make golang gnupg2 git
  echo "[*] Setting up rita"
  git clone https://github.com/activecm/rita.git
  cd rita
  make
  #wget https://github.com/rita/releases/download/v4.4.0/rita
  cp ./rita /usr/local/bin/rita
  mkdir /etc/rita && chmod 755 /etc/rita
  mkdir -p /var/lib/ritalogs && chmod -R 755 /var/lib/ritalogs
  make clean
  #cp etc/rita.yaml /etc/rita/config.yaml && chmod 666 /etc/rita/config.yaml
  cd .. && rm -rf rita
  apt-get -y purge make golang gnupg2 git && apt-get -y autoremove
fi
echo 'At this point you can modify config.yaml and run "rita test-config" to test the config'
exit

# RITA REQUIRES MONGODB BETWEEN 4.2.0 and 4.3.0
