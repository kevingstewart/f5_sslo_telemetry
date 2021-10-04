#!/bin/bash

CREDS=$1
BIGIP=$2
SYSLOG=$3

if [ $# -eq 3 ]
then
    ## Update the config file
    sed -ie "s/\"host\":.*,/\"host\":\"${SYSLOG}\",/g" config-f5-ts.json

    ## send configuration
    curl -sku ${CREDS} -H 'Content-Type: application/json' -X POST "https://${BIGIP}/mgmt/shared/telemetry/declare" --data @config-f5-ts.json
else
    echo
    echo "Usage: $0 [CREDS] [BIG-IP] [SYSLOG]"
    echo
    echo "Where:"
    echo "  CREDS:  BIG-IP user:pass                ex. 'admin:admin'"
    echo "  BIG-IP: IP of target BIG-IP             ex. 10.1.1.4"
    echo "  SYSLOG: IP of the Syslog listener       ex. 10.1.10.30"
    echo
    echo "Example: $0 'admin:admin' 10.1.1.4 10.1.10.30"
    echo
fi