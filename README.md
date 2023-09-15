This repo contains scripts for analyzing and processing pcaps. Their main 
purpose was to analyze pcaps produced by the Squid proxy layer at the
edge and to extract out individual streams based on Event ID from those
pcaps.

= How to process =

== Pre-Process ==
First there are a set of pre-process steps, you only need to do this once for each set of pcaps you download for a given time window that you're interested in.

1. Download the pcaps for the given time span of interest. Use the command ./find_pcaps_based_on_time.sh  to more easily find the correct pcaps to download.
   Example: ./find_pcaps_based_on_time.sh  --start '2023-09-10 13:00:00' --end '2023-09-10 13:10:00'
2. Merge all of the downloaded pcaps per proxy into a single file using the command mergecap (part of the wireshark install).
   Example: mergecap -w <merged.pcap> tshark_*.pcap
3. To make it more efficient for future processing, we will process the massive pcap ones and write the information out in various files, which the other scripts
   will work off of. This so we don't have to keep processing the same pcap over and over when we're trying to find a particular event. Do do this, we want to 
   find all the HTTP CONNECTs because they contain the event ID and then find all the SSL sessions since we need to correlate internal and external side of the proxy.
   What ties the two together are then the "tcp conversation stream id" (a wireshark concept, you won't find it elsewhere, nor in the actual traffic).

   a. run script `find_http_connects.sh <outputfile.pcap>` and pipe the result to a file:
      find_http_connects.sh <merged.pcap> > <http_connects.csv>
   b. run script `find_streams.sh`, which will find all the TLS Handshakes, print out their Session IDs, which is how you tie the internal and the external side together. Pipe the result to a file.
      find_streams.sh <merged.pcap> > <streams.csv>

We are now ready to query the data in a more efficient manner since all the meta-data that we need in order to identify a given attempt, has been extracted.

== Process ==

The only thing that we can query on right now is the event id. Given this id, you'll be able to extract:

1. The internal and external traffic of the proxy. The raw traffic will be saved as a pcap.
2. 


