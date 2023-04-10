#!/bin/bash

# check if mongodb is up
rita list || exit

ZEEKLOGS='/zeek-logs'
while true
do
  target=$(date --date='-1 hour' +\%Y-\%m-\%d)
  echo "[rita] Importing from zeek logs (""$target"")..."
  rita import --rolling "$ZEEKLOGS"/"$target"/ rita
  echo "[rita] Beacon analysis complete (""$target"")."
  rita show-beacons rita > /data/beacons.csv
  #rita show-beacons-fqdn rita > /beacons-fqdn.csv
  #rita show-beacons-proxy rita > /beacons-proxy.csv
  rita show-beacons-sni rita > /data/beacons-sni.csv
  echo "[rita] Refreshing remote analysis results database..."
  python3 /refresh-database.py

  echo "[rita] Sleeping for 3600 seconds..."
  sleep 3600
done
