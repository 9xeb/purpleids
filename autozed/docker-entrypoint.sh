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

  yesterday=$(date --date="yesterday" +%Y-%m-%d)
  # Parse certs logs in separate pools
  for key in "${!zeek_log_groups[@]}"; do
    zed drop -f /network/aggregated/${key}
    zed create /network/aggregated/${key}
    for value in ${zeek_log_groups[$key]}; do
      for zeeklog in $(find /zeek-logs/${yesterday} -type f -name ${value}'*'); do
        gzip -c -d ${zeeklog}
      done
    done | zed load -use /network/aggregated/${key} - && echo "[archive] Reloaded yesterday's logs in "${key}
  done

  # repeat a five minutes cycle 288 times, 300 s * 288 s = 86400 s = 24 hours
  #zed create /network/aggregated/suricata
  for i in $(seq 288); do
    #zed load -use /network/aggregated/suricata /suricata-logs/eve.json && echo "[suricata] Refreshed current suricata logs"

    for key in "${!zeek_log_groups[@]}"; do
      for value in ${zeek_log_groups[$key]}; do
        # zed load -use /network/aggregated/${key} $(find /zeek-spool -type f -name ${value}'*' | tr '\n' ' ') && echo "[zeek] Refreshed current "${value}" logs in "${key}
        find /zeek-spool/ -type f -name ${value}'*' -exec cat {} \; 2>/dev/null
      done | zed load -use /network/aggregated/${key} - && echo "[zeek] Refreshed current logs in "${key}
    done

    zed create /network/beacons
    zed load -use /network/beacons /rita-logs/beacons.csv /rita-logs/beacons-sni.csv

    # Revert current pools
    sleep 300
    #zed revert -use /network/aggregated/suricata $(zed -use /network/aggregated/suricata log | head -n 1 | cut -d' ' -f 2) && echo "[suricata] Reverted current suricata logs"
    for key in "${!zeek_log_groups[@]}"; do
      zed ls /network/aggregated/${key} && echo "[zeek] Reverting current logs in "${key} && zed revert -use /network/aggregated/${key} $(zed -use /network/aggregated/${key} log | head -n 1 | cut -d' ' -f 2) && echo "[zeek] Reverted current logs in "${key}
#      for value in ${zeek_log_groups[$key]}; do
#        #echo "[zeek] Reverting current "${value}" logs in "${key}
#        zed ls /network/aggregated/${key} && echo "[zeek] Reverting current "${value}" logs in "${key} && zed revert -use /network/aggregated/${key} $(zed -use /network/aggregated/${key} log | head -n 1 | cut -d' ' -f 2) && echo "[zeek] Reverted current "${value}" logs in "${key}
#      done
    done

    zed drop -f /network/beacons
    #zed revert -use /network/beacons $(zed -use /network/beacons log | head -n 1 | cut -d' ' -f 2)
  done
done
#tail -F /zed/zlake.log
