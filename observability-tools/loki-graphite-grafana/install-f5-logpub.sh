#!/bin/bash

CREDS='admin:admin'
SYSLOG='OBSERVABILITY-SERVER-IP-HERE:1514'
BIGIP=$1
POLICY=$2


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

## Attach the log publisher to the SSLO policy
DATA="{\"name\":\"sslo_${POLICY}.app/sslo_${POLICY}-log-setting\",\"access\":[{\"name\":\"general-log\",\"logLevel\":{\"sslOrchestrator\":\"info\"},\"publisher\":\"loki-syslog-pub\",\"type\":\"ssl-orchestrator\"}]}"
curl -sku 'admin:admin' -H "Content-Type: application/json" -X PATCH "https://172.16.1.77/mgmt/tm/apm/log-setting/sslo_${POLICY}.app~sslo_${POLICY}-log-setting" --data ${DATA}