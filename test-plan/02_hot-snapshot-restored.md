# Hot snapshot restore 

Videos : hotsnapshot-restored.mp4

## Situation 

We take a hot snapshot of the kafka cluster then we : 
1.   Stop all producers
2.   Stop mirror maker 
3.   Restore the hotsnapshot on the kafka cluster 

## Assumption 1 before the snapshot

Before the snap a topic with it's partition are in this state 

Blogs topic before snap :
```
Partition 0: ---------------------------
Partition 1: ---------------------------
Partition 2: ---------------------------
```

messages are evenly distributed.

## Assumption 2 on the head of the restored topic 

But because partitions are not snapshotted exactly in the same time and not 
all segments are completly flushed at the snapshot time we are in this situtation : 

Blogs topic snapshotted :
```
Partition 0: ---------------------------
                                       ^ capture at time                                     
Partition 1: ---------------------------
                                      ^ capture at time but last segment not flushed
Partition 2: ------------------------------
                                          ^ capture at time + epsilon because even if snap are scheduled in 
                                          the same time storage may not be immediatly available for snap
```

When you restore you get this situation 

Blogs topic restored :
```
Partition 0: ---------------------------
Partition 1: --------------------------
Partition 2: ------------------------------
```

## Assumption 3 on the tail of the restored topic 

Beeing able to rework in this situation depends of the applications that use the topic 
if we can at least garantee that no segments are missing in the middle of a partition
after the restoration.

We do the assumptions that tail of the restored topic do not lose any segments and me must prove it.

## How do I check  assumptions 1,2 and 3 

### Assumption 1 befote the snapshot

First check the head of your partitions before snapshot 
```
./read_last_10_messages.sh kafka blogs
ns:kafka-mirror topic:my-source-cluster.blogs partion:0 messages:[1563565:1563575]
==========================================================================
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-4xqhs 07cbffc5-0e95-488e-92ef-bd41894cec96
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-4xqhs bfb79b6f-7e96-4385-ab27-99d345864afd
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-4xqhs 0ab041f5-e219-4389-887a-c10503d92d24
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-4xqhs d2b3ec7f-476f-4b71-a766-b3a8e919f457
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-4xqhs b9c8273e-3deb-40d6-9759-bb66007d97b1
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-4xqhs 6a0d54b0-000d-449e-ade1-16624b4226ff
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-4xqhs 2405cd4d-9dc0-4761-84eb-04d7245c1c7b
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-4xqhs b75a8db5-0a1a-4c70-8c65-76f828a8fa27
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-4xqhs 3dde1378-2f74-45b5-82c3-3560993bf54e
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-4xqhs f8c4d069-2e17-497b-8b5e-e325bf87ef00
Processed a total of 10 messages
ns:kafka-mirror topic:my-source-cluster.blogs partion:1 messages:[1546769:1546779]
==========================================================================
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-jzjdd da3ba361-38c2-40b1-8427-84a5994e6c7d
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-jzjdd e45f0fde-040d-4eb1-ad7f-3326c4f7e83c
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-jzjdd 17170a64-ba96-441a-8518-729cc44716fa
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-jzjdd 2f6fed39-d650-42cf-a358-8a004d975081
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-jzjdd 73be787c-5335-484a-a9bb-13c5b0acedc2
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-jzjdd 79dd8d3c-b7c4-494c-a2bb-4ebdf8f1cf20
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-jzjdd e58776b1-6af9-4096-a601-ada2adfb279e
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-jzjdd 92392596-c714-4740-a80a-2e88c80f2594
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-jzjdd 575dbdf6-b75c-4354-90f5-ffecb67537d6
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-jzjdd 4e784d16-707a-4370-bb33-7a8565efe82c
Processed a total of 10 messages
ns:kafka-mirror topic:my-source-cluster.blogs partion:2 messages:[1565938:1565948]
==========================================================================
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-x6wbp 66275f06-07ab-41d4-91ec-d07abf9dba1e
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-x6wbp f4fd03b4-7fcd-4171-bcff-8ff30123bb82
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-x6wbp 93b109ba-6ea1-41ee-86ad-ecc23a4bf8dc
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-x6wbp a5d8878c-5836-4e17-9202-0dace98aca46
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-x6wbp 3cd5d1d7-2a33-4dab-8ba7-c5d2f7708666
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-x6wbp 9c02da2b-b32a-4923-b38a-1a0681f62070
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-x6wbp 6b3ec8b7-cdd5-4ae9-a988-9e940d990f95
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-x6wbp 9312dd31-4c18-4ccf-8e6e-1eafa60631e7
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-x6wbp 5147d0e6-51be-449a-a63d-e04104dbfa2a
Wed Jun 23 14:12:46 UTC 2021 -- blogs-f5d8f5d58-x6wbp f5467d1a-5f39-4145-9d15-f39eea8b9aaf
```

We can see that the date are evenly distibuted between partitions.

### Assumption 2 on the head of the restored topic 

After restore we can see that the head of the partitions are in the situation that we described 
check the differences between the dates to confirm it. 
```
./read_last_10_messages.sh kafka blogs                         
ns:kafka topic:blogs partion:0 messages:[1233036:1233046]
==========================================================================
Wed Jun 23 14:24:34 UTC 2021 -- blogs-f5d8f5d58-4xqhs 64460c73-1501-4529-9d05-5693e1b6793c
Wed Jun 23 14:24:34 UTC 2021 -- blogs-f5d8f5d58-4xqhs 289e6be4-5419-4d42-9954-96d31aff9f8a
Wed Jun 23 14:24:34 UTC 2021 -- blogs-f5d8f5d58-4xqhs d7997ff6-fa97-4359-af94-30ac0e50e6a3
Wed Jun 23 14:24:34 UTC 2021 -- blogs-f5d8f5d58-4xqhs 5d11def4-e053-4dc9-9578-4fae70255562
Wed Jun 23 14:24:34 UTC 2021 -- blogs-f5d8f5d58-4xqhs 14bda69d-f8a8-4a56-b534-1cd837cdbafd
Wed Jun 23 14:24:34 UTC 2021 -- blogs-f5d8f5d58-4xqhs 33cc9c90-5001-4e62-b66d-5560fb3a0676
Wed Jun 23 14:24:34 UTC 2021 -- blogs-f5d8f5d58-4xqhs 9255fcfc-52d0-427f-8cce-a8fd6bc63444
Wed Jun 23 14:24:34 UTC 2021 -- blogs-f5d8f5d58-4xqhs cdeb1c7b-c17d-4084-bb16-119c421380ca
Wed Jun 23 14:24:34 UTC 2021 -- blogs-f5d8f5d58-4xqhs c237112e-dd0c-4533-ae8d-0ec806c8087a
Wed Jun 23 14:24:34 UTC 2021 -- blogs-f5d8f5d58-4xqhs ec5eb069-44bc-49c6-b39b-9cf4c2855a9c
Processed a total of 10 messages
ns:kafka topic:blogs partion:1 messages:[1224663:1224673]
==========================================================================
Wed Jun 23 14:24:35 UTC 2021 -- blogs-f5d8f5d58-cd9zz 46a40da8-7dd8-4f81-91b7-a27532d5afec
Wed Jun 23 14:24:35 UTC 2021 -- blogs-f5d8f5d58-cd9zz ff454e53-d50d-4c4a-9cd3-1009563265d7
Wed Jun 23 14:24:35 UTC 2021 -- blogs-f5d8f5d58-cd9zz a65f42a3-b028-48d2-bf55-8b1bf738a109
Wed Jun 23 14:24:35 UTC 2021 -- blogs-f5d8f5d58-cd9zz d35e3e1e-54aa-4176-b69b-757e4bf101f2
Wed Jun 23 14:24:35 UTC 2021 -- blogs-f5d8f5d58-cd9zz 56b82828-053a-4493-b481-f6604fc0c500
Wed Jun 23 14:24:35 UTC 2021 -- blogs-f5d8f5d58-cd9zz f71bb202-2f1e-4275-b63d-6f65ef663528
Wed Jun 23 14:24:35 UTC 2021 -- blogs-f5d8f5d58-cd9zz d5febdcb-2fa0-448f-a8ac-8a83d975bf65
Wed Jun 23 14:24:35 UTC 2021 -- blogs-f5d8f5d58-cd9zz 9a190fcf-44cc-4557-970c-7d96dcba0461
Wed Jun 23 14:24:35 UTC 2021 -- blogs-f5d8f5d58-cd9zz 084c82dd-f330-4af9-8e18-6de27f883c31
Wed Jun 23 14:24:35 UTC 2021 -- blogs-f5d8f5d58-cd9zz e009d4cc-235d-4e24-a477-95d0822b603a
Processed a total of 10 messages
ns:kafka topic:blogs partion:2 messages:[1250695:1250705]
==========================================================================
Wed Jun 23 14:24:55 UTC 2021 -- blogs-f5d8f5d58-cd9zz e1ca1daf-3e1f-431b-8c4a-6f18f406cbe1
Wed Jun 23 14:24:55 UTC 2021 -- blogs-f5d8f5d58-cd9zz 30dbe977-f1e5-4d1e-b802-6f9d4ea7e352
Wed Jun 23 14:24:55 UTC 2021 -- blogs-f5d8f5d58-cd9zz 05a2d6cc-5a4a-4e18-a2e7-b66dcb80828b
Wed Jun 23 14:24:55 UTC 2021 -- blogs-f5d8f5d58-cd9zz 047b734d-3635-4435-bd96-d14916181b48
Wed Jun 23 14:24:55 UTC 2021 -- blogs-f5d8f5d58-cd9zz b361efa3-f8ea-4503-8451-a6c5d374b357
Wed Jun 23 14:24:55 UTC 2021 -- blogs-f5d8f5d58-cd9zz 64cba2e2-d7fd-4a09-a2d1-bb7296a92c80
Wed Jun 23 14:24:55 UTC 2021 -- blogs-f5d8f5d58-cd9zz d394af70-962b-4c0f-93e5-7095a91cff55
Wed Jun 23 14:24:55 UTC 2021 -- blogs-f5d8f5d58-cd9zz 2792bf75-5b31-419d-b4e3-a7aa1564072a
Wed Jun 23 14:24:55 UTC 2021 -- blogs-f5d8f5d58-cd9zz 91d4d2a7-1fec-4af1-8d19-04fbe065e0db
Wed Jun 23 14:24:55 UTC 2021 -- blogs-f5d8f5d58-cd9zz 0f309420-12b7-472f-8e87-63ce600dfa1c
Processed a total of 10 messages
```

We have difference up to 20 seconds between partitions, that verify that the head of the 
partitions are not evenly distributed when restored.

### Assumption on the tail of the restored topic 

Here I can use the kafka-mirror cluster to compare the biggest common tail between partitions : 

```
ns:kafka topic:blogs partion:0 messages:[1233036:1233046]
ns:kafka topic:blogs partion:1 messages:[1224663:1224673]
ns:kafka topic:blogs partion:2 messages:[1250695:1250705]
```

The biggest common tail is given by the partion that have the smallest offset : 1224663

And to make this comparison we have this simple tool `compare_topic.sh <topic> <num_partition> <max-messages> [starting_offset]`
```
kafka % bash compare_topic.sh blogs 2 1224663                  
===========================================================
Comparing topic blogs between kafka and kafka-mirror
Comparing from --from-beginning a number of 1224663 messages
On 2 partitions
===========================================================
Checking on kafka
Processed a total of 1224663 messages
Checking on kafka-mirror
Processed a total of 1224663 messages
Comparing md5 file between
  /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.cSnXy4p5/kafka_0
  /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.cSnXy4p5/kafka-mirror_0
topic blogs partition 0 are equals between --from-beginning on 1224663 messages on both clusters
---------------------------------------------------------------------------------------------------------------------
Checking on kafka
Processed a total of 1224663 messages
Checking on kafka-mirror
Processed a total of 1224663 messages
Comparing md5 file between
  /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.cSnXy4p5/kafka_1
  /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.cSnXy4p5/kafka-mirror_1
topic blogs partition 1 are equals between --from-beginning on 1224663 messages on both clusters
---------------------------------------------------------------------------------------------------------------------
Checking on kafka
Processed a total of 1224663 messages
Checking on kafka-mirror
Processed a total of 1224663 messages
Comparing md5 file between
  /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.cSnXy4p5/kafka_2
  /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.cSnXy4p5/kafka-mirror_2
topic blogs partition 2 are equals between --from-beginning on 1224663 messages on both clusters
---------------------------------------------------------------------------------------------------------------------
Topic blogs are completly equals from --from-beginning on 1224663 messages on all the partitions
cleaning temporary directory /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.cSnXy4p5
```

The conclusion of the test `Topic blogs are completly equals from --from-beginning on 1224663 messages on all the partitions`
show that the biggest common tail has been restored with no segment loss.

We get exactly the same result on the items that have 10 partitions instead of 3. 