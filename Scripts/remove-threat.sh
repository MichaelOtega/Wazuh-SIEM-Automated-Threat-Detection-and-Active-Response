#!/bin/bash
# ==============================================================================
# Script: remove-threat.sh
# Purpose: Wazuh Active Response script to automatically delete malicious files 
#          flagged by VirusTotal integration.
# Dependencies: jq (JSON processor)
# ==============================================================================

# Wazuh 4.x passes the alert payload to Active Response scripts via STDIN
read -r INPUT_JSON

# Log file for active response actions
LOG_FILE="/var/ossec/logs/active-responses.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 1. Parse the JSON payload using jq to extract the file path
# The VirusTotal integration nests the original file path under the 'source' object
FILE_PATH=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.data.virustotal.source.file')

# Fallback: Check standard FIM path if VT source path is missing
if [ "$FILE_PATH" == "null" ] || [ -z "$FILE_PATH" ]; then
    FILE_PATH=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.syscheck.path')
fi

# 2. Validation and Execution
if [ -n "$FILE_PATH" ] && [ "$FILE_PATH" != "null" ]; then
    if [ -f "$FILE_PATH" ]; then
        # Execute zero-touch removal
        rm -f "$FILE_PATH"
        echo "$TIMESTAMP active-response/bin/remove-threat.sh: SUCCESS - Removed malicious file at $FILE_PATH" >> "$LOG_FILE"
    else
        echo "$TIMESTAMP active-response/bin/remove-threat.sh: WARNING - File $FILE_PATH not found (possibly already deleted)" >> "$LOG_FILE"
    fi
else
    echo "$TIMESTAMP active-response/bin/remove-threat.sh: ERROR - Could not parse file path from JSON payload" >> "$LOG_FILE"
fi
