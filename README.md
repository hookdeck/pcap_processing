
# Pcap Analysis Repository

This repository contains scripts designed to analyze and process pcaps. The primary objective is to analyze pcaps generated by the Squid proxy layer at the edge and extract individual streams based on a specified Event ID.

## How to Process

The main objective is to extract the traffic associated with a given Event ID on both sides of the Squid edge proxy.

### Pre-Process Steps

Execute these steps once for each set of pcaps you download for a specific time frame.

1. **Download pcaps:** Obtain the pcaps for your desired time span using:
   ```bash
   ./find_pcaps_based_on_time.sh --start 'YYYY-MM-DD HH:MM:SS' --end 'YYYY-MM-DD HH:MM:SS'
   ```
   Example:
   ```bash
   ./find_pcaps_based_on_time.sh --start '2023-09-10 13:00:00' --end '2023-09-10 13:10:00'
   ```

2. **Merge pcaps:** Combine all the downloaded pcaps for each proxy into one file using `mergecap` (from the Wireshark package).
   ```bash
   mergecap -w merged.pcap tshark_*.pcap
   ```

3. **Optimization:** To boost future processing efficiency, process the large pcap file once and save the information in different files to avoid repetitive processing of the same pcap. We aim to locate all the HTTP CONNECTs (which contain the Event ID) and then identify all SSL sessions for correlating the internal and external sides of the proxy. The "tcp conversation stream id" is essential for this (a Wireshark-specific concept).

   a. Execute the `find_http_connects.sh` script and redirect the output to a file:
      ```bash
      find_http_connects.sh merged.pcap > http_connects.csv
      ```

   b. Run the `find_streams.sh` script to identify all TLS Handshakes, display their Session IDs (linking the internal and external sides), and redirect the result to a file:
      ```bash
      find_streams.sh merged.pcap > streams.csv
      ```

After the pre-processing, you can efficiently query the data since we've extracted all the required meta-data.

### Process

To identify the traffic for a specific Event ID, use the `process` script and provide the necessary pre-processed files.

Example:

During the pre-process, we merged all individual pcaps into `merged.pcap`. We extracted the HTTP CONNECT information into `http_connects.csv` and saved TCP stream information, including the SSL Session ID, in `streams.csv`. Utilize the `process` command as follows:

```bash
./process.sh --http_connect http_connects.csv --streams streams.csv --pcap merged.pcap <event id>
```

This command extracts the traffic for the specified Event ID, saves it in a new pcap, and also captures TCP stats in a separate file.
