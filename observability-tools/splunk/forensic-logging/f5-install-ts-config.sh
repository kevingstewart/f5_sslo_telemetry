#!/bin/bash
## F5 Telemetry Streaming Configuration Installer
## Author: Kevin Stewart, Sr. SA F5 Networks
## Revision: 1.0
## Description: pushes the required configuration to the target Telemetry Streaming package
##
## Command line: requires the following:
##  CREDS: the BIG-IP username:password required to perform these administrative operations, enclosed in single quotes. Example: 'admin:admin'
##  BIGIP: the IP address of the target BIG-IP. Example: 10.1.1.4
##  SYSLOG: the IP of the target Syslog listener service. Example: 10.1.10.30

CREDS=$1
BIGIP=$2

if [ $# -eq 2 ]
then
    ## send configuration
    curl -sku ${CREDS} -H 'Content-Type: application/json' -X POST "https://${BIGIP}/mgmt/shared/telemetry/declare" --data @f5-config-ts.json
else
    echo
    echo "Usage: $0 [CREDS] [BIG-IP] [SYSLOG]"
    echo
    echo "Where:"
    echo "  CREDS:  BIG-IP user:pass                ex. 'admin:admin'"
    echo "  BIG-IP: IP of target BIG-IP             ex. 10.1.1.4"
    echo
    echo "Example: $0 'admin:admin' 10.1.1.4"
    echo
fi
