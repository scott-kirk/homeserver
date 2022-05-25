#!/bin/bash
# based on https://gist.github.com/Tras2/cba88201b17d765ec065ccbedfb16d9a
# get the basic data
ipv4=$(curl -s -X GET -4 https://ifconfig.co)
ipv6=$(curl -s -X GET -6 https://ifconfig.co)
user_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
               -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
               -H "Content-Type:application/json" \
          | jq -r '{"result"}[] | .id'
         )

# write down IPv4 and/or IPv6
if [ $ipv4 ]; then echo -e "\033[0;32m [+] Your public IPv4 address: $ipv4"; else echo -e "\033[0;33m [!] Unable to get any public IPv4 address."; fi
if [ $ipv6 ]; then echo -e "\033[0;32m [+] Your public IPv6 address: $ipv6"; else echo -e "\033[0;33m [!] Unable to get any public IPv6 address."; fi

# check if the user API is valid and the CLOUDFLARE_EMAIL is correct
if [ $user_id ]
then
    zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CLOUDFLARE_DOMAIN&status=active" \
                   -H "Content-Type: application/json" \
                   -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
                   -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
              | jq -r '{"result"}[] | .[0] | .id'
             )
    # check if the zone ID is avilable
    if [ $zone_id ]
    then
        # check if there is any IP version 4
        if [ $ipv4 ]
        then
            CLOUDFLARE_DOMAIN_a_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=A&name=$CLOUDFLARE_DOMAIN"  \
                                   -H "Content-Type: application/json" \
                                   -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
                                   -H "Authorization: Bearer $CLOUDFLARE_TOKEN"
                             )
            # if the IPv4 exist
            CLOUDFLARE_DOMAIN_a_ip=$(echo $CLOUDFLARE_DOMAIN_a_id |  jq -r '{"result"}[] | .[0] | .content')
            if [ $CLOUDFLARE_DOMAIN_a_ip != $ipv4 ]
            then
                # change the A record
                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$(echo $CLOUDFLARE_DOMAIN_a_id | jq -r '{"result"}[] | .[0] | .id')" \
                     -H "Content-Type: application/json" \
                     -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
                     -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
                     --data "{\"type\":\"A\",\"name\":\"$CLOUDFLARE_DOMAIN\",\"content\":\"$ipv4\",\"ttl\":1,\"proxied\":true}" \
                | jq -r '.errors'
                # write the result
                echo -e "\033[0;32m [+] The IPv4 A Record on Cloudflare has been updated from: $CLOUDFLARE_DOMAIN_a_ip to $ipv4"
            else
                echo -e "\033[0;37m [~] The current IPv4 is present on Cloudflare; there is no need to update it."
            fi
        fi

        # check if there is any IP version 6
        if [ $ipv6 ]
        then
            CLOUDFLARE_DOMAIN_aaaa_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=AAAA&name=$CLOUDFLARE_DOMAIN"  \
                                      -H "Content-Type: application/json" \
                                      -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
                                      -H "Authorization: Bearer $CLOUDFLARE_TOKEN"
                                )
            # if the IPv6 exist
            CLOUDFLARE_DOMAIN_aaaa_ip=$(echo $CLOUDFLARE_DOMAIN_aaaa_id | jq -r '{"result"}[] | .[0] | .content')
            if [ $CLOUDFLARE_DOMAIN_aaaa_ip != $ipv6 ]
            then
                # change the AAAA record
                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$(echo $CLOUDFLARE_DOMAIN_aaaa_id | jq -r '{"result"}[] | .[0] | .id')" \
                     -H "Content-Type: application/json" \
                     -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
                     -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
                     --data "{\"type\":\"AAAA\",\"name\":\"$CLOUDFLARE_DOMAIN\",\"content\":\"$ipv6\",\"ttl\":1,\"proxied\":true}" \
                | jq -r '.errors'
                # write the result
                echo -e "\033[0;32m [+] The IPv6 AAAA Record on Cloudflare has been updated from: $CLOUDFLARE_DOMAIN_aaaa_ip to $ipv6"
            else
                echo -e "\033[0;37m [~] The current IPv6 address is present on Cloudflare; there is no need to update it."
            fi
        fi
    else
        echo -e "\033[0;31m [-] There is a problem with getting the Zone ID (subdomain) or the CLOUDFLARE_EMAIL address (username). Check them and try again."
    fi
else
    echo -e "\033[0;31m [-] There is a problem with the API token. Check it and try again."
fi
