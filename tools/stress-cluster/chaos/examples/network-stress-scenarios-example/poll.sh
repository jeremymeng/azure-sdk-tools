set -x

if test -f "$ENV_FILE"; then
    echo "env file located at $ENV_FILE:"
    ls -al $ENV_FILE
else
    echo "ENV FILE NOT FOUND"
fi

while true;
    # Azure AKS default outbound rules do not allow ICMP,
    # so use wget in place of ping for deployment simplicity
    echo "SCENARIO_NAME: $SCENARIO_NAME"
    do wget -T1 -t1 --spider http://$SCENARIO_NAME.bing.com
    sleep 5
done
