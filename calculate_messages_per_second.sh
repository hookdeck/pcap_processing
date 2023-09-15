#!/bin/bash

use_dns=0
use_tcp=0
output_file=""
title="Messages/second"
pcap=""

# The pcap filter is only needed if we are to filter out only tcp or dns etc.
# Ohterwise we'll process the entire file.
pcap_filter=""

# Function to print usage
display_help() {
  echo "Usage: $0 [--dns | --tcp] [--output <file>] [--title <title>] <pcap>"
  echo
  echo "   --dns     Flag indicating if we should just count DNS messages"
  echo "   --tcp     Flag indicating if we should just count TCP messages"
  echo "   --output  The name of the SVG image that will be produced showing the messages/second."
  echo "   --title   The title of the resulting SVG image"
  echo "   --help    Display this help and exit"
  echo
  echo "   pcap      The pcap containing the traffic we are to extract and analyze"
  echo
  exit 1
}

# Parse the command line arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --dns)
      use_dns=1
      ;;
    --tcp)
      use_tcp=1
      ;;
    --output)
      shift
      if [[ -z "$1" ]]; then
        echo "Error: --output expects a filename."
        exit 1
      fi
      output_file="$1"
      ;;
    --title)
      shift
      if [[ -z "$1" ]]; then
        echo "Error: --title expects a string."
        exit 1
      fi
      title="$1"
      ;;
    --help) display_help; exit 0 ;;
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
  exit 1
fi

if [[ "$use_dns" -eq 1 ]] && [[ "$use_tcp" -eq 1 ]]; then
  echo "Error: --dns and --tcp are mutually exclusive."
  exit 1
fi


filename=$(basename $pcap)
directory=$(dirname $pcap)
if [[ $filename == *.pcap ]]; then
  filename=`echo $filename | cut -d '.' -f 1`
fi
csv_file=$directory/$filename

if [[ "$use_dns" -eq 1 ]]; then
  pcap_filter="-Y dns"
  csv_file=$csv_file.dns.csv
elif [[ "$use_tcp" -eq 1 ]]; then
  pcap_filter="-Y tcp"
  csv_file=$csv_file.tcp.csv
else
  csv_file=$csv_file.csv
fi

if [[ -z "$output_file" ]]; then
  output_file=$directory/$filename.svg
fi

echo "Title                : $title"
echo "Input pcap           : $pcap"
echo "CSV data file        : $csv_file"
echo "Image file (SVG)     : $output_file"
echo "Tshark filter pattern: $pcap_filter"

# not sure why i couldn't just pass the empty filter
# but for some reason, tshark then complained about the
# -t ud option so i got annoyed and this at least works.
# moving on.
if [[ -z "$pcap_filter" ]]; then
  TZ=UTC tshark -r "$pcap" -t ud -T fields -e _ws.col.Time | cut -d '.' -f 1 | uniq -c | awk '{$1=$1; print substr($0, length($1)+2)","$1}' > "$csv_file"
else
  TZ=UTC tshark -r "$pcap" "$pcap_filter" -t ud -T fields -e _ws.col.Time | cut -d '.' -f 1 | uniq -c | awk '{$1=$1; print substr($0, length($1)+2)","$1}' > "$csv_file"
fi

gnuplot -e "set datafile separator ','; set terminal svg enhanced size 1600,900 background rgb 'white'; set output '$output_file'; set xdata time; set timefmt '%Y-%m-%d %H:%M:%S'; set format x '%H:%M'; plot '$csv_file' using 1:2 with linespoints title '$title'"

