
# Network

## ASN
Uses [Team Cymru IP to ASN Mapping Service](https://www.team-cymru.com/ip-asn-mapping) over DNS, [RIPEstat Data API](https://stat.ripe.net/docs/02.data-api), and [PeeringDB API](https://www.peeringdb.com/apidocs).
```bash
# Print the AS info for the IP.
asn 8.8.8.8
# Print the AS info for the ASN.
asn AS15169
# List all prefixes announced for the ASN.
asn 7014 -p
# List all prefixes announced for the ASN and aggregate them.
asn 7014 -pp
# List all sibling ASNs owned by the same org.
asn 32934 -s
```

## Geolocation
Uses [IPinfo API](https://ipinfo.io/developers/data-types#geolocation-data) and [dataset](https://ipinfo.io/developers/database-download).
```bash
# Print geolocation information for the IP address.
geo 157.240.203.35
cat ip_address.list | geo
```

## Location
Uses [OurAirports dataset](https://ourairports.com/data).
```bash
# Print city and country of the airport.
iata sea
# Print verbose details of the airport.
iata sea -v
# Search for the airport by name.
iata mumbai
# Print country name for the ISO 3166 two-letter code.
iata IN
# Look up country code by the country name.
iata germany -c
```

## Measurement
Uses [RIPEstat Data API](https://stat.ripe.net/docs/02.data-api).
```bash
# Run traceroute to facebook.com from 10 random probes around the world.
ripe facebook.com
# Run traceroute to 8.8.8.8 from 10 probes in India.
ripe 8.8.8.8 IN
# Run traceroute to 8.8.8.8 from 100 probes in AT&T.
ripe 8.8.8.8 AS7018 100
# Count the active probes in India.
ripe IN
# Count the active probes in AT&T.
ripe AS7018
# Get the report for measurement #67353375.
ripe 67353375
```

## Vendor
Uses [IEEE OUI dataset](https://standards-oui.ieee.org).
```bash
# Get the vendor name for the MAC ID.
oui 1c:69:7a:65:de:eb
```

# Productivity

## Notification
Uses [Pushover](https://pushover.net), a push notification service.
```bash
# Send a push notification.
push "Script has finished"
# Notify with high priority if the script has a non-zero exit code.
./long_script.sh || push "Script has crashed!" -p
```

## Pastebin
Uses [@mkaczanowski's Pastebin](https://github.com/mkaczanowski/pastebin), a self-hosted pastebin.
```bash
# Upload file to pastebin.
cat file.txt | pb
# Upload contents of the clipboard to pastebin. Burn the paste after it's opened once.
pb -b
```

## URL Shortener
Uses [Shlink](https://shlink.io), a self-hosted URL Shortener.
```bash
# Shorten the URL.
shurl https://en.wikipedia.org/wiki/Computer_network
```
