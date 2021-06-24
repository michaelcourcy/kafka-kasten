#!/bin/bash
# count the number of messages produced at each second
ns=$1
topic=$2
# create kafka-tools if needed 
if ! oc get po -n $ns kafka-tools &>/dev/null
then 
    echo "installing kafka-tools"
    oc run kafka-tools -n $ns --image=strimzi/kafka:0.20.0-kafka-2.6.0 -- tail -f /dev/null
fi

echo "counting the offsets of $topic ..."

first_total=0

offset=0
for item in $(oc exec -n $ns kafka-tools -- bin/kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list my-cluster-kafka-bootstrap:9092 --topic $topic)
do 
    echo $item
    offset=$(echo $item | cut -d: -f3)  
    first_total=$((first_total + offset))    
done

echo "$first_total $topic messages in $ns"