#!/bin/bash
# based on https://gist.github.com/Tras2/cba88201b17d765ec065ccbedfb16d9a
# get the basic data
ipv4=$(curl -s -X GET -4 https://ifconfig.co)
if [ $ipv4 ]; then echo -e "$(date -Iseconds -u) \033[0;32m [+] Your public IPv4 address: $ipv4"; else echo -e "$(date -Iseconds -u) \033[0;33m [!] Unable to get any public IPv4 address."; fi
ipv6=$(curl -s -X GET -6 https://ifconfig.co)
if [ $ipv6 ]; then echo -e "$(date -Iseconds -u) \033[0;32m [+] Your public IPv6 address: $ipv6"; else echo -e "$(date -Iseconds -u) \033[0;33m [!] Unable to get any public IPv6 address."; fi
user_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  -H "Content-Type:application/json" \
  | jq -r '{"result"}[] | .id')
# check if the user API is valid and the CLOUDFLARE_EMAIL is correct
if [ -z $user_id ]; then
  echo -e "$(date -Iseconds -u) \033[0;31m [-] There is a problem with the API token. Check it and try again."
fi
echo -e "$(date -Iseconds -u) \033[0;32m [+] Checking DNS records for $CLOUDFLARE_DOMAIN"

zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CLOUDFLARE_DOMAIN&status=active" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  | jq -r '{"result"}[] | .[0] | .id')
# check if the zone ID is avilable
if [ -z $zone_id ]; then
  echo -e "$(date -Iseconds -u) \033[0;31m [-] There is a problem with getting the Zone ID (subdomain) or the CLOUDFLARE_EMAIL address (username). Check them and try again."
fi

# check if there is any IP version 4
if [ $ipv4 ]; then
  CLOUDFLARE_DOMAIN_a_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=A"  \
    -H "Content-Type: application/json" \
    -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
    -H "Authorization: Bearer $CLOUDFLARE_TOKEN")
  # if the IPv4 exist
  for ((i=0;i<$(echo $CLOUDFLARE_DOMAIN_a_id | jq -r '{"result"}[] | length');i++)); do
    # change the A record
    curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$(echo $CLOUDFLARE_DOMAIN_a_id \
      | jq --argjson i "$i" -r '{"result"}[] | .[$i] | .id')" \
      -H "Content-Type: application/json" \
      -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
      -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
      --data "{\"type\":\"A\",\"content\":\"$ipv4\"}" > /dev/null
    # echo the result
    echo -e "$(date -Iseconds -u) \033[0;32m [+] The IPv4 A Record on Cloudflare has been set to $ipv4"
  done
fi

# check if there is any IP version 6
if [ $ipv6 ]; then
  CLOUDFLARE_DOMAIN_aaaa_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=AAAA"  \
    -H "Content-Type: application/json" \
    -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
    -H "Authorization: Bearer $CLOUDFLARE_TOKEN")
  # if the IPv4 exist
  for ((i=0;i<$(echo $CLOUDFLARE_DOMAIN_aaaa_id | jq -r '{"result"}[] | length');i++)); do
    # change the A record
    curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$(echo $CLOUDFLARE_DOMAIN_aaaa_id \
      | jq --argjson i "$i" -r '{"result"}[] | .[$i] | .id')" \
      -H "Content-Type: application/json" \
      -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
      -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
      --data "{\"type\":\"AAAA\",\"content\":\"$ipv6\"}" > /dev/null
    # echo the result
    echo -e "$(date -Iseconds -u) \033[0;32m [+] The IPv6 AAAA Record on Cloudflare has been set to $ipv6"
  done
fi
