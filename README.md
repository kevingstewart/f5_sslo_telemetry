# F5 SSL Orchestrator Telemetry Project
## _PREVIEW - Still in testing_

This project extends F5 SSL Orchestrator telemetry (metric visibility) into third party observability tools. 

## Description
The bulk of SSLO's critical telemetry information passes through flow-summary and SSL logs which can be challenging to parse and use in troubleshooting efforts, and are otherwise only visibile directly on the BIG-IP (or BIG-IQ). The tools presented here serve to collect and aggregate the important log data into useful metrics and searchable data elements in third party observability tools.

F5 Telemetry Streaming alone is generally insufficient here, as SSL Orchestrator's information isn't available as readily-accessible numerical metric data. And so the set of tools prescribed are limited to those that can collect Syslog traffic and aggregate into useful data. While there are many options to choose from, this project focuses on a key set of tool combinations (log collectors -> aggregators -> dashboards) as templates for any other tools you may need to use. The combinations presented here are:

- **Loki :: Graphite :: Grafana** - Loki (along with Promtail) performs the collection and aggregation of Syslog-NG messages from the BIG-IP. Graphite (with Statsd and F5 Telemetry Streaming) collects pure system performance metric information. And Grafana presents all of this information in a highly customizable dashboard.


- **Logstash :: Elasticsearch :: Kibana** (ELK) - Logstash collects BIG-IP Syslog-NG messages for aggregation in Elasticsearch. Kibana presents this information in a highly customizable dashboard.


- **Splunk** - This all-in-one commercial tool performs all of the operations - log collection, aggregation and visibility.



## Requirements
The following software packages are required:

- F5 Telemetry Streaming >= 1.22

## Installation
Text
