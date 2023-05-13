# PurpleIDS
A docker compose configuration for __intrusion detection__, __DoS__ and __exploitation protection__, and __threat hunting__. It is meant to run in 9xeb/purplesec, hence the misaligned paths in some compose files. It has its own repo for easier versioning only.


Originally developed for my own homelab, I believe it can be applied to many small environments that need to propel their detection from zero to decent.

## A note on logs
Logs are imported via docker volumes or bind mounts. Out of all solutions, this turned out to be the best tradeoff between applicability and complexity of setup.
Check my purplesec repo for a clever setup using multi host NFS docker volumes running through SSH tunnels, ensuring easy logs imports and much lower costs compared to solutions like Elasticsearch for small scale networks.


Currently supported logs are:
 * Zeek logs and Suricata eve.json files
 * access.log files from web servers out of the box, and anything else the Crowdsec Hub covers with some minimal adjustments.

## How it works
A set of containers working together for a common goal, following different analysis techniques.


__Crowdsec__ performs behavior detection on logs (mostly tested with web logs from reverse proxies and web apps, but anything from the Crowdsec Hub should work fine) and provides the tools for automated response at the network level.


__RITA__ does its magic and detects beacons. I wrote a custom RITA docker image to perform continuous and periodic scanning of yesterday's Zeek logs, regularly outputting csv logs.


__Diamond__ ingests log lines and spits out JSON records containing correlated observables in triads. External artifacts (IP addresses, domain names) are grouped with a vector (hash or url) and an internal asset (internal IP address) inspired by the diamond model of intrusion analysis. Additionally, single observables are analyzed via small customizable scripts called handlers that refer to OSINT feeds. Still a bit clunky and a WIP, but I'm optimistic I'll sort it out soon enough.


Last but not least, __Autozed__. A custom docker image based on the awesome Zed project by Brim Data. I tried to leverage Zed data lakes creatively to expose an API for threat hunting. Zeek and RITA logs are loaded into the lake following a rolling strategy that retains up to the last 24 hours of logs, and refreshes every 5 minutes. You can connect to the data lake using Zui (formerly Brim) and perform all sorts of queries. In the future I plan to add some default queries that best use the data that is available.

## How to use
Connect to tcp/9867 using Zui and explore all the available logs to perform threat hunting using the powerful Zed query language. Beacons, certificates, addresses, ports, protocols and software fingerprints are some of the information that are ready at hand, refreshed regularly.


There will be something available to monitor what the Crowdsec agent is doing soon. For now you'll have to query the agent from terminal.
## Future additions
 * Refactoring and better code readability
 * Support for other vectors than hashes, for example URLs
 * IPv6 support
 * Better integration with Crowdsec's LAPI for active response
 * Virustotal integration in diamond
 * Crowdsec daily report in zed data lake
