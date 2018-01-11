#!/bin/bash

set -eu


# echo "Shutting down OLD OpsMgr VM... ${OPSMAN_IP} for the upgrade"
# Is it currently powered on?
POWEREDON=`govc vm.info -vm.ip=${OM_IP} | grep poweredOn | awk '{print $3}'`
if [ "$POWEREDON" == "poweredOn" ]; then
   govc vm.power -off=true -vm.ip=${OM_IP}
fi

file_path=`find ./pivnet-opsman-product/ -name *.ova`

echo $file_path

govc import.spec $file_path | python -m json.tool > om-import.json

cat > filters <<'EOF'
del(.Deployment) |
.Name = $vmName |
.DiskProvisioning = $diskType |
.NetworkMapping[].Network = $network |
.PowerOn = $powerOn |
(.PropertyMapping[] | select(.Key == "ip0")).Value = $ip0 |
(.PropertyMapping[] | select(.Key == "netmask0")).Value = $netmask0 |
(.PropertyMapping[] | select(.Key == "gateway")).Value = $gateway |
(.PropertyMapping[] | select(.Key == "DNS")).Value = $dns |
(.PropertyMapping[] | select(.Key == "ntp_servers")).Value = $ntpServers |
(.PropertyMapping[] | select(.Key == "admin_password")).Value = $adminPassword |
(.PropertyMapping[] | select(.Key == "custom_hostname")).Value = $customHostname
EOF

jq \
  --arg ip0 "$OM_IP" \
  --arg netmask0 "$OM_NETMASK" \
  --arg gateway "$OM_GATEWAY" \
  --arg dns "$OM_DNS_SERVERS" \
  --arg ntpServers "$OM_NTP_SERVERS" \
  --arg adminPassword "$OPS_MGR_SSH_PWD" \
  --arg customHostname "$OM_VM_NAME" \
  --arg network "$OM_VM_NETWORK" \
  --arg vmName "$OM_VM_NAME" \
  --arg diskType "$OM_DISK_TYPE" \
  --argjson powerOn $OM_VM_POWER_STATE \
  --from-file filters \
  om-import.json > options.json

cat options.json

if [ -z $OM_VM_FOLDER ]; then
  govc import.ova -options=options.json $file_path
else
  if [ `govc folder.info $OM_VM_FOLDER 2>&1 | grep $OM_VM_FOLDER | awk '{print $2}'` != $OM_VM_FOLDER ]; then
    govc folder.create $OM_VM_FOLDER
  fi
  govc import.ova -folder=$OM_VM_FOLDER -options=options.json $file_path
fi
