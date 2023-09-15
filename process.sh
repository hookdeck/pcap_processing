# -------------------------------------
# In the pre-process of the pcap we write out one liners about
# SSL Session IDs, their TCP Stream IDs and some other information.
# We use this information to find, based on an initial single stream id,
# the SSL Session ID. This function takes that "streams" text file
# from the pre-processing step and extracts out the single Session ID.

# Arguments:
#   - $1: A CRLF delimited string where each line contains a single TCP Stream ID (a wireshark thing)
#   - $2: The file containing all the SSL Session IDs from the pre-processed pcap. 
# Returns:
#   - The pcap filter needed to filter out the stream(s).
# -------------------------------------
find_ssl_session_id() {
  local key="$1"
  local IFS=$'\n' 

  for line in $2; do
    local stream_id=`echo $line | cut -d ' ' -f 10`
    local ssl_session_id=`echo $line | cut -d ' ' -f 11`

    if [[ "$stream_id" == "$key" ]]; then
      echo "$ssl_session_id"
      return 0
    fi
  done

  echo
  return 1
}

# -------------------------------------
# Build the pcap filter that is needed
# to filter out the "TCP Streams" for a
# given customer interaction.

# Arguments:
#   - $1: A CRLF delimited string where each line contains a single TCP Stream ID (a wireshark thing)
# Returns:
#   - The pcap filter needed to filter out the stream(s).
# -------------------------------------
build_pcap_filter() {
  local ids="$1"
  local IFS=$'\n' 

  local first_iteration=true

  local pcap_filter=""
  for stream_id in $ids; do
    if $first_iteration; then
      first_iteration=false
    else
      pcap_filter+=" or "
    fi
    pcap_filter+="tcp.stream eq $stream_id"
  done

  echo "$pcap_filter"
  return 0
}

# -------------------------------------
# Filter out the customer interaction based on
# the given filter. The result is stored in a new
# pcap, which is named after the event id.

# Arguments:
#   - $1: The pcap filter string
#   - $2: The event id
#   - $3: The pcap to filter out the traffic from.
#   - $4: The directory where to store the resulting pcap.
# Returns:
#   - The name of the new pcap file
# -------------------------------------
filter_pcap() {
  local filter="$1"
  local event_id="$2"
  local pcap="$3"
  local path="$4"
  local new_pcap=$path"/"$event_id.pcap

  tshark -r $pcap -Y "$filter" -w "$new_pcap"
  echo "$new_pcap"
  return 0
}


display_help() {
  echo "Usage: $0 [option...] <event_id>" >&2
  echo
  echo "   --http_connect   The CSV (space separated) file containing the HTTP CONNECT information'"
  echo "   --streams        The CSV (space separated) file containing the TCP streams and TSL Session ID information'"
  echo "   --pcap           The pcap containing the traffic we are to extract and analyze"
  echo "   --result_dir     The directory where all the results of the processing will be stored. Default is the same path as the pcap."
  echo "   --help           Display this help and exit"
  echo
  echo "   event_id         The event id to search for"
  echo
  exit 1
}

# Parse command line arguments for named variables
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --http_connect) http_connect_arg="$2"; shift ;;
    --streams) streams_arg="$2"; shift ;;
    --pcap) pcap_arg="$2"; shift ;;
    --result_dir) result_dir_arg="$2"; shift ;;
    --help) display_help; exit 0 ;;
    *) 
      if [[ -z "$event_id_arg" ]]; then
        event_id_arg="$1"
      else
        echo "Unknown parameter passed: $1"; display_help; exit 1
      fi
      ;;
  esac
  shift
done

# Check if both start and end times are provided
if [[ -z "$http_connect_arg" || -z "$streams_arg" || -z "$pcap_arg" || -z "$event_id_arg" ]]; then
  echo 
  echo "[ERROR] --http_connect, --streams, --pcap options and the positional argument are required."
  echo 
  display_help
  exit 1
fi

if [[ -z "$result_dir_arg"  ]]; then
  result_dir_arg=$(dirname "$pcap_arg")
fi


event_info=`grep $event_id_arg $http_connect_arg | sed 's/\s\+/ /g'`
if [[ -z "$event_info" ]]; then
  echo "[ERROR] Unknown Event ID '$event_id_arg'. No such Event ID found in file '$http_connect_arg'"
  exit 1
fi

echo "" 
echo "$event_info"
CONNECT_STREAM_ID=`echo $event_info | cut -d ' ' -f 10`
echo $CONNECT_STREAM_ID


echo 
# TODO: instead of sed:ing all over, let's have the pre-process ensure single white space...
# TODO: merge the "MAYBE" part into tthhe find_ssl_session_id instead.
MAYBE=`grep "$CONNECT_STREAM_ID" "$streams_arg" | sed 's/\s\+/ /g'`
ssl_session_id=$(find_ssl_session_id "$CONNECT_STREAM_ID" "$MAYBE")
echo "SSL Session ID: $ssl_session_id"

sessions=`grep "$ssl_session_id" "$streams_arg"`
session_count=`echo "$sessions" | wc -l`
tcp_stream_ids=`echo "$sessions" | sed 's/\s\+/ /g'  | cut -d ' ' -f 10 | sort | uniq`
echo "$tcp_stream_ids"

pcap_filter=$(build_pcap_filter "$tcp_stream_ids" )
event_pcap=$(filter_pcap "$pcap_filter" "$event_id_arg" "$pcap_arg" "$result_dir_arg")

stats_file="$result_dir_arg"/"$event_id_arg".tcp.stats.txt
tshark -r "$event_pcap" -q -z "conv,tcp" > "$stats_file"

echo "Pcap     : $event_pcap"
echo "TCP Stats: $stats_file"

cat "$stats_file"

exit 0

