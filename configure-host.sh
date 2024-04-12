#!/bin/bash

# Function to log changes
log_changes() {
    local message="$1"
    if [ "$VERBOSE" = true ]; then
        echo "$message"
    else
        logger -t "configure-host" "$message"
    fi
}

# Function to update hostname
updateHostname() {
    local desiredName="$1"
    local currentName=$(hostname)

    # Update /etc/hostname if necessary
    if [ "$desiredName" != "$currentName" ]; then
        echo "$desiredName" > /etc/hostname
        log_changes "Hostname changed to $desiredName"
    fi

    # Update /etc/hosts if necessary
    if ! grep -q "^127.0.1.1\s*$desiredName" /etc/hosts; then
        sed -i "s/^127.0.1.1\s*$currentName/127.0.1.1 $desiredName/g" /etc/hosts
        log_changes "Updated /etc/hosts with hostname $desiredName"
    fi
}

# Function to update IP address
update_ipaddr() {
    local desiredIPAddress="$1"
    local currentIP=$(hostname -I | awk '{print $1}')

    # Update /etc/hosts if necessary
    if ! grep -q "$desiredIPAddress\s*$HOSTNAME" /etc/hosts; then
        sed -i "/$currentIP/d" /etc/hosts
        echo "$desiredIPAddress $HOSTNAME" >> /etc/hosts
        log_changes "Updated /etc/hosts with IP address $desiredIPAddress"
    fi

    # Update netplan file (assuming it's in /etc/netplan/01-netcfg.yaml)
    if [ -f "/etc/netplan/01-netcfg.yaml" ]; then
        sed -i "s/address $currentIP/address $desiredIPAddress/g" /etc/netplan/01-netcfg.yaml
        netplan apply
        log_changes "IP address changed to $desiredIPAddress"
    fi
}

# Function to add host entry
addHostEntry() {
    local desiredName="$1"
    local desiredIPAddress="$2"

    if ! grep -q "$desiredIPAddress\s*$desiredName" /etc/hosts; then
        echo "$desiredIPAddress $desiredName" >> /etc/hosts
        log_changes "Added host entry: $desiredName $desiredIPAddress"
    fi
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -verbose)
            VERBOSE=true
            shift
            ;;
        -name)
            updateHostname "$2"
            shift 2
            ;;
        -ip)
            update_ipaddr "$2"
            shift 2
            ;;
        -hostentry)
            addHostEntry "$2" "$3"
            shift 3
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done
