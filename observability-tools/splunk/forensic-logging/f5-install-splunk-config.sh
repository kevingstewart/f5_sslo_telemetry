#!/bin/bash
## F5 SSLO Splunk Configuration Installer
## Author: Kevin Stewart, Sr. SA F5 Networks
## Revision: 1.0
## Description: pushes the required SSLO Splunk configuration to the target BIG-IP
##
## Command line: requires the following:
##  CREDS: the BIG-IP username:password required to perform these administrative operations, enclosed in single quotes. Example: ${CREDS}
##  BIGIP: the IP address of the target BIG-IP. Example: ${BIGIP}

CREDS=$1
BIGIP=$2

if [ $# -eq 2 ]
then
    ## Update DB variable
    curl -sku ${CREDS} -H 'Content-Type: application/json' -X PATCH "https://${BIGIP}/mgmt/tm/sys/db/tmm.tcl.rule.node.allow_loopback_addresses" -d '{"value":"true"}'
    curl -sku ${CREDS} -H 'Content-Type: application/json' -X POST "https://${BIGIP}/mgmt/tm/sys/config" -d '{"command":"save"}'

    ## Create TS Pool (BIGIP-MGMT-SELF:6514)
    DATA="{\"name\":\"splunk-ts-pool\",\"monitor\":\"/Common/tcp\",\"members\":\"${BIGIP}:6514\"}"
    curl -sku ${CREDS} -H 'Content-Type: application/json' -X POST "https://${BIGIP}/mgmt/tm/ltm/pool/" --data ${DATA}

    ## Create TS iRule
    curl -sku ${CREDS} -H 'Content-Type: application/json' -X POST "https://${BIGIP}/mgmt/tm/ltm/rule" -d '{"name":"splunk-ts-rule","apiAnonymous":"when CLIENT_ACCEPTED { node 127.0.0.1 6514  }"}'

    ## Create TS VIP (BIGIP-MGMT-SELF:6514)
    DATA="{\"name\":\"splunk-ts-vip\",\"destination\":\"${BIGIP}:6514\",\"ipProtocol\":\"tcp\",\"profiles\":\"/Common/f5-tcp-progressive\",\"sourceAddressTranslation\":{\"type\":\"automap\"},\"rules\":[\"splunk-ts-rule\"],\"vlansEnabled\":true}"
    curl -sku ${CREDS} -H 'Content-Type: application/json' -X POST "https://${BIGIP}//mgmt/tm/ltm/virtual" --data ${DATA}

    ## Create Remote HSL Log Destination
    curl -sku ${CREDS} -H 'Content-Type: application/json' -X POST "https://${BIGIP}/mgmt/tm/sys/log-config/destination/remote-high-speed-log" -d '{"name":"splunk-destination-hsl","pool-name":"splunk-ts-pool","protocol":"tcp"}'

    ## Create Splunk Log Destination
    curl -sku ${CREDS} -H 'Content-Type: application/json' -X POST "https://${BIGIP}/mgmt/tm/sys/log-config/destination/splunk" -d '{"name":"splunk-destination","forward-to":"splunk-destination-hsl"}'

    ## Create Splunk Log Publisher
    curl -sku ${CREDS} -H 'Content-Type: application/json' -X POST "https://${BIGIP}/mgmt/tm/sys/log-config/publisher" -d '{"name":"splunk-publisher","destinations":"splunk-destination"}'

    ## Create SSLO Access Policy Log Settings
    curl -sku ${CREDS} -H 'Content-Type: application/json' -X POST "https://${BIGIP}/mgmt/tm/apm/log-setting" -d '{"name": "sslo-splunk-log","access": [{"name": "splunk-sslo-access","enabled":"true","logLevel": {"sslOrchestrator": "info"},"publisher": "/Common/splunk-publisher","type": "ssl-orchestrator"}]}'

else
    echo
    echo "Usage: $0 [CREDS] [BIG-IP]"
    echo
    echo "Where:"
    echo "  CREDS:  BIG-IP user:pass                ex. 'admin:admin'"
    echo "  BIG-IP: IP of target BIG-IP             ex. 10.1.1.4"
    echo
    echo "Example: $0 'admin:admin' 10.1.1.4"
    echo
fi
