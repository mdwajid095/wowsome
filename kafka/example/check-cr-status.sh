File=$1
TIME_OUT=$2
OUT=`cat $3`
CR_STATE=`echo $OUT |cut -d" " -f2`
RED_ColourCode=91m
GREEN_ColourCode=92m

printStatus(){
    echo "$2"
    echo -e "\033[0;$1 STATE = $(kubectl get pods $component -o 'jsonpath={..status.containerStatuses[].state}') \033[m" | xargs -n1
}

podDeployment(){
    echo "$component rollout is about to start in 20s..." && sleep 20s && let COUNTER+=20
    while [[ $(kubectl get pods $component -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]
    do
        echo "waiting for pod.  :::$component" && sleep 15s && let COUNTER+=15
        if [ "$COUNTER" -gt "$TIME_OUT" ]; then
            printStatus $RED_ColourCode "$component is taking more time to come in RUNNING state. It has crossed the TIME_OUT: $COUNTER"
            exit -1
        fi
    done        
}

for component in $(kubectl get --no-headers=true pods -l app=$File -o custom-columns=:metadata.name |sort -r)
do
    if [ "$CR_STATE" != "unchanged" ]; then
        podDeployment
    fi
    printStatus $GREEN_ColourCode "$component deployed successfully..."
done

