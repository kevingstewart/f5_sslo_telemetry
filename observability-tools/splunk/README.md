# SSL Orchestrator Telemetry Project
## Tools: Splunk

This guide specifically addresses SSL Orchestrator **forensic** logging - the per-flow records an admin can use to diagnose user traffic issues (date-time, src, dst, proto, tls, policy, services, errors, etc.).

### Splunk Installation

1. **Create a new index**<br />

    - Settings -> Indexes [Create New Index]
    - Index Name: sslo
    - Index Data Type: Events
    
      ***Note: You can also do this REST. If you're deploying Splunk as a container using the free license, you'll need to exec into the container's Bash shell***
    
      ```
      docker exec -it splunk-container /bin/bash
      curl -ku 'admin:P@ssword!' https://localhost:8089/servicesNS/admin/search/data/indexes -d name=sslo
      ```

2. **Configure an HTTP Event Collector**<br />

    - Settings -> Data Inputs -> HTTP Event Collector [Generate New Token]
    - Name: provide a name (ex. hec)
    - Input Settings: Source Type: Syslog
    - Input Settings: Index: sslo
    
      ***Note: You can also do this REST. If you're deploying Splunk as a container using the free license, you'll need to exec into the container's Bash shell***
    
      ```
      docker exec -it splunk-container /bin/bash
      curl -ku 'admin:P@ssword!' https://localhost:8089/servicesNS/admin/search/data/inputs/http -d 'name=sslo_hec' -d 'sourcetype=syslog' -d 'index=sslo'
      ```
      
      ***The output from the HTTP Event Collector will include a TOKEN Value. Copy this for later.***

______________________

### F5 Telemetry Streaming Installation

1. **Install Telemetry Streaming**<br />
   This will install the latest TS package from the F5 repository. Run the "f5-install-ts.sh" script and provide the BIG-IP admin credentials and IP address:
   
   ```
   chmod +x f5-install-ts.sh
   ./f5-install-ts.sh 'admin:admin' 10.1.1.4
   ```
   
2. **Modify the Telemetry Config JSON file**<br />
   Edit the **config-f5-ts.json** and replace the following two values:
   
    - SPLUNK_LISTENER_IP: the IP address of the Splunk listener
    - SPLUNK_TOKEN: the TOKEN generated from the Splunk HTTP Event Collector creation

   ***Note: if Splunk is running as a container, also change the "port" value to the host-side port specified in the docker config. The native Plunk listener port is typically 8088.***
   
3. **POST the Telemetry Streaming Config File to the BIG-IP**<br />
   This will push the JSON configuration to the running Telemetry Streaming process on the BIG-IP. Run the "f5-install-ts-config.sh" script and provide the BIG-IP admin credentials and IP address:
   
   ```
   chmod +x f5-install-ts-config.sh
   ./f5-install-ts-config.sh 'admin:admin' 10.1.1.4
   ```

______________________

### F5 Telemetry Streaming Configuration

1. **Create the Telemetry Streaming Log Configuration on the BIG-IP**<br />
   This will install all of the components necessary to facilitate logging to Splunk. Run the "f5-install-splunk-config.sh" script and provide the BIG-IP admin credentials and IP address:

   ```
   chmod +x f5-install-splunk-config.sh
   ./f5-install-splunk-config.sh 'admin:admin' 10.1.1.4
   ```
   
   ***Note: this will create the Telemetry Streaming pool, iRule, virtual server, remote high-speed logging destination, splunk logging destination, log publisher, and an access policy log setting that consumes this publisher.***

2. **Create an SSL Orchestrator Access Policy**<br />
   This will be used in place of the autp-generated policy to enable persistent log settings across topology deployments.
   
    - In the BIG-IP UI, UI: Access -> Profiles/Policies -> Access Profiles (Per-Session Policies) [Create]
    - Name: sslo-splunk-access-profile
    - Profile Type: SSL Orchestrator
    - Profile Scope: Public
    - Customization Type: Standard
    - Languages: (choose languages)

3. **Assign the Log Configuration to the Access Policy**<br />
   This will attach the access log configuration to the above policy.
   
    - In the BIG-IP UI: Access -> Overview -> Event Logs -> Settings [Edit Splunk log settings]
    - Access Profiles: select the sslo-splunk-access-profile

______________________

### F5 SSL Orchestrator Configuration

1. **Configure a topology**<br />
   On the Interception Rules page, modify the Access Profile and select sslo-splunk-access-profile.

   ***Note: If creating an explicit proxy topology, take the defaults and deploy. After deploying, edit the topology's "in-t" Interception Rule. modify the Access Profile and select sslo-splunk-access-profile.***

______________________

### Searching Splunk

Your SSL Orchestrator topology should now be pushing summary log data to Splunk. To search on this data, change the search index to "sslo".

  - In the Splunk UI: Apps -> Search & Reporting
  - Search: ```index=sslo```
  - Search on specific records(src and dst): ```index=sslo AND Connflow="*10.1.10.50*" AND Connflow="*93.184.216.34:443*"```
  - Delete all records: ```index=sslo | delete```


