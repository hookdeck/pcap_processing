#!/bin/bash

tshark -r pcaps/example001/proxy2/tshark_00125_20230909175840.pcap -Y "tcp.stream eq 5961 or tcp.stream eq 5962" | sed 's/\s\+/ /g' | awk '{printf $3 "->" $5 ":"; for (i=8; i<=NF; i++) printf $i " "; print ""}'
