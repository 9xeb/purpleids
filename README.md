# PurpleIDS
A docker compose configuration for intrusion detection, Dos protection and threat hunting. It is meant to run in 9xeb/purplesec, hence the misaligned paths in docker-compose.yml. It has its own repo for easier versioning only.


Originally developed for my own homelab, I believe it can be applied to many small environments that need to propel their detection from zero to decent.

## A note on logs
Logs are imported via docker volumes or bind mounts. Out of all solutions, this turned out to be the best tradeoff between applicability and complexity of setup.
Check 9xeb/purplesec for a clever setup using multi host NFS docker volumes running through SSH tunnels, ensuring easy logs imports and much lower costs compared to solutions like Elasticsearch for small scale networks.


Currently supported logs are:
 * Zeek logs and Suricata eve.json files
 * access.log files from web servers, and anything else the Crowdsec Hub covers.

## How it works
A set of containers working together for a common goal, following different analysis techniques.


Crowdsec performs behavior detection on logs (mostly tested with web logs from reverse proxies and web apps, but anything from the Crowdsec Hub should work fine) and provides the tools for automated response at the network level.


RITA does its magic and detects beacons. I wrote a custom RITA docker image to perform continuous and periodic scanning of yesterday's Zeek logs, regularly outputting csv logs.


Diamond ingests log lines and spits out JSON records containing correlated observables in triads. External artifacts (IP addresses, domain names) are grouped with a vector (hash or url) and an internal asset (internal IP address) inspired by the diamond model of intrusion analysis. Additionally, single observables are analyzed via small customizable scripts called handlers that refer to OSINT feeds. Still a bit clunky and a WIP, but I'm optimistic I'll sort it out soon enough.


Last but not least, Autozed. A custom docker image based on the awesome Zed project by Brim Data. I tried to leverage Zed data lakes creatively to expose an API for threat hunting. Zeek and RITA logs are loaded into the lake following a rolling strategy that retains up to the last 24 hours of logs, and refreshes every 5 minutes. You can connect to the data lake using Zui (formerly Brim) and perform all sorts of queries. In the future I plan to add some default queries that best use the data that is available.
