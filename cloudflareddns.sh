#!/bin/bash
set -e;

ipv4Regex="((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])"

proxy="false"

# DSM Config
username="$1"
password="$2"
hostname="$3"
ipAddr="$4"

if [[ $ipAddr =~ $ipv4Regex ]]; then
    recordType="A";
else
    recordType="AAAA";
fi


getZoneIDApi="https://api.cloudflare.com/client/v4/zones?name=7539510.xyz"
zoneRes=$(curl -s -X GET "$getZoneIDApi" -H "X-Auth-Email: ${username}" -H "X-Auth-Key: ${password}" -H "Content-Type:application/json")
zoneid=$(echo "$zoneRes" | jq -r ".result[0].id")


listDnsApi="https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records?type=${recordType}&name=${hostname}"
createDnsApi="https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records"

res=$(curl -s -X GET "$listDnsApi" -H "X-Auth-Email: ${username}" -H "X-Auth-Key: ${password}" -H "Content-Type:application/json")
resSuccess=$(echo "$res" | jq -r ".success")


if [[ $resSuccess != "true" ]]; then
    echo "badauth";
    exit 1;
fi

recordId=$(echo "$res" | jq -r ".result[0].id")
recordIp=$(echo "$res" | jq -r ".result[0].content")


if [[ $recordIp = "$ipAddr" ]]; then
    echo "nochg";
    exit 0;
fi

if [[ $recordId = "null" ]]; then
    # Record not exists
    res=$(curl -s -X POST "$createDnsApi" -H "X-Auth-Email: ${username}" -H "X-Auth-Key: ${password}" -H "Content-Type:application/json" --data "{\"type\":\"$recordType\",\"name\":\"$hostname\",\"content\":\"$ipAddr\",\"proxied\":$proxy}")
else
    # Record exists
    updateDnsApi="https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records/${recordId}";
    res=$(curl -s -X PUT "$updateDnsApi" -H "X-Auth-Email: ${username}" -H "X-Auth-Key: ${password}" -H "Content-Type:application/json" --data "{\"type\":\"$recordType\",\"name\":\"$hostname\",\"content\":\"$ipAddr\",\"proxied\":$proxy}")
fi

resSuccess=$(echo "$res" | jq -r ".success")

if [[ $resSuccess = "true" ]]; then
    echo "good";
else
    echo "badauth";
fi
