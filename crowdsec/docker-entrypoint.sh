#!/bin/bash

for type in $all_crowdsec_collections; do
(cat << EOF
---
filename: /${type}/testweb.log
labels:
  type: ${type}
---
EOF
 ) >> /etc/crowdsec/acquis.yaml
done

/docker_start.sh
