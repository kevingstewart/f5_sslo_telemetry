# SSL Orchestrator Telemetry Project
## Tools: Loki :: Graphite :: Grafana

Please refer to official Loki documentation at: https://grafana.com/oss/loki/. Loki is a "*horizontally-scalable, highly-available. multi-tenant log aggregation system inspered by Prometheus*". In this case, as the important data coming from SSL Orchestrator is made available in log messages, Loki is a perfect tool for aggregating that information into usable metrics and searchable context. Loki will rely on a separate utility, Promtail, as its collector.

Please refer to official Graphite documentation at: https://graphiteapp.org/. Where Loki collects log information, some useful **system** data is better to collect from BIG-IP statistics. Coupled with F5 Telemetry Streaming (https://clouddocs.f5.com/products/extensions/f5-telemetry-streaming/latest/), Graphite is used here to collect iControl stats data directly.

Please refer to official Grafana documentation at: https://grafana.com/. Grafana is a free and open source (FOSS) dashboard for a large ecosystem of data providers, collectors and aggregators. In this case, Loki collects log information and converts to metrics, Graphite collects stats, and both source the visibility panels in the Grafana dashboard. 

All together, the following instructions define a minimum configuration for presenting multi-system SSL Orchestrator health and availability.

Example:

<img src="../../images/loki-graphite-grafana-sample.png" width="300">


### Installation
While not expressly required, the steps to building Loki, Promtail, Graphite, and Grafana in Docker containers is shown below. This is an easy way to get an observability system up and runninq quickly. The entire set of tools can also be created from a single docker-compose file (included here). For this observability server, you'll minimally need a Linux platform with Docker installed (and optionally Docker-Compose).<br />
<img src="../../images/loki-graphite-grafana-layout.png" width="500"><br />
Naturally in a production system these components can be spread across multiple machines, however the details of that architecture are beyond the scope of this project. Please consult official product documentation as required. The below is for demonstration purposes only and relies on a single *observability* server to provide all log/stat collection, log aggregation, and dashboard tools - running in Docker containers.

1. **Create an observability server**<br />
For the set of Docker-based services described below, any generic Linux distro will suffice as long as Docker and Docker-Compose can be installed. As described, this server will run all of the observability services (ie. Loki, Promtail, Graphite, and Grafana), though it is perfectly reasonable to run these as dedicated (non-containerized) services on dedicated systems.

    ***Note**: As the BIG-IP will be pushing logs through a high-speed log publisher, the observability services should be accessible to the BIG-IP via data plane interface.*

2. **Clone this Github repository**<br />
Clone this repository to your observability server.
    ```
    mkdir build
    cd build
    git clone https://github.com/kevingstewart/f5_sslo_telemetry.git
    cd f5_sslo_telemetry/observability-tools/loki-graphite-grafana/
    ```

3. **Edit the config-promtail.yaml file**<br />
Edit the file to point the client's url (line 9) to the local server IP so that Promtail can access Loki. Promtail will establish a remote Syslog listener on this IP, and TCP port 1514. Ensure that this IP address will be accessible to the BIG-IP over a data plane interface.

4. **Install the services via Docker-Compose**<br />
The compose file is configured to read the Loki/Promtail configurations from the current directory. To start all of the services:
    ```
    docker-compose up -d
    ```

        Optional: Create all of the containers individually:

        A. Install Loki** (log aggregator)
            docker run -d --name loki --restart unless-stopped -v $(pwd):/mnt/config -p 3100:3100 grafana/loki:2.3.0 -config.file=/mnt/config/loki-config.yaml
        
        B. Install and configure Promtail (log collector)
            !! Edit config-promtail.yaml file (included here) to point the client's url (line 9) to the local server IP so that Promtail can access Loki. Promtail will establish a remote Syslog listener on this IP, and TCP port 1514.
            docker run -d --name promtail --restart unless-stopped -p 1514:1514 -v $(pwd):/mnt/config -v /var/log:/var/log grafana/promtail:2.3.0 -config.file=/mnt/config/config-promtail.yaml

        C. Install Graphite (stats collector)
            docker run -d --name graphite --restart unless-stopped -p 88:80 -p 2003-2004:2003-2004 -p 2023-2024:2023-2024 -p 8125:8125/udp -p 8126:8126 graphiteapp/graphite-statsd

        D. Install and configure Grafana (dashboard)
            docker run -d --name grafana --restart unless-stopped -p 3000:3000 grafana/grafana

1. **Install and configure F5 Telemetry Streaming** (stats publisher)<br />
Use the included **install-f5-ts.sh** Bash script to remotely install the latest F5 Telemetry Streaming package. This will download the latest RPM from the Github repository, upload the RPM to the BIG-IP, and then initiate package installation. Run the script, providing the BIG-IP credentials and IP of the BIG-IP as arguments. Example:
    ```
    chmod +x install-f5-ts.sh
    ./install-f5-ts.sh 'admin:admin' 10.1.1.4
    ```

    Use the included **install-ts-config.sh** Bash script to push the required Telemetry Streaming configuration to the BIG-IP. Run the script, providing the BIG-IP credentials, IP of the BIG-IP, and the IP of the observability server as arguments. Example:
    ```
    chmod +x install-ts-config.sh
    ./install-ts-config.sh 'admin:admin' 10.1.1.4 10.1.10.30
    ```

6. **Install and configure an F5 log publisher** (log publisher)<br />
Loki aggregates logs collected from the Promtail syslog service. To get those logs to Promtail, the BIG-IP must be configured with a log publisher that attaches to the SSL Orchestrator security policy. Use the included **install-f5-logpub.sh** script to create all of the requires logging objects on the target BIG-IP. Run the script, providing the BIG-IP credentials, IP of the BIG-IP, and observability server's Syslog listener IP:port as arguments. Example:
    ```
    chmod +x install-f5-logpub.sh
    ./install-f5-logpub.sh 'admin:admin' 10.1.1.4 10.1.10.30:1514
    ```
        
    The script creates all of the required objects to push SSLO summary logs to an external Syslog. This includes the Syslog pool, log filter/destination/publisher, and a new SSLO-type per-session profile that attaches this log publisher. The SSLO workflow has no consistent way to attach a new log publisher to the SSLO profile. The script therefore creates a new SSLO-type per-session profile that can be used in topology workflows. 

    - In an L2 or L3 outbound SSLO topology workflow, on the Interception Rules page, under "Access Profile", select the new SSLO logging profile.
    - In an L3 explicit proxy SSLO topology workflow, complete and deploy the topology, then edit the corresponding "-in-t" object on the Interception Rules page. Under "Access Profile", select the new SSLO logging profile.
    - In L2 or L3 inbound SSLO topology workflow, on the Interception Rules page, under "Access Profile", select the new SSLO logging profile.
    <br />

1. **Import the Grafana configuration**<br />
Once all observability services are up and running, you can access the Grafana dashboard at http://server-ip:3000 (where "server-ip" is the IP address of this server). Initial login is 'admin:admin'.
    <br />
    - Navigate to Configuration :: Data sources. Click the "Add data sources" button. Select **Graphite**. In the URL field, enter "http://[observability-server-ip]:88", where observability-server-ip is the IP address of this server (ex. http://10.1.10.30:88). Click the "Save & test" button to complete the data source import.
    <br />

    - Navigate to Configuration :: Data sources. Click the "Add data sources" button. Select **Loki**. In the URL field, enter "http://[observability-server-ip]:3100", where observability-server-ip is the IP address of this server (ex. http://10.1.10.30:3100). Click the "Save & test" button to complete the data source import.
    <br />

    - Navigate to Dashboards :: Manage. Click the Import button, and then copy the contents of the included config-grafana.json file into the window. Click Import again to complete the import process.

8. **Generate SSL Orchestrator Traffic**<br />
Generate traffic and observe summary log and metric information pouring into the Grafana dashboard.

9. **Exploration**<br />
One of the most useful functions of this Loki/Grafana integration is the powerful way in which the logs can be explored. This is especially powerful in troubleshooting user connectivity issues. Please review the sample dashboard above. While the bulk of the page is dedicated to aggregated stats/metrics, the bottom panel includes a log viewer. Click on the "Summary Log" title and click **Explore** from the fly-out menu.<br /><br />
<img src="../../images/loki-graphite-grafana-sample-1.png" width="800"><br /><br />
You can then manually update the log query in the "Log browser" field to filter the displayed logs. Or, click on the "**>**" icon next to a log line to expand its contents. Within that you'll see the individual labelled elements. To include one of these labels in the search, click the "plus-magnifying-glass" icon next to a label. This will add the label to the query and reduce the set of logs down to those that match this criteria. You could, for example, filter the logs down to all matching a specific source_ip label, or any combinations of label matches. 