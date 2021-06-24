#!/bin/bash

topic=$1
partition=$2
offset=$3

offset_sup=$((offset+10))


echo "ns:kafka topic:$topic partion:$partition messages:[$offset:$offset_sup]"
echo "==============================================================================================="
oc exec -n kafka kafka-tools -- bin/kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 \
         --topic $topic \
         --partition $partition \
         --offset $offset \
         --max-messages 10

echo "ns:kafka-mirror topic:my-source-cluster.$topic partion:$partition messages:[$offset:$offset_sup]"
echo "================================================================================================"
oc exec -n kafka-mirror kafka-tools -- bin/kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 \
         --topic my-source-cluster.$topic \
         --partition $partition \
         --offset $offset \
         --max-messages 10
