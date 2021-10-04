#!/bin/bash

CREDS=$1
BIGIP=$2
POLICY=$3
SYSLOG=$4

if [ $# -eq 4 ]
then
    ## Create remote syslog pool
    DATA="{\"name\":\"loki-syslog-pool\",\"monitor\":\"/Common/gateway_icmp\",\"members\":[\"${SYSLOG}\"]}"
    curl -sku ${CREDS} -H "Content-Type: application/json" "https://${BIGIP}/mgmt/tm/ltm/pool" --data ${DATA}

    ## Create remote high-speed log destination
    DATA="{\"name\":\"loki-syslog-hsl-dest\",\"protocol\":\"tcp\",\"pool-name\":\"loki-syslog-pool\"}"
    curl -sku ${CREDS} -H "Content-Type: application/json" "https://${BIGIP}/mgmt/tm/sys/log-config/destination/remote-high-speed-log" --data ${DATA}

    ## Create remote high-speed log rfc5424 destination formatter 
    DATA="{\"name\":\"loki-syslog-dest\",\"format\":\"rfc5424\",\"remote-high-speed-log\":\"loki-syslog-hsl-dest\"}"
    curl -sku ${CREDS} -H "Content-Type: application/json" "https://${BIGIP}/mgmt/tm/sys/log-config/destination/remote-syslog" --data ${DATA}

    ## Create log publisher
    DATA="{\"name\":\"loki-syslog-pub\",\"destinations\":\"loki-syslog-dest\"}"
    curl -sku ${CREDS} -H "Content-Type: application/json" "https://${BIGIP}/mgmt/tm/sys/log-config/publisher" --data ${DATA}

    ## Create SSL error log filter
    DATA="{\"name\":\"filter-01260009\",\"message-id\":\"01260009\",\"publisher\":\"loki-syslog-pub\"}"
    curl -sku ${CREDS} -H "Content-Type: application/json" "https://${BIGIP}/mgmt/tm/sys/log-config/filter" --data ${DATA}

    ## Attach the log publisher to the SSLO policy - a) disable strictness, b) apply publisher, c)enable strictness, d)apply policy
    DATA="{\"name\":\"sslo_${POLICY}.app/sslo_${POLICY}\",\"strictUpdates\":\"disabled\"}"
    curl -sku ${CREDS} -H "Content-Type: application/json" -X PATCH "https://${BIGIP}/mgmt/tm/sys/application/service/sslo_${POLICY}.app~sslo_${POLICY}" --data ${DATA}

    DATA="{\"name\":\"sslo_${POLICY}.app/sslo_${POLICY}-log-setting\",\"access\":[{\"name\":\"general-log\",\"logLevel\":{\"sslOrchestrator\":\"info\"},\"publisher\":\"loki-syslog-pub\",\"type\":\"ssl-orchestrator\"}]}"
    curl -sku ${CREDS} -H "Content-Type: application/json" -X PATCH "https://${BIGIP}/mgmt/tm/apm/log-setting/sslo_${POLICY}.app~sslo_${POLICY}-log-setting" --data ${DATA}

    DATA="{\"name\":\"sslo_${POLICY}.app/sslo_${POLICY}\",\"strictUpdates\":\"enabled\"}"
    curl -sku ${CREDS} -H "Content-Type: application/json" -X PATCH "https://${BIGIP}/mgmt/tm/sys/application/service/sslo_${POLICY}.app~sslo_${POLICY}" --data ${DATA}

    DATA="{\"name\":\"sslo_${POLICY}.app/sslo_${POLICY}_accessProfile\",\"generation-action\":\"increment\"}"
    curl -sku ${CREDS} -H "Content-Type: application/json" -X PATCH "https://${BIGIP}/mgmt/tm/apm/profile/access/sslo_${POLICY}.app~sslo_${POLICY}_accessProfile" --data ${DATA}
else
    echo
    echo "Usage: $0 [CREDS] [BIG-IP] [POLICY] [SYSLOG]"
    echo
    echo "Where:"
    echo "  CREDS:  BIG-IP user:pass                ex. 'admin:admin'"
    echo "  BIG-IP: IP of target BIG-IP             ex. 10.1.1.4"
    echo "  POLICY: SSLO topology shortname         ex. demoOutL3"
    echo "  SYSLOG: Syslog listener IP:port         ex. 10.1.10.30:1514"
    echo
    echo "Example: $0 'admin:admin' 10.1.1.4 demoOutL3 10.1.10.30:1514"
    echo
fi
