#!/bin/bash -e

#mv tool-om/om-linux-* tool-om/om-linux
chmod +x tool-om/om-linux
CMD=./tool-om/om-linux

RELEASE=`$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k available-products | grep Pivotal_Single_Sign-On_Service`

PRODUCT_NAME=`echo $RELEASE | cut -d"|" -f2 | tr -d " "`
PRODUCT_VERSION=`echo $RELEASE | cut -d"|" -f3 | tr -d " "`

$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k stage-product -p $PRODUCT_NAME -v $PRODUCT_VERSION

function fn_other_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

OTHER_AZS=$(fn_other_azs $OTHER_JOB_AZS)

NETWORK=$(cat <<-EOF
{
  "singleton_availability_zone": {
    "name": "$SINGLETON_JOB_AZ"
  },
  "other_availability_zones": [
    $OTHER_AZS
  ],
  "network": {
    "name": "$NETWORK_NAME"
  }
}
EOF
)

PROPERTIES=$(cat <<-EOF
{
}
EOF
)
###Resource config
if [[ -z "$scs_broker_deployer_type" ]]; then
   scs_broker_deployer_type="automatic"
else
   scs_broker_deployer_type="$SCS_BROKER_DEPLOYER_TYPE"
fi

if [[ -z "$scs_broker_registrar_type" ]]; then
   scs_broker_registrar_type="automatic"
else
   scs_broker_registrar_type="$SCS_BROKER_REGISTRAR_TYPE"
fi

if [[ -z "$scs_smoke_test_type" ]]; then
   scs_smoke_test_type="automatic"
else
   scs_smoke_test_type="$SCS_SMOKE_TEST_TYPE"
fi

if [[ -z "$scs_broker_deregistrar_type" ]]; then
   scs_broker_deregistrar_type="automatic"
else
   scs_broker_deregistrar_type="$SCS_BROKER_DEREGISTRAR_TYPE"
fi

RESOURCES=$(cat <<-EOF
{
  "deploy-service-broker": { 
    "instance_type": {"id": "$scs_broker_deployer_type"}
  },
  "register-service-broker": {
    "instance_type": {"id": "$scs_broker_registrar_type"}
  },
  "run-smoke-tests": {
    "instance_type": {"id": "$scs_smoke_test_type"}
  },
  "destroy-service-broker": {
    "instance_typet": {"id": "$scs_broker_deregistrar_type"}
  }
}
EOF
)
#resource config end
$CMD -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k configure-product -n $PRODUCT_NAME -p "$PROPERTIES" -pn "$NETWORK" -pr "$RESOURCES"
