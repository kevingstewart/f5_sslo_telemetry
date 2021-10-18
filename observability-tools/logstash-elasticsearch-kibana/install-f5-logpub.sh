#!/bin/bash
## SSLO Summary Log Object Creator
## Author: Kevin Stewart, Sr. SA F5 Networks
## Revision: 1.0
## Description: creates the complete set of objects required to push SSL Orchestrator summary logs to a remote Syslog. This will create a new SSL Orchestrator
## per-session policy that can be selected in the SSLO topology workflow (Interception Rules page). Creates the following objects:
##   Syslog pool
##   Remote HSL destination
##   Remote HSL RFC52424 formatter
##   Log publisher
##   SSL error log filter
##   Access event log settings
##   SSLO access profile (via transaction):
##     Customization groups (logout, eps, errormap, framework-installation, general-ui)
##     Allow ending
##     Policy items (Entry, allow ending)
##     Policy
##     Profile
##
## Command line: requires the following:
##  CREDS: the BIG-IP username:password required to perform these administrative operations, enclosed in single quotes. Example: 'admin:admin'
##  BIGIP: the IP address of the target BIG-IP. Example: 10.1.1.4
##  SYSLOG: the IP and port of the target Syslog listener service. Example: 10.1.10.30:1514

BASE='loki'

CREDS=$1
BIGIP=$2
SYSLOG=$3

if [ $# -eq 3 ]
then
    ## Create remote syslog pool
    JSON="{\"name\":\"${BASE}-syslog-pool\",\"monitor\":\"/Common/gateway_icmp\",\"members\":[\"${SYSLOG}\"]}"
    curl -sku ${CREDS} -X POST "https://${BIGIP}/mgmt/tm/ltm/pool" -H "Content-Type: application/json" --data ${JSON} > /dev/null 2>&1

    ## Create remote high-speed log destination
    JSON="{\"name\":\"${BASE}-syslog-hsl-dest\",\"protocol\":\"tcp\",\"pool-name\":\"${BASE}-syslog-pool\"}"
    curl -sku ${CREDS} -X POST "https://${BIGIP}/mgmt/tm/sys/log-config/destination/remote-high-speed-log" -H "Content-Type: application/json" --data ${JSON} > /dev/null 2>&1

    ## Create remote high-speed log rfc5424 destination formatter 
    JSON="{\"name\":\"${BASE}-syslog-dest\",\"format\":\"rfc5424\",\"remote-high-speed-log\":\"${BASE}-syslog-hsl-dest\"}"
    curl -sku ${CREDS} -X POST "https://${BIGIP}/mgmt/tm/sys/log-config/destination/remote-syslog" -H "Content-Type: application/json" --data ${JSON} > /dev/null 2>&1

    ## Create log publisher
    JSON="{\"name\":\"${BASE}-syslog-pub\",\"destinations\":\"${BASE}-syslog-dest\"}"
    curl -sku ${CREDS} -X POST "https://${BIGIP}/mgmt/tm/sys/log-config/publisher" -H "Content-Type: application/json" --data ${JSON} > /dev/null 2>&1

    ## Create SSL error log filter
    JSON="{\"name\":\"filter-01260009\",\"message-id\":\"01260009\",\"publisher\":\"${BASE}-syslog-pub\"}"
    curl -sku ${CREDS} -X POST "https://${BIGIP}/mgmt/tm/sys/log-config/filter" -H "Content-Type: application/json" --data ${JSON} > /dev/null 2>&1

    ## Create access log setting
    JSON="{\"name\":\"sslo-${BASE}-log-settings\",\"access\":[{\"name\":\"general-log\",\"logLevel\":{\"sslOrchestrator\":\"info\"},\"publisher\":\"${BASE}-syslog-pub\",\"type\":\"ssl-orchestrator\"}]}"
    curl -sku ${CREDS} -X POST "https://${BIGIP}/mgmt/tm/apm/log-setting" -H "Content-Type: application/json" --data ${JSON} > /dev/null 2>&1

    ## Create access profile transaction
    transid=`curl -sku "${CREDS}" -H "Accept: application/json" -H "Content-Type: application/json" "https://${BIGIP}/mgmt/tm/transaction" -d '{}' |awk -F"," '{ print $1 }' |awk -F":" '{ print $2 }'`

    ## Create customization groups
    JSON="{\"name\":\"sslo-telemetry-${BASE}_logout\",\"partition\":\"Common\",\"source\":\"/Common/standard\",\"type\":\"logout\"}"
    curl -sku "${CREDS}" -X POST "https://${BIGIP}/mgmt/tm/apm/policy/customization-group" -H "Content-Type:application/json" -H "X-F5-REST-Coordination-Id:${transid}" --data ${JSON} > /dev/null 2>&1

    JSON="{\"name\":\"sslo-telemetry-${BASE}_eps\",\"partition\":\"Common\",\"source\":\"/Common/standard\",\"type\":\"eps\"}"
    curl -sku "${CREDS}" -X POST "https://${BIGIP}/mgmt/tm/apm/policy/customization-group" -H "Content-Type:application/json" -H "X-F5-REST-Coordination-Id:${transid}" --data ${JSON} > /dev/null 2>&1

    JSON="{\"name\":\"sslo-telemetry-${BASE}_errormap\",\"partition\":\"Common\",\"source\":\"/Common/standard\",\"type\":\"errormap\"}"
    curl -sku "${CREDS}" -X POST "https://${BIGIP}/mgmt/tm/apm/policy/customization-group" -H "Content-Type:application/json" -H "X-F5-REST-Coordination-Id:${transid}" --data ${JSON} > /dev/null 2>&1

    JSON="{\"name\":\"sslo-telemetry-${BASE}_framework_installation\",\"partition\":\"Common\",\"source\":\"/Common/standard\",\"type\":\"framework-installation\"}"
    curl -sku "${CREDS}" -X POST "https://${BIGIP}/mgmt/tm/apm/policy/customization-group" -H "Content-Type:application/json" -H "X-F5-REST-Coordination-Id:${transid}" --data ${JSON} > /dev/null 2>&1

    JSON="{\"name\":\"sslo-telemetry-${BASE}_general_ui\",\"partition\":\"Common\",\"source\":\"/Common/standard\",\"type\":\"general-ui\"}"
    curl -sku "${CREDS}" -X POST "https://${BIGIP}/mgmt/tm/apm/policy/customization-group" -H "Content-Type:application/json" -H "X-F5-REST-Coordination-Id:${transid}" --data ${JSON} > /dev/null 2>&1

    ## Create ending
    JSON="{\"name\":\"sslo-telemetry-${BASE}_end_allow_ag\",\"partition\":\"Common\"}"
    curl -sku "${CREDS}" -X POST "https://${BIGIP}/mgmt/tm/apm/policy/agent/ending-allow/" -H "Content-Type:application/json" -H "X-F5-REST-Coordination-Id:${transid}" --data ${JSON} > /dev/null 2>&1

    ## Create policy items
    JSON="{\"name\":\"sslo-telemetry-${BASE}_end_allow\",\"partition\":\"Common\",\"caption\":\"Allow\",\"color\":1,\"itemType\":\"ending\",\"agents\":[{\"name\":\"sslo-telemetry-${BASE}_end_allow_ag\",\"partition\":\"Common\",\"type\":\"ending-allow\"}]}"
    curl -sku "${CREDS}" -X POST "https://${BIGIP}/mgmt/tm/apm/policy/policy-item/" -H "Content-Type:application/json" -H "X-F5-REST-Coordination-Id:${transid}" --data ${JSON} > /dev/null 2>&1

    JSON="{\"name\":\"sslo-telemetry-${BASE}_ent\",\"partition\":\"Common\",\"caption\":\"Start\",\"color\":1,\"itemType\":\"entry\",\"loop\":\"false\",\"rules\":[{\"caption\":\"fallback\",\"nextItem\":\"/Common/sslo-telemetry-${BASE}_end_allow\"}]}"
    curl -sku "${CREDS}" -X POST "https://${BIGIP}/mgmt/tm/apm/policy/policy-item/" -H "Content-Type:application/json" -H "X-F5-REST-Coordination-Id:${transid}" --data ${JSON} > /dev/null 2>&1

    ## Create policy
    JSON="{\"name\":\"sslo-telemetry-${BASE}\",\"partition\":\"Common\",\"defaultEnding\":\"sslo-telemetry-${BASE}_end_allow\",\"maxMacroLoopCount\":1,\"oneshotMacro\":\"false\",\"startItem\":\"sslo-telemetry-${BASE}_ent\",\"type\":\"access-policy\",\"items\":[{\"name\":\"sslo-telemetry-${BASE}_end_allow\",\"partition\":\"Common\"},{\"name\":\"sslo-telemetry-${BASE}_ent\",\"partition\":\"Common\"}]}"
    curl -sku "${CREDS}" -X POST "https://${BIGIP}/mgmt/tm/apm/policy/access-policy/" -H "Content-Type:application/json" -H "X-F5-REST-Coordination-Id:${transid}" --data ${JSON} > /dev/null 2>&1

    ## Create profile
    JSON="{\"name\":\"sslo-telemetry-${BASE}\",\"partition\":\"Common\",\"acceptLanguages\":[\"en\"],\"accessPolicy\":\"/Common/sslo-telemetry-${BASE}\",\"customizationGroup\":\"/Common/sslo-telemetry-${BASE}_logout\",\"epsGroup\":\"/Common/sslo-telemetry-${BASE}_eps\",\"errormapGroup\":\"/Common/sslo-telemetry-${BASE}_errormap\",\"frameworkInstallationGroup\":\"/Common/sslo-telemetry-${BASE}_framework_installation\",\"generalUiGroup\":\"/Common/sslo-telemetry-${BASE}_general_ui\",\"accessPolicyTimeout\":300,\"defaultLanguage\":\"en\",\"httponlyCookie\":\"false\",\"inactivityTimeout\":900,\"logoutUriTimeout\":5,\"maxConcurrentSessions\":0,\"maxConcurrentUsers\":0,\"maxFailureDelay\":5,\"maxInProgressSessions\":128,\"maxSessionTimeout\":604800,\"minFailureDelay\":2,\"modifiedSinceLastPolicySync\":\"false\",\"persistentCookie\":\"true\",\"restrictToSingleClientIp\":\"false\",\"scope\":\"public\",\"secureCookie\":\"true\",\"type\":\"ssl-orchestrator\",\"useHttp_503OnError\":\"false\",\"userIdentityMethod\":\"http\",\"logSettings\":[\"/Common/sslo-${BASE}-log-settings\"]}"
    curl -sku "${CREDS}" -X POST "https://${BIGIP}/mgmt/tm/apm/profile/access/" -H "Content-Type:application/json" -H "X-F5-REST-Coordination-Id:${transid}" --data ${JSON} > /dev/null 2>&1

    ## Commit transaction
    JSON="{\"state\":\"VALIDATING\"}"
    curl -sku "${CREDS}" -H "Accept: application/json" -H "Content-Type: application/json" -X PUT "https://${BIGIP}/mgmt/tm/transaction/${transid}" --data ${JSON} > /dev/null 2>&1

    ## Apply policy
    JSON="{\"generationAction\":\"increment\"}"
    curl -sku "${CREDS}" -H "Accept: application/json" -H "Content-Type: application/json" -X PATCH "https://${BIGIP}/mgmt/tm/apm/profile/access/~Common~sslo-telemetry-${BASE}" --data ${JSON} > /dev/null 2>&1
else
    echo
    echo "Usage: $0 [CREDS] [BIG-IP] [SYSLOG]"
    echo
    echo "Where:"
    echo "  CREDS:  BIG-IP user:pass                ex. 'admin:admin'"
    echo "  BIG-IP: IP of target BIG-IP             ex. 10.1.1.4"
    echo "  SYSLOG: Syslog listener IP:port         ex. 10.1.10.30:1514"
    echo
    echo "Example: $0 'admin:admin' 10.1.1.4 10.1.10.30:1514"
    echo
fi