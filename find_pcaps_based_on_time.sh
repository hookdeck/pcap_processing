#!/bin/bash

# Thank you Chat GPT for writing 99% of this code! 

# Default values
pcaps_dir="/mnt/tshark"

# Function to display help/usage
display_help() {
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   --start      Start time in the format 'YYYY-MM-DD HH:MM:SS'"
    echo "   --end        End time in the format 'YYYY-MM-DD HH:MM:SS'"
    echo "   --pcaps_dir  Directory to search for pcaps (default: /mnt/tshark)"
    echo "   --help       Display this help and exit"
    echo
    exit 1
}

# Parse command line arguments for named variables
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --start) start_time_arg="$2"; shift ;;
        --end) end_time_arg="$2"; shift ;;
        --pcaps_dir) pcaps_dir="$2"; shift ;;
        --help) display_help; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; display_help; exit 1 ;;
    esac
    shift
done

# Check if both start and end times are provided
if [[ -z "$start_time_arg" || -z "$end_time_arg" ]]; then
    echo "Both --start and --end options are required."
    display_help
    exit 1
fi
# Define the start and end times in seconds since the Unix epoch

start_time=$(date -d "$start_time_arg" "+%s")
end_time=$(date -d "$end_time_arg" "+%s")

# Use find to get all pcap files and then filter them based on the timestamp
find "$pcaps_dir" -name "tshark_*.pcap" | sort | awk -F'_' -v start="$start_time" -v end="$end_time" '
{
    # Extract the timestamp from the filename
    timestamp = substr($3, 1, 14);
    year = substr(timestamp, 1, 4);
    month = substr(timestamp, 5, 2);
    day = substr(timestamp, 7, 2);
    hour = substr(timestamp, 9, 2);
    minute = substr(timestamp, 11, 2);
    second = substr(timestamp, 13, 2);
    datetime = year "-" month "-" day " " hour ":" minute ":" second;

    # Convert the timestamp to seconds since the Unix epoch
    cmd = "date -d \"" datetime "\" +%s";
    cmd | getline ts;
    close(cmd);

    if (NR > 1 && (prev_ts <= end && ts >= start)) {
        print prev_file;
    }

    prev_ts = ts;
    prev_file = $0;
}
END {
# Handle the last pcap separately (assuming it lasts for 1 minute)
    if (prev_ts <= end && (prev_ts + 59) >= start) {
        print prev_file;
    }
}' 

