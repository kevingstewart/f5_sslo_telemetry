#!/bin/bash

CREDS="admin:admin"
BIGIP=$1

## Get the latest F5 Telemetry Streaming package
tag=$(curl -sk https://api.github.com/repos/F5Networks/f5-telemetry-streaming/releases/latest |egrep "tag_name" | cut -d '"' -f 4)
file=$(curl -sk https://api.github.com/repos/F5Networks/f5-telemetry-streaming/releases/latest | egrep '\"f5-telemetry-.*.rpm\"' | cut -d '"' -f 4)
curl -sk --location "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/${tag}/${file}" -o ${file}

## upload RPM
LEN=$(wc -c ${file} | grep -o -E '[0-9]{4,}')
curl -sku ${CREDS} "https://${BIGIP}/mgmt/shared/file-transfer/uploads/${file}" -H 'Content-Type: application/octet-stream' -H "Content-Range: 0-$((LEN - 1))/$LEN" -H "Content-Length: $LEN" -H 'Connection: keep-alive' --data-binary @${file}

## install RPM
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/${file}\"}"
curl -sku ${CREDS} "https://${BIGIP}/mgmt/shared/iapp/package-management-tasks" -H "Origin: https://${BIGIP}" -H 'Content-Type: application/json;charset=UTF-8' --data ${DATA}
