#!/bin/bash
# prepare ns 
if oc get ns kafka &>/dev/null; then echo "delete ns kafka"; oc delete ns kafka --wait; fi
if oc get ns kafka-mirror &>/dev/null; then echo "delete ns kafka-mirror"; oc delete ns kafka-mirror --wait; fi
oc create ns kafka; 
oc create ns kafka-mirror; 
oc -n kafka         adm policy add-scc-to-user anyuid -z my-cluster-zookeeper 
oc -n kafka         adm policy add-scc-to-user anyuid -z my-cluster-kafka 
oc -n kafka-mirror  adm policy add-scc-to-user anyuid -z my-cluster-zookeeper 
oc -n kafka-mirror  adm policy add-scc-to-user anyuid -z my-cluster-kafka 

#create kaka-tools pod  
oc -n kafka         run kafka-tools --image=strimzi/kafka:0.20.0-kafka-2.6.0 -- tail -f /dev/null
oc -n kafka-mirror  run  kafka-tools --image=strimzi/kafka:0.20.0-kafka-2.6.0 -- tail -f /dev/null

# create the same cluster 
oc -n kafka         apply -f kafka.yaml 
oc -n kafka-mirror  apply -f kafka.yaml 
oc -n kafka-mirror  patch kafka my-cluster --type='merge' --patch "$(cat patch-kafka-with-bp.yaml)"
#oc -n kafka-mirror  patch kafka my-cluster -p '{"spec.kafka.template": {"statefulset":{"metadata":{"annotations":{"kanister.kasten.io/blueprint":"scale-down-up-kafka-bp"}}}} }'

# activate strimzi operator 
oc scale deployment strimzi-cluster-operator-v0.23.0 --replicas=1 -n openshift-operators

# we wait for both cluster are ready
echo "wait for clusters to be ready" 
oc wait -n kafka        kafka my-cluster --for=condition=Ready --timeout=300s
oc wait -n kafka-mirror kafka my-cluster --for=condition=Ready --timeout=300s

# create topic on both side 
# Blogs 3 partions of 20 Go with replication factor 1 => 3 x 20 x 2 = 120 Gb 
oc -n kafka run kafka-topic -ti --image=strimzi/kafka:0.20.0-kafka-2.6.0 --rm=true --restart=Never -- bin/kafka-topics.sh \
     --create \
     --topic blogs \
     --partitions 3 \
     --replication-factor 2 \
     --config  retention.bytes=20000000000 \
     --bootstrap-server my-cluster-kafka-bootstrap:9092
# Items 10 partions of 30 Go with nreplication factor 1 => 10 x 30 x 1 = 300 Gb 
oc -n kafka run kafka-topic -ti --image=strimzi/kafka:0.20.0-kafka-2.6.0 --rm=true --restart=Never -- bin/kafka-topics.sh \
     --create \
     --topic items \
     --partitions 10 \
     --replication-factor 1 \
     --config  retention.bytes=30000000000 \
     --bootstrap-server my-cluster-kafka-bootstrap:9092

# Create mirror-maker
oc -n kafka-mirror apply -f my-mirror-maker-2.yaml 

# wait for they are ready with a timeout of 2 minutes 
oc wait -n kafka-mirror kafkamirrormaker2 my-mirror-maker --for=condition=Ready --timeout=120s


# create producer 
oc -n kafka apply -f items-producer-deployment.yaml
oc -n kafka apply -f blogs-producer-deployment.yaml

# unactivate strimzi operator
sleep 15
oc scale deployment strimzi-cluster-operator-v0.23.0 --replicas=0 -n openshift-operators