#!/bin/bash

# This script reads ever changing log files from zeek and suricata, and regularly updates a zed data lake containing a set of pools
# Current zeek logs and suricata eve.json are reloaded every 5 minutes
# Rotated zeek logs are reloaded every 24 hours
# in principle, this procedure can be applied to any log flow readable by zed, hence the name 'autozed'
# though there is some overhead due to the occasional drop/reload procedure, it is NOTHING compared to solutions like Elasticsearch, and it it just as widely applicable thanks to the ZSON format
# think about the benefits of simply putting log files in a directory (even a mesh of remote folders with sshnfs) and having them periodically and autonomously parsed by autozed, for you to perform queries via Brim/Zui


# log categories inspired by zeek docs
declare -A zeek_log_groups
zeek_log_groups[network]='conn dce_rpc dhcp dnp3 dns ftp http irc kerberos modbus mysql ntlm ntp radius rdp rfb sip smb smtp snmp socks ssh ssl syslog tunnel'
zeek_log_groups[files]='files'
zeek_log_groups[observations]='known_certs known_hosts known_modbus known_services software'
zeek_log_groups[certs]='x509 ocsp'
#zeek_logs_blacklist='intel notice notice_alarm signatures traceroute broker capture_loss cluster config loaded_scripts packet_filter print prof reporter stats stderr stdout'

while true; do
  zed serve -l 0.0.0.0:9867 -lake /zed/.zedlake -log.level=info -log.filemode=rotate -log.path=/zed/zlake.log
done &

# workaround, wait 1 sec for zed service to start up
# TODO: improve this, instead of waiting a fixed time, loop test connection to zed lake until it responds, then proceed
while zed ls 2>&1 | grep refused; do
  sleep 5
done


# every 24 hours loads yesterday's zeek logs
# every 5 minutes rebuild pool with latest eve.json and zeek current logs
while true; do
  zed drop -f /unified
  zed create /unified
  {
    yesterday=$(date --date="yesterday" +%Y-%m-%d);
    for key in "${!zeek_log_groups[@]}"; do
      for value in ${zeek_log_groups[$key]}; do
        for zeeklog in $(find /zeek-logs/${yesterday} -type f -name ${value}'*'); do
          gzip -c -d ${zeeklog}
        done
      done
    done;
  } | grep '^{' | zed load -use /unified - && echo "[unified] Reloaded yesterday's logs"

  for i in $(seq 288); do
    {
      for key in "${!zeek_log_groups[@]}"; do
        for value in ${zeek_log_groups[$key]}; do
          find /zeek-spool/ -type f -name ${value}'*' -exec cat {} \; 2>/dev/null
        done
      done;
      #cat /rita-logs/beacons.csv /rita-logs/beacons-sni.csv;
      # intel/diamond /intel/tags;
    } | grep '^{' | zed load -use /unified - && echo "[unified] Reloaded current zeek logs"
    cat /rita-logs/beacons.csv | zed load -use /unified - && echo "[unified] Reloaded current rita beacons"
    cat /rita-logs/beacons-sni.csv | zed load -use /unified - && echo "[unified] Reloaded current rita beacons sni"
    sleep 300
    # revert for each load
    for i in $(zed log -use /unified | grep '^commit' | cut -d' ' -f2 | head -n 3); do
      zed revert -use /unified ${i}
    done
  done
done