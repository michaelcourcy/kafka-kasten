#!/bin/bash
# read the last 10 message of topic
ns=$1
topic=$2
page=$3
page=${page:=0}
if ! oc get po -n $ns kafka-tools &>/dev/null
then 
    echo "installing kafka-tools"
    oc run kafka-tools -n $ns --image=strimzi/kafka:0.20.0-kafka-2.6.0 -- tail -f /dev/null
fi

for item in $(oc exec -n $ns kafka-tools -- bin/kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list my-cluster-kafka-bootstrap:9092 --topic $topic)
do 
    partition=$(echo $item | cut -d: -f2)  
    offset=$(echo $item | cut -d: -f3)  
    offset=$((offset-(page*10)))
    offset_minus_10=$((offset-10)) 
    max_messages=10
    if [ $offset_minus_10 -le 0 ]; 
    then 
       offset_minus_10=0; 
       max_messages=$offset
    fi 
    echo "ns:$ns topic:$topic partion:$partition messages:[$offset_minus_10:$offset]"
    echo "=========================================================================="
    oc exec -n $ns kafka-tools -- bin/kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 \
         --topic $topic \
         --partition $partition \
         --offset $offset_minus_10 \
         --max-messages $max_messages
done