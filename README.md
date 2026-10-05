# Wazuh-SIEM-Automated-Threat-Detection-and-Active-Response
# Wazuh SIEM & XDR: Automated Threat Detection & Zero-Touch Remediation

Most people talk about SIEM architecture; this repository documents the process of actually building it. This project features a complete Wazuh SIEM and XDR security lab deployed entirely from the ground up—no pre-configured environments, no shortcuts. Just raw infrastructure, production-grade tools, and extensive system troubleshooting.

The primary objective was to build a production-relevant security monitoring environment capable of ingesting live network traffic, identifying threats in real-time, and executing automated malware remediation without human intervention.

## Core Objectives
*   **Real-Time Threat Detection:** Ingest and analyze live endpoint and network telemetry to identify malicious activity instantly.
*   **Automated Incident Response:** Engineer an active response pipeline that detects, verifies, and deletes malware automatically.
*   **Live Network Monitoring:** Deploy and tune a dedicated Intrusion Detection System (IDS) to inspect network traffic for intrusion attempts.

## Technology Stack
*   **Wazuh 4.14.3:** Core SIEM & XDR platform (Indexer, Manager, Dashboard).
*   **Kali Linux:** Host environment for the Wazuh Server infrastructure.
*   **Ubuntu 25.10:** Monitored endpoint and active detonation environment.
*   **Suricata IDS:** Network intrusion detection engine utilizing Emerging Threats signatures.
*   **VirusTotal API:** Cloud threat intelligence integration for automated hash verification.
*   **jq:** Lightweight JSON parser utilized for custom active response shell scripting.

## Architecture & Data Flow
This deployment relies on a highly integrated data pipeline to achieve zero-touch remediation:

1.  **Traffic Inspection:** Suricata monitors live network traffic on the Ubuntu endpoint, matching packets against the Emerging Threats ruleset and writing alerts to `eve.json`.
2.  **Log Forwarding:** The Wazuh Agent reads the Suricata log file and securely forwards the event telemetry to the Wazuh Server hosted on Kali Linux.
3.  **Threat Correlation & Verification:** The Wazuh Server processes the events. Upon matching specific high-severity detection rules, the manager automatically extracts file hashes and submits them to the VirusTotal API.
4.  **Automated Trigger:** If VirusTotal returns a positive malware verdict, Wazuh immediately triggers a custom active response.
5.  **Execution & Remediation:** The custom `remove-threat.sh` script executes on the Ubuntu endpoint, parsing the JSON alert payload with `jq` and permanently deleting the malicious file. All alerts, verdicts, and remediation actions are simultaneously indexed and visualized on the Wazuh Dashboard.

## Operational Challenges & Resolutions
Every real deployment comes with real problems. Engineering this pipeline required significant troubleshooting and system administration:

*   **Firewall State Mismatches (UFW vs. iptables):** Despite UFW showing the necessary ports as open, `iptables` was silently dropping traffic underneath. *Resolution:* Bypassed surface-level firewall listings and verified actual TCP/UDP connectivity using `nc -zv` to identify and flush the conflicting rules.
*   **Suricata Signature Parser Failures:** During initialization, Suricata suffered a full startup failure. The wildcard `.rules` configuration was attempting to load unsupported industrial control system (ICS) protocol signatures (Modbus, DNP3, ENIP). *Resolution:* Manually identified and stripped the incompatible SCADA rule files from the Emerging Threats dataset to allow a successful startup.
*   **XML Configuration Ordering Errors:** The Wazuh Manager failed silently on startup due to strict parsing requirements in the `ossec.conf` file. *Resolution:* Discovered that the `<command>` block must strictly precede the `<active-response>` block. Corrected the XML hierarchy to restore manager functionality.
*   **Systemd State Synchronization:** After modifying the Wazuh Agent service files to grant necessary permissions for active response, the service refused to apply the updates. *Resolution:* Identified that systemd was caching an outdated service configuration. Executed `systemctl daemon-reload` to synchronize the state before restarting the daemon.

## Business Impact
This deployment demonstrates the exact capabilities a modern Security Operations Center (SOC) relies on to reduce Mean Time to Respond (MTTR). By integrating automated threat intelligence with endpoint execution capabilities, the architecture shifts the operational burden from manual analyst triage to machine-speed remediation, drastically minimizing enterprise risk exposure.
