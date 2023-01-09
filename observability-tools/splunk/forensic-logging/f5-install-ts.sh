#!/bin/bash
## F5 Telemetry Streaming Package Installer
## Author: Kevin Stewart, Sr. SA F5 Networks
## Revision: 1.0
## Description: pushes the latest version of the F5 TS package to the target BIG-IP
##
## Command line: requires the following:
##  CREDS: the BIG-IP username:password required to perform these administrative operations, enclosed in single quotes. Example: 'admin:admin'
##  BIGIP: the IP address of the target BIG-IP. Example: 10.1.1.4

CREDS=$1
BIGIP=$2

if [ $# -eq 2 ]
then
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
