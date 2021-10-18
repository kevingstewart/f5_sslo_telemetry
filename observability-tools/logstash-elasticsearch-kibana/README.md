# SSL Orchestrator Telemetry Project
## Tools: Elasticsearch :: Logstash :: Kibana

Please refer to official Elk Stack documentation at: https://www.elastic.co/guide/index.html. Elasticsearch provides a search and analytics engine used for full-text search and for analyzing logs and metrics. Logstash provides an open-source tool that ingests and transforms logs and events. And Kibana adds visualization and exploration tools for reviewing logs and events. 

All together, the following instructions define a minimum configuration for presenting multi-system SSL Orchestrator health and availability.

Example:

[IMAGE STUB]


### Installation
While not expressly required, the steps to building an Elk Stack in Docker containers is shown below. This is an easy way to get an observability system up and runninq quickly. The entire set of tools can also be created from a single docker-compose file (included here). For this observability server, you'll minimally need a Linux platform with Docker installed (and optionally Docker-Compose).<br />
[IMAGE STUB]<br />
Naturally in a production system these components can be spread across multiple machines, however the details of that architecture are beyond the scope of this project. Please consult official product documentation as required. The below is for demonstration purposes only and relies on a single *observability* server to provide all log/stat collection, log aggregation, and dashboard tools - running in Docker containers.

1. **Create an observability server**<br />
For the set of Docker-based services described below, any generic Linux distro will suffice as long as Docker and Docker-Compose can be installed. As described, this server will run all of the observability services (ie. Elasticsearch, Logstash, and Kibana), though it is perfectly reasonable to run these as dedicated (non-containerized) services on dedicated systems.

    ***Note**: As the BIG-IP will be pushing logs through a high-speed log publisher, the observability services should be accessible to the BIG-IP via data plane interface.*

2. **Clone this Github repository**<br />
Clone this repository to your observability server.
    ```
    mkdir build
    cd build
    git clone https://github.com/kevingstewart/f5_sslo_telemetry.git
    cd f5_sslo_telemetry/observability-tools/logstash-elasticsearch-kibana/
    ```

3. **Install the services via Docker-Compose**<br />
The compose file is configured to read the Logstash configuration file from the current directory. To start all of the services:
    ```
    docker-compose up -d
    ```

4. **Install and configure F5 Telemetry Streaming** (stats publisher)<br />
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

5. **Install and configure an F5 log publisher** (log publisher)<br />
Elasticsearch aggregates logs collected from Logstash. To get those logs to Logstash, the BIG-IP must be configured with a log publisher that attaches to the SSL Orchestrator security policy. Use the included **install-f5-logpub.sh** script to create all of the requires logging objects on the target BIG-IP. Run the script, providing the BIG-IP credentials, IP of the BIG-IP, and observability server's Syslog listener IP:port as arguments. Example:
    ```
    chmod +x install-f5-logpub.sh
    ./install-f5-logpub.sh 'admin:admin' 10.1.1.4 10.1.10.30:1514
    ```
        
    The script creates all of the required objects to push SSLO summary logs to an external Syslog. This includes the Syslog pool, log filter/destination/publisher, and a new SSLO-type per-session profile that attaches this log publisher. The SSLO workflow has no consistent way to attach a new log publisher to the SSLO profile. The script therefore creates a new SSLO-type per-session profile that can be used in topology workflows. This new profile is functionally identical to the non-editable per-session profile created in the workflow, except that it defines the new log publisher.

    - In an L2 or L3 outbound SSLO topology workflow, on the Interception Rules page, under "Access Profile", select the new SSLO logging profile.
    - In an L3 explicit proxy SSLO topology workflow, complete and deploy the topology, then edit the corresponding "-in-t" object on the Interception Rules page. Under "Access Profile", select the new SSLO logging profile.
    - In L2 or L3 inbound SSLO topology workflow, on the Interception Rules page, under "Access Profile", select the new SSLO logging profile.

6. **Import the Kibana stack configuration**<br />
Once all observability services are up and running, you can access the Kibana dashboard at http://server-ip:5601 (where "server-ip" is the IP address of this server).
    <br />
    - Navigate to "Stack Management" :: "Saved Objects", click Import, and import config-kibana.ndjson.
    <br />

7. **Generate SSL Orchestrator Traffic**<br />
Generate traffic and observe summary log and metric information pouring into the Kibana dashboard.

