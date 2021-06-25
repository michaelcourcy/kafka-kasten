# Set up the env Kafka, kafka-mirror and producers 

Video : setup_env.mp4

## situation 

We setup here the initial situation with thanks to the strimzi operator on Openshift on Azure. 
We use a managed premium storage class.
1.   One kafka cluster : 6 brokers of 100 Go each 3 zookeeper 20 Go each 
2.   One kafka-mirror cluster in another namespace that replicate the kafka cluster with mirror maker
3.   2 group of producers that write in blogs and items topic with a rate of **10 000 messages per second**
    *    blogs : 3 partions of 20 Go with replication factor 1 => 3 x 20 x 2 = 120 Gb 
    *    items : 10 partions of 30 Go with nreplication factor 1 => 10 x 30 x 1 = 300 Gb

The producers are writing message that are composed with `date`,  `producer name` and a `uniq id` to make sure that 
each messages are unique and comparison between initial and mirror or between initial and restored are unambiguous.

We embed this producers in a deployment we can scale to increase the production rate and do test performance easily.

```
    spec:
      containers:
        - name: producer
          env: 
          - name: POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name 
          image: 'strimzi/kafka:0.20.0-kafka-2.6.0'
          args:
            - bash
            - '-c'
            - >-
              (while true; do echo "$(date) -- $POD_NAME $(uuidgen)"; done) 
              | bin/kafka-console-producer.sh
              --broker-list my-cluster-kafka-bootstrap:9092 --topic items
```


To setup this env we provide the `recreate_env.sh` script

```
./recreate_env.sh 
delete ns kafka
namespace "kafka" deleted
delete ns kafka-mirror
namespace "kafka-mirror" deleted
namespace/kafka created
namespace/kafka-mirror created
clusterrole.rbac.authorization.k8s.io/system:openshift:scc:anyuid added: "my-cluster-zookeeper"
clusterrole.rbac.authorization.k8s.io/system:openshift:scc:anyuid added: "my-cluster-kafka"
clusterrole.rbac.authorization.k8s.io/system:openshift:scc:anyuid added: "my-cluster-zookeeper"
clusterrole.rbac.authorization.k8s.io/system:openshift:scc:anyuid added: "my-cluster-kafka"
pod/kafka-tools created
pod/kafka-tools created
kafka.kafka.strimzi.io/my-cluster created
kafka.kafka.strimzi.io/my-cluster created
kafka.kafka.strimzi.io/my-cluster patched
deployment.apps/strimzi-cluster-operator-v0.23.0 scaled
wait for clusters to be ready
kafka.kafka.strimzi.io/my-cluster condition met
kafka.kafka.strimzi.io/my-cluster condition met
If you don't see a command prompt, try pressing enter.
Created topic blogs.
pod "kafka-topic" deleted
If you don't see a command prompt, try pressing enter.
Created topic items.
pod "kafka-topic" deleted
kafkamirrormaker2.kafka.strimzi.io/my-mirror-maker created
kafkamirrormaker2.kafka.strimzi.io/my-mirror-maker condition met
deployment.apps/items created
deployment.apps/blogs created
deployment.apps/strimzi-cluster-operator-v0.23.0 scaled
```

##  We have around 8000 messages per second on each cluster

We can verify that with the `count_message_per_seconds.sh <cluster-ns> <topic>` script 

```
./count_message_per_seconds.sh kafka blogs     
counting the offsets of blogs ...
blogs:0:1974438
blogs:1:1982296
blogs:2:1978147
Waiting 5 second to recount the offsets of blogs ...
blogs:0:1981291
blogs:1:1987655
blogs:2:1984808
3774/s blogs messages

./count_message_per_seconds.sh kafka-mirror my-source-cluster.blogs
counting the offsets of my-source-cluster.blogs ...
my-source-cluster.blogs:0:1992818
my-source-cluster.blogs:1:1998748
my-source-cluster.blogs:2:1997529
Waiting 5 second to recount the offsets of my-source-cluster.blogs ...
my-source-cluster.blogs:0:1999194
my-source-cluster.blogs:1:2005876
my-source-cluster.blogs:2:2004406
4076/s my-source-cluster.blogs messages
```

We have the same result for items topic hence 8000 messages per second.

## There is exactly the same data between the 2 clusters 

Stop the producers 
```
oc -n kafka scale deployment blogs --replicas=0
oc -n kafka scale deployment items --replicas=0
```

Wait for the producer to stop you can reuse the `count_message_per_seconds.sh`to check no mesages 
are produced on the mirror that means all activities are stopped

```
./count_message_per_seconds.sh kafka-mirror my-source-cluster.items
counting the offsets of my-source-cluster.items ...
my-source-cluster.items:0:622229
my-source-cluster.items:1:619718
my-source-cluster.items:2:635153
my-source-cluster.items:3:618256
my-source-cluster.items:4:676222
my-source-cluster.items:5:677143
my-source-cluster.items:6:628399
my-source-cluster.items:7:624200
my-source-cluster.items:8:627704
my-source-cluster.items:9:622321
Waiting 5 second to recount the offsets of my-source-cluster.items ...
my-source-cluster.items:0:622229
my-source-cluster.items:1:619718
my-source-cluster.items:2:635153
my-source-cluster.items:3:618256
my-source-cluster.items:4:676222
my-source-cluster.items:5:677143
my-source-cluster.items:6:628399
my-source-cluster.items:7:624200
my-source-cluster.items:8:627704
my-source-cluster.items:9:622321
0/s my-source-cluster.items messages
```

You can do a quick check on the head of a topic with 
```
./read_last_10_messages.sh kafka blogs
ns:kafka topic:blogs partion:0 messages:[2118890:2118900]
==========================================================================
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-4h9zc bdd8388a-f2fb-4a7e-992a-ee1475855c17
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-4h9zc 9ffb33c5-d4f7-4cc5-90f6-a7088a803019
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-4h9zc d246ec12-1cd5-47ac-9f0c-d31936e1b55b
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-4h9zc 3ed77cf1-832e-46d2-9f69-660614c43c4b
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-4h9zc d93df5dd-acbd-4d75-8a1a-03da520cacd8
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-4h9zc 687cd630-e1ec-4560-b09c-9c41724ddf9e
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-4h9zc ea7cc467-d62f-45c2-88d1-a6be38f50a02
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-4h9zc b0581b17-3f10-43f1-a317-56e10adf678a
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-4h9zc 80ec641b-ddf3-4031-9bb4-3bcaa772d659
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-4h9zc 1af6a330-7de4-46f8-a7dc-3b2d02f073c4
Processed a total of 10 messages
ns:kafka topic:blogs partion:1 messages:[2125255:2125265]
==========================================================================
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm 18a4ec59-b189-4f16-ac71-7b8a021a7ec1
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm 8f78e5b8-d460-43a6-a161-d0317d85b49d
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm 22fdcb8b-3cf1-4061-a398-7977de6f72ae
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm 4625872b-01b0-4d98-90aa-62d47a419df7
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm b32594f2-3027-4a6a-ae29-979b0da82c92
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm 59b43a05-4a9c-429b-8ce5-35481ed91932
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm f4046e3e-006a-424b-89e4-24656ee9d4b4
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm 0dfeb303-b7ff-431a-b93e-99f2b7bfd952
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm f5a811ad-991e-46ea-9147-2f7f948d2f48
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm 10f30f59-0c34-4a2b-bd05-14533bf98f7f
Processed a total of 10 messages
ns:kafka topic:blogs partion:2 messages:[2130547:2130557]
==========================================================================
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl e1ae0aa9-8962-4a2b-97ad-b807568a60e1
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl 01072be2-8d9a-493e-a62f-1d00faf4b219
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl 626e042c-a1d4-4466-8069-60e0b274292a
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl de08bc26-297c-462c-8005-2ab5af21660d
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl 3239f0e2-c648-452a-9eea-ad1388a2b839
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl 1f61e755-7e16-46d5-a3d5-b098cbd2f06c
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl c6e8c882-508b-4843-a004-31710ba9fc3f
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl 6215a0a8-6a73-4a98-bafb-e8156b547244
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl 38520253-2cf5-43c0-b56d-4c33139b747e
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl 26bf2174-c48c-4f41-96da-6fed0bf7be6c


./read_last_10_messages.sh kafka-mirror my-source-cluster.blogs
ns:kafka-mirror topic:my-source-cluster.blogs partion:0 messages:[2118890:2118900]
==========================================================================
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-4h9zc bdd8388a-f2fb-4a7e-992a-ee1475855c17
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-4h9zc 9ffb33c5-d4f7-4cc5-90f6-a7088a803019
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-4h9zc d246ec12-1cd5-47ac-9f0c-d31936e1b55b
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-4h9zc 3ed77cf1-832e-46d2-9f69-660614c43c4b
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-4h9zc d93df5dd-acbd-4d75-8a1a-03da520cacd8
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-4h9zc 687cd630-e1ec-4560-b09c-9c41724ddf9e
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-4h9zc ea7cc467-d62f-45c2-88d1-a6be38f50a02
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-4h9zc b0581b17-3f10-43f1-a317-56e10adf678a
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-4h9zc 80ec641b-ddf3-4031-9bb4-3bcaa772d659
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-4h9zc 1af6a330-7de4-46f8-a7dc-3b2d02f073c4
Processed a total of 10 messages
ns:kafka-mirror topic:my-source-cluster.blogs partion:1 messages:[2125255:2125265]
==========================================================================
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm 18a4ec59-b189-4f16-ac71-7b8a021a7ec1
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm 8f78e5b8-d460-43a6-a161-d0317d85b49d
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm 22fdcb8b-3cf1-4061-a398-7977de6f72ae
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm 4625872b-01b0-4d98-90aa-62d47a419df7
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm b32594f2-3027-4a6a-ae29-979b0da82c92
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm 59b43a05-4a9c-429b-8ce5-35481ed91932
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm f4046e3e-006a-424b-89e4-24656ee9d4b4
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm 0dfeb303-b7ff-431a-b93e-99f2b7bfd952
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm f5a811ad-991e-46ea-9147-2f7f948d2f48
Thu Jun 24 10:14:35 UTC 2021 -- blogs-f5d8f5d58-5n9gm 10f30f59-0c34-4a2b-bd05-14533bf98f7f
Processed a total of 10 messages
ns:kafka-mirror topic:my-source-cluster.blogs partion:2 messages:[2130547:2130557]
==========================================================================
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl e1ae0aa9-8962-4a2b-97ad-b807568a60e1
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl 01072be2-8d9a-493e-a62f-1d00faf4b219
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl 626e042c-a1d4-4466-8069-60e0b274292a
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl de08bc26-297c-462c-8005-2ab5af21660d
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl 3239f0e2-c648-452a-9eea-ad1388a2b839
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl 1f61e755-7e16-46d5-a3d5-b098cbd2f06c
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl c6e8c882-508b-4843-a004-31710ba9fc3f
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl 6215a0a8-6a73-4a98-bafb-e8156b547244
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl 38520253-2cf5-43c0-b56d-4c33139b747e
Thu Jun 24 10:14:36 UTC 2021 -- blogs-f5d8f5d58-xgmrl 26bf2174-c48c-4f41-96da-6fed0bf7be6c
Processed a total of 10 messages
```

The uid let you check the identity on both clusters.

But you can run a more complete check on the integrality of the partitions comparing, 
this can be long for the max messages you must choose the smallest offset of the partitions,
her for blob it's 2118900.

```
bash compare_topic.sh blogs 2 2118900
===========================================================
Comparing topic blogs between kafka and kafka-mirror
Comparing from --from-beginning a number of 2118900 messages
On 2 partitions
===========================================================
Checking on kafka
Processed a total of 2118900 messages
Checking on kafka-mirror
Processed a total of 2118900 messages
Comparing md5 file between
  /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.WgCw5Ffu/kafka_0
  /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.WgCw5Ffu/kafka-mirror_0
topic blogs partition 0 are equals between --from-beginning on 2118900 messages on both clusters
---------------------------------------------------------------------------------------------------------------------
Checking on kafka
Processed a total of 2118900 messages
Checking on kafka-mirror
Processed a total of 2118900 messages
Comparing md5 file between
  /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.WgCw5Ffu/kafka_1
  /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.WgCw5Ffu/kafka-mirror_1
topic blogs partition 1 are equals between --from-beginning on 2118900 messages on both clusters
---------------------------------------------------------------------------------------------------------------------
Checking on kafka
Processed a total of 2118900 messages
Checking on kafka-mirror
Processed a total of 2118900 messages
Comparing md5 file between
  /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.WgCw5Ffu/kafka_2
  /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.WgCw5Ffu/kafka-mirror_2
topic blogs partition 2 are equals between --from-beginning on 2118900 messages on both clusters
---------------------------------------------------------------------------------------------------------------------
Topic blogs are completly equals from --from-beginning on 2118900 messages on all the partitions
cleaning temporary directory /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.WgCw5Ffu
```

We get the same result for items.

That show tha the too topics are the same 





