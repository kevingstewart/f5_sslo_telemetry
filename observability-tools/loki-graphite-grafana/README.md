# SSL Orchestrator Telemetry Project
## Tools: Loki :: Graphite :: Grafana

Please refer to official Loki documentation at: https://grafana.com/oss/loki/. Loki is a "*horizontally-scalable, highly-available. multi-tenant log aggregation system inspered by Prometheus*". In this case, as the important data coming from SSL Orchestrator is made available in log messages, Loki is a perfect tool for aggregating that information into usable metrics and searchable context. 

Please refer to official Graphite documentation at: https://graphiteapp.org/. Where Loki collects log information, some useful **system** data is better to collect from BIG-IP statistics. Coupled with F5 Telemetry Streaming (https://clouddocs.f5.com/products/extensions/f5-telemetry-streaming/latest/), Graphite is used here to collect iControl stats data directly.

Please refer to official Grafana documentation at: https://grafana.com/. Grafana is a free and open source (FOSS) dashboard for a large ecosystem of data providers, collectors and aggregators. In this case, Loki collects log information and converts to metrics, Graphite collects stats, and both source the visibility panels in the Grafana dashboard. 

All together, the following instructions define a minimum configuration for presenting multi-system SSL Orchestrator health and availability.

Example:
<img src="../../images/grafana_telemetry_page_20210924a.png" width="300">


### Description
Text