#!/bin/bash

pcap=""

# Function to print usage
display_help() {
  echo
  echo "Usage: $0 <pcap>"
  echo
  echo "   --help    Display this help and exit"
  echo "   pcap      The pcap containing the traffic we are to extract and analyze"
  echo
  exit 1
}

# Parse the command line arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    *) 
      if [[ -z "$pcap" ]]; then
        pcap="$1"
      else
        echo "Unknown parameter passed: $1"; display_help; exit 1
      fi
      ;;
  esac
  shift
done

if [[ -z "$pcap" ]]; then
  echo "Error: you must specify the pcap file to read from"
  display_help
  exit 1
fi


TZ=UTC tshark -r $pcap -Y "tls.handshake" -T fields -e frame.time -e ip.src -e tcp.srcport -e ip.dst -e tcp.dstport -e tcp.stream -e tls.handshake.session_id | awk 'BEGIN {FS=OFS="\t"} {if ($7 != "") print}'
