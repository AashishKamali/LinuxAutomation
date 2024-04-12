  GNU nano 6.2                                                   lab3.sh                                                            
#!/bin/bash

# Function to display verbose output
verbose_output() {
    local message="$1"
    if [ "$VERBOSE" = true ]; then
        echo "$message"
    fi
}

# Function to transfer configure-host.sh script and execute it on the server
deploy_configure_script() {
    local server="$1"
    verbose_output "Transferring configure-host.sh script to $server..."
    scp configure-host.sh remoteadmin@"$server":/root

    verbose_output "Executing configure-host.sh script on $server..."
    ssh remoteadmin@"$server" -- /root/configure-host.sh "$@"
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Deploy and run configure-host.sh script on server1
deploy_configure_script "server1-mgmt" -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4
