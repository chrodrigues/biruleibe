#!/bin/bash
#/var/lib/cloud/scripts/per-once

get_hostname(){
  #login values
  PROXMOX_USERNAME=$PROXMOX_USERNAME
  PROXMOX_PASSWORD=$PROXMOX_PASSWORD
  PROXMOX_HOST=$PROXMOX_HOST
  #get all mac adresses
  MAC_ADDRESS=($(cat /sys/class/net/*/address))

  #get ticket
  DATA=`curl -s4 -k -d "username=$PROXMOX_USERNAME&password=$PROXMOX_PASSWORD" $PROXMOX_HOST/api2/json/access/ticket`
  TICKET=$(echo "${DATA}" | jq -r .data.ticket )
  CSRF=$(echo "${DATA}" | jq -r .data.CSRFPreventionToken)

  #get all vms
  DATA=$(curl -s4k -b "PVEAuthCookie=$TICKET" $HOST/api2/json/cluster/resources | jq -S -r '(.data[] |select(.type=="qemu")) ')
  NODE=($(echo "${DATA}" | jq -r .node))
  VMID=($(echo "${DATA}" | jq -r .vmid))
  NAME=($(echo "${DATA}" | jq -r .name | sed s/'VM.[0-9]*'/unnamed/g))
  echo "own mac"$MAC_ADDRESS
  #get interface mac address
  for ((i = 0 ; i < ${#VMID[@]} ; i++)); do
    DATA=$(curl -s4k -b "PVEAuthCookie=$TICKET" $HOST/api2/json/nodes/${NODE[$i]}/qemu/${VMID[$i]}/config)
    MAC=$(echo "${DATA}" | jq .data.net0 | cut -d "=" -f2 | cut -d "," -f1)
    #compare mac adress
    if [[ "${MAC_ADDRESS[@]}" =~ "${MAC,,}" ]]; then
        echo $MAC
        echo "${NAME[$i]}"
        #set hostame
        if [[ ! "${NAME[$i]}" == "null" ]];then
          if [[ -n "${NAME[$i]}" ]];then
            if [[ ! $(cat /etc/hostname) = "${NAME[$i]}" ]];then
                  oldname=$(cat /etc/hostname)
                  sed -i -e "s/$oldname/${NAME[$i]}/g" /etc/hosts
                  hostnamectl set-hostname "${NAME[$i]}"
                  HOSTNAME="${NAME[$i]}"
                  reboot
            fi
          fi
        fi
        break
    fi
  done
}


main(){
    get_hostname
}

main
