#!/bin/bash

topic=$1
num_partitions=$2
max_messages=$3
offset=$4
offset=${offset:=0}
if [ $offset -eq 0 ]; 
then 
    offset="--from-beginning"; 
else 
    offset="--offset $offset"; 
fi

echo "==========================================================="
echo "Comparing topic $topic between kafka and kafka-mirror"
echo "Comparing from $offset a number of $max_messages messages"
echo "On $num_partitions partitions"
echo "==========================================================="

tmp_dir=$(mktemp -d)

for partition in $(seq 0 $num_partitions)
do
    cluster=kafka
    echo "Checking on $cluster"
    partition_file_kafka="$tmp_dir/${cluster}_${partition}"
    oc exec -n $cluster kafka-tools -- bin/kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 \
            --topic $topic \
            --partition $partition \
            $offset \
            --max-messages $max_messages > $partition_file_kafka
    md5_kafka=($(md5sum $partition_file_kafka))
    

    cluster=kafka-mirror
    echo "Checking on $cluster"
    partition_file_kafka_mirror="$tmp_dir/${cluster}_${partition}"
    oc exec -n $cluster kafka-tools -- bin/kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 \
            --topic my-source-cluster.$topic \
            --partition $partition \
            $offset \
            --max-messages $max_messages > $partition_file_kafka_mirror
    md5_kafka_mirror=($(md5sum $partition_file_kafka_mirror))
    
    echo "Comparing md5 file between"
    echo "  $partition_file_kafka"
    echo "  $partition_file_kafka_mirror"    
    
    if [ "$md5_kafka" = "$md5_kafka_mirror" ]; then
        echo "topic $topic partition $partition are equals between $offset on $max_messages messages on both clusters"
    else
        echo "topic $topic partition $partition are **not equal** between $offset on $max_messages messages on both clusters"
        exit 1
    fi
    echo "---------------------------------------------------------------------------------------------------------------------"
done

echo "Topic $topic are completly equals from $offset on $max_messages messages on all the partitions"
echo "cleaning temporary directory $tmp_dir"
rm -rf $tmp_dir