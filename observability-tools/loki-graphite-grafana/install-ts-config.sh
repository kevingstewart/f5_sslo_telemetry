#!/bin/bash

CREDS=admin:admin
BIGIP=$1
CONFIG=$2


## send configuration
curl -sku ${CREDS} -H 'Content-Type: application/json' -X POST "https://${BIGIP}/mgmt/shared/telemetry/declare" --data @${CONFIG}