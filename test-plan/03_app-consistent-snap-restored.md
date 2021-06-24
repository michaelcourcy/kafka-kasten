
# Kafka blueprint 

video kafka-blueprint.mp4

## Situation

We want to run the backup on the mirror not on the source itself. 
But we are able to perform operation that can't be done on the source
like : 
*   Stop all productions before backup 
*   call sync to flush all file to the disk 
*   Stop the brokers and zookeepers before snapshot

All this operations are performed by the [scale-down-up-kafka-bp.yaml](../scale-down-up-kafka-bp.yaml) 
blueprint put on the kafka brokers statefulset and [scale-down-up-bp.yaml](../scale-down-up-bp.yaml) 
blueprint put on the zookeeper statefulset.

## Assumption 1 : that mirror maker support interruption

Mirror maker will be able to restart where it was when 
it was interrupted. Mirror maker keep it's state in the source cluster 
on the mm2-offset-syncs.my-target-cluster.internal topic.

## Assumption 2 : the restored backup will have its head partition evenly distributed

Because we stop mirror maker in a single instant and call `sync` on all 
the partition's node head will be evenly distributed.


## How do I check  assumptions 1 and 2  

### Assumption 1 :  mirror maker support interruption 

Run a backup on kafka mirror that will stop mirror maker for the time 
of the backup then stop the producer.

```
oc -n kafka scale deployment blogs --replicas=0
oc -n kafka scale deployment items --replicas=0
```

Once all the producers are stopped wait few seconds to make sure mirror maker
has copied everything back to the target cluster. 

And launch the comparison script on the offset of the smallest partition 

```
./read_last_10_messages.sh kafka-mirror my-source-cluster.blogs
ns:kafka-mirror topic:my-source-cluster.blogs partion:0 messages:[4486522:4486532]
==========================================================================
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-nbw77 47e41943-c634-4194-98ce-0535d75f5b2c
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-nbw77 ca13c5c5-ccf3-4535-afba-4104797f59c7
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-nbw77 f8206125-9ab9-4fe0-b677-4448d816b5f8
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-nbw77 493c852b-a2aa-4a5a-9484-75d042121586
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-nbw77 2d641f93-4fc7-4e80-a9c2-cd6470fad159
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-nbw77 b1186990-4faa-450d-b484-c732f34b21e1
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-nbw77 33aa5843-aa44-4c34-b47a-bd62870fbe46
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-nbw77 28706423-e3f7-4590-8b2c-6adbce26430d
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-nbw77 ed75457b-9f9d-4f64-a126-8ce9c8e66dd0
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-nbw77 ee5894c8-1583-490e-a246-580c62b66be6
Processed a total of 10 messages
ns:kafka-mirror topic:my-source-cluster.blogs partion:1 messages:[4481822:4481832]
==========================================================================
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-d225g f353bc4f-2602-4340-b3bc-c4150b96b0e7
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-d225g 64e5e5dc-d545-47ca-bbe2-798de83db725
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-d225g 281d4409-6f04-4d44-9860-f53174959c96
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-d225g a991d247-18b1-4ee8-8a5e-04fedd38c4fc
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-d225g e4085535-8cc7-4459-8c99-3facacbf271d
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-d225g 1614f1ae-be51-4e95-98b3-1e5c5f961e57
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-d225g 9a0b59e8-2dd0-4f1d-a3c9-29b2fb50482e
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-d225g 6f4f60fb-fcac-4e8b-a8a1-e4cfbe4706c3
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-d225g 23e5c46a-4df4-45ac-aa71-644f04cdc372
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-d225g 93e53038-7652-423f-9121-70221566beb7
Processed a total of 10 messages
ns:kafka-mirror topic:my-source-cluster.blogs partion:2 messages:[4468902:4468912]
==========================================================================
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-862gj 373b9f50-f3db-4a28-b682-b845fb2c7e97
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-862gj 95ba075d-2070-433a-8d78-ac7164f36a25
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-862gj ed92fdd8-6748-4e30-8eed-0b962ef1cce7
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-862gj ef00e65e-9e10-492f-b992-715cfac947d0
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-862gj 3f64f6ca-b6fc-47df-a452-c726c1e90df2
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-862gj 924d087b-387b-468d-a818-c4f97928fc20
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-862gj a7f881e5-634a-4814-a420-4b01c81ee752
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-862gj 0731acc6-c1ed-4ba9-b3df-537f22c472c4
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-862gj b4b21bae-5c28-4ce7-b4f1-73897d44fab2
Thu Jun 24 13:25:27 UTC 2021 -- blogs-f5d8f5d58-862gj 322e8803-7234-450d-b4b7-3b04bd3479da
```

here the smallest partition is 4.468.912 (4,5 millions messages) 

```
bash compare_topic.sh blogs 2 4468912   
===========================================================
Comparing topic blogs between kafka and kafka-mirror
Comparing from --from-beginning a number of 4468912 messages
On 2 partitions
===========================================================
Checking on kafka
Processed a total of 4468912 messages
Checking on kafka-mirror
Processed a total of 4468912 messages
Comparing md5 file between
  /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.DDVZQ63K/kafka_0
  /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.DDVZQ63K/kafka-mirror_0
topic blogs partition 0 are equals between --from-beginning on 4468912 messages on both clusters
---------------------------------------------------------------------------------------------------------------------
Checking on kafka
Processed a total of 4468912 messages
Checking on kafka-mirror
Processed a total of 4468912 messages
Comparing md5 file between
  /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.DDVZQ63K/kafka_1
  /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.DDVZQ63K/kafka-mirror_1
topic blogs partition 1 are equals between --from-beginning on 4468912 messages on both clusters
---------------------------------------------------------------------------------------------------------------------
Checking on kafka
Processed a total of 4468912 messages
Checking on kafka-mirror
Processed a total of 4468912 messages
Comparing md5 file between
  /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.DDVZQ63K/kafka_2
  /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.DDVZQ63K/kafka-mirror_2
topic blogs partition 2 are equals between --from-beginning on 4468912 messages on both clusters
---------------------------------------------------------------------------------------------------------------------
Topic blogs are completly equals from --from-beginning on 4468912 messages on all the partitions
cleaning temporary directory /var/folders/tj/0gvsp6p575939s_7kc81cpsm0000gn/T/tmp.DDVZQ63K
```

### Assumption 2 : the restored backup will have its head partition evenly distributed

Producers are already stopped stop mirror maker as well 

```
oc -n kafka-mirror scale deployment my-mirror-maker-mirrormaker2 --replicas=0
```

Restore the namespace and chech the head of the topic

```
./read_last_10_messages.sh kafka-mirror my-source-cluster.blogs
ns:kafka-mirror topic:my-source-cluster.blogs partion:0 messages:[767316:767326]
==========================================================================
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-c9l78 df81eaa4-31e1-44cd-a401-2ebd9e1753e5
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-c9l78 fb9a0c05-e480-47ac-bb8c-e48c3726fff8
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-c9l78 5c4d98ba-011e-4133-95c4-6ad84a47ddeb
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-c9l78 64bfa256-6da7-4f75-a9ea-b88b8a471aa1
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-c9l78 eb87fa8a-9c25-4bae-b94d-f39eeba599ca
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-c9l78 8bf98f35-5d50-4853-8fd7-f3a692963700
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-c9l78 c91dfd2b-4172-427e-88d3-1328b9793e2e
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-c9l78 1468eaae-afae-4f4a-906f-896ddbed8a2b
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-c9l78 b6f627c6-5d8b-42a4-8845-8326de43bea9
Processed a total of 10 messages
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-c9l78 1407a981-1349-4366-8eba-6b4fa360ce22
ns:kafka-mirror topic:my-source-cluster.blogs partion:1 messages:[776325:776335]
==========================================================================
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-d4g88 845ab8c5-d190-4b61-b5dc-214b546ea9d6
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-d4g88 7164613d-0845-4f01-ae34-4a8b0e1e8909
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-d4g88 5b7dea77-7671-4627-a47d-5c3268c965c6
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-d4g88 3d3bd033-093e-4b7f-92c7-08c31adb944f
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-d4g88 c38ba860-71cd-4a1c-9c6d-197e18930b2c
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-d4g88 aa02aa78-b10b-4a70-b83d-7d9ea3893768
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-d4g88 6d9a5318-8c2b-411e-b77f-1954ad9b535f
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-d4g88 e5334adc-ea2a-40d8-acce-d316f2b7705c
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-d4g88 b80db8d5-c54e-48e3-85ff-7dd7ec338ef1
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-d4g88 e4e8c01f-3b63-4572-ae87-cfe14e326bd4
Processed a total of 10 messages
ns:kafka-mirror topic:my-source-cluster.blogs partion:2 messages:[781804:781814]
==========================================================================
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-5fmjd 474d39c2-0e1e-41d9-8404-1537cdda1970
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-5fmjd e3dc06e1-6dcb-491c-b0de-1d7dbb44d0dc
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-5fmjd 27ed02a4-a4a3-4060-a7bf-073ea4947643
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-5fmjd 80c63b4a-739a-4675-b846-353f0d35f65f
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-5fmjd 18a541cd-3a39-45a8-b311-20f61a10d72a
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-5fmjd 1322427f-f6f9-408f-b78a-641913ef9e0d
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-5fmjd 5109343b-8381-4860-8eab-2a0f18332dae
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-5fmjd 52e8478c-8385-4310-a0d4-f85de0df4980
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-5fmjd 20899813-da7b-40be-af51-3122b4c22572
Thu Jun 24 17:22:31 UTC 2021 -- blogs-f5d8f5d58-5fmjd 9004ff85-46b1-4148-8603-a063a8e67d9f
Processed a total of 10 messages


./read_last_10_messages.sh kafka-mirror my-source-cluster.items
ns:kafka-mirror topic:my-source-cluster.items partion:0 messages:[231824:231834]
==========================================================================
Thu Jun 24 17:22:30 UTC 2021 -- items-58cd7c4564-79gd9 5b79aca3-3f16-4211-9a93-43dea1939c93
Thu Jun 24 17:22:30 UTC 2021 -- items-58cd7c4564-79gd9 1cdf469d-f0f8-4537-9fba-2928cb7152b7
Thu Jun 24 17:22:30 UTC 2021 -- items-58cd7c4564-79gd9 15fe24c4-8a91-45cc-9e70-1908ed46c093
Thu Jun 24 17:22:30 UTC 2021 -- items-58cd7c4564-79gd9 1cf47694-84e8-4f7c-ad85-4d75818bd8f1
Thu Jun 24 17:22:30 UTC 2021 -- items-58cd7c4564-79gd9 72050504-4f92-4915-b185-086c2670bc2f
Thu Jun 24 17:22:30 UTC 2021 -- items-58cd7c4564-79gd9 810226fe-0fec-4e5a-a183-20afd9a6fa9b
Thu Jun 24 17:22:30 UTC 2021 -- items-58cd7c4564-79gd9 c1789e5e-6fe2-499f-a5c9-260d231171c2
Thu Jun 24 17:22:30 UTC 2021 -- items-58cd7c4564-79gd9 21b8cf3d-6d8a-4625-ae84-a7fc60adfd22
Thu Jun 24 17:22:30 UTC 2021 -- items-58cd7c4564-79gd9 0681f8db-ae4a-47ea-9b43-2c9520ed9708
Thu Jun 24 17:22:30 UTC 2021 -- items-58cd7c4564-79gd9 a899df6e-0736-4ff8-9bdd-e65eb8161e93
Processed a total of 10 messages
ns:kafka-mirror topic:my-source-cluster.items partion:1 messages:[222074:222084]
==========================================================================
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bwq22 168fcbc1-3763-4530-9560-f11ddddad2eb
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bwq22 eb58ff85-1718-41e7-b844-041c999da934
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bwq22 6523b401-fe37-4f25-b355-cf8360edb5bb
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bwq22 e37b1e60-9614-44b7-8ad7-948e3ac5a416
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bwq22 ad6e7273-804f-43ee-9b5e-fb034587e339
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bwq22 7d480d64-b683-408c-bc9f-2156aed756bc
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bwq22 fe93161e-a9ef-4aca-a16d-0b91a20f166c
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bwq22 e828e0a9-d549-44c5-af5a-737ae83c44dc
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bwq22 dea8fcde-62e9-467c-871d-0921821d0d2b
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bwq22 e17fce37-b224-4a11-8165-af2d21a0a96d
Processed a total of 10 messages
ns:kafka-mirror topic:my-source-cluster.items partion:2 messages:[230722:230732]
==========================================================================
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-h69mx 69102ab1-9bc4-490d-b257-10e11f69def2
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-h69mx 9046313f-ec84-4674-8585-7755a6ca98e3
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-h69mx 436ac56c-444d-4c80-87e2-cb871c7da917
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-h69mx 86ecf5fe-d90a-46c0-9e47-f914e4fcc289
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-h69mx da42cd66-00f2-4ca0-ab81-77bfb9b200ab
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-h69mx 11fd5d87-9032-4332-ba4a-ac3e14a99f37
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-h69mx 9b42c9f2-7bb1-4f72-acb5-c8cd29337c5c
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-h69mx 45d5a413-fe3a-4762-b4cb-33b3db007b24
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-h69mx 13c3a5ea-f34c-4e22-b722-4a2644fdfd97
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-h69mx aa7b72e2-5882-4fad-b505-34e650629eb0
Processed a total of 10 messages
ns:kafka-mirror topic:my-source-cluster.items partion:3 messages:[227522:227532]
==========================================================================
Processed a total of 10 messages
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-79gd9 1c57d96e-6c8d-4010-916d-fff9d15807a5
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-79gd9 0a9a31a1-4756-4f7e-a575-25001170fa91
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-79gd9 e2cd0b42-a139-4329-8822-7c79c56ef64a
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-79gd9 aad751d3-b87f-4195-808d-da1a1dcb651b
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-79gd9 2928e9a6-a6ec-4ac5-9980-acf9425dfa1b
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-79gd9 c9e27648-d8c6-4f45-9908-64f25ea84beb
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-79gd9 c37042e0-2766-4ac1-a53e-68df4e77785a
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-79gd9 ab8d9f87-78ff-4433-8506-99558d90dcee
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-79gd9 0ca03306-52c4-45a9-af3f-1930cb8a28a0
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-79gd9 7c3cd0aa-77ba-4fed-91cb-38bbd0c9a9e2
ns:kafka-mirror topic:my-source-cluster.items partion:4 messages:[251300:251310]
==========================================================================
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-lxqp2 bad8fe60-fb82-4dc2-bce9-e586df8230c9
Processed a total of 10 messages
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-lxqp2 95b897c2-581a-411c-817a-6be00b770239
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-lxqp2 17b9bd70-3c4b-4af9-80c4-7f60532e4aa2
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-lxqp2 78b39e9f-8bb0-4a8d-bc3a-f759c17d8899
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-lxqp2 65dfd494-5b48-4b79-816d-e689f2efdf88
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-lxqp2 52524560-a648-4ee5-80c0-3a203bc81520
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-lxqp2 defb5f8d-1642-4ab9-b45b-d7c79ec542b8
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-lxqp2 5c37748c-7219-465b-8394-6f2d99a2f1ec
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-lxqp2 75a7deb1-21a3-46d5-ae0d-9cfc8545887a
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-lxqp2 f8ea42cf-3af3-43af-a718-df461373ed7a
ns:kafka-mirror topic:my-source-cluster.items partion:5 messages:[254742:254752]
==========================================================================
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-4m59m fd7afaa3-25fe-4fd9-bfb2-54dd04c8998b
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-4m59m f99c8ec9-92cd-4ce0-8eb1-2e1c144ea5f8
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-4m59m 7626a88b-f929-4393-b9fd-d6b9dbad7f71
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-4m59m abdb475f-72ff-489b-bedb-b11340ea632c
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-4m59m bf8c6742-6483-487f-9917-7fc0a4109471
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-4m59m e2da64a2-af34-4022-8536-1566c228dd47
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-4m59m 516f06b0-b03b-4c55-b6e0-436c03e60669
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-4m59m 7614c591-9310-4c7e-941f-165b73f0266a
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-4m59m 47b2c029-2188-41b7-82ef-67a31ed3d08e
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-4m59m 466df37b-d4fc-4fcf-8daa-ddf99a81173c
Processed a total of 10 messages
ns:kafka-mirror topic:my-source-cluster.items partion:6 messages:[226676:226686]
==========================================================================
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-9w8wj e19c28b7-dabd-4a70-a471-8d8474e73dea
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-9w8wj c2262ca9-faf3-4064-8ba9-76c9d9705f18
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-9w8wj 6837afe4-274c-4d50-add7-769f0c16cd35
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-9w8wj f4a1be67-2d47-4f98-9309-f011ae56e397
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-9w8wj ea3619d2-738e-4fc1-aa9d-e9b5b19fe0ef
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-9w8wj 8f6054db-381f-42d1-adcf-13c62d65b228
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-9w8wj f386bc59-c55a-425b-8216-4fe344d4748f
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-9w8wj 6995c169-ca42-463d-b918-9ad7e887b111
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-9w8wj 31bd9ece-3f43-4509-9f7a-1072dd8aece3
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-9w8wj 5bf279eb-a28f-4bf8-b779-8d62684466b3
Processed a total of 10 messages
ns:kafka-mirror topic:my-source-cluster.items partion:7 messages:[227969:227979]
==========================================================================
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-2h6rn 0ebfc7a0-ad4b-422d-8b13-88cf25f2720b
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-2h6rn 130a9c63-741d-4da0-8116-47ab0f9487d8
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-2h6rn 60c5011e-6830-4038-ab2a-0a2915a8b938
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-2h6rn a94afc64-d614-4e1d-9a01-2508cd9a1a55
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-2h6rn a7f58c30-b6c0-46a9-ae61-2142fd99488a
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-2h6rn 6f783f49-5d9b-4b9d-a990-3ace0db5df55
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-2h6rn e9c5c518-d602-4f59-aa1d-6a912e2525b4
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-2h6rn 71fe53b9-a6eb-441e-b6d9-89536d7a40a9
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-2h6rn 7c341a37-27a2-4741-80d3-074d6714b86c
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-2h6rn 782d0bc3-236c-4c34-89ec-9cfff8976001
Processed a total of 10 messages
ns:kafka-mirror topic:my-source-cluster.items partion:8 messages:[229227:229237]
==========================================================================
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bth9n eeb76215-42f7-41b7-a773-e14b401cd325
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bth9n 7198997a-c41e-4b9d-bf60-2af6d3218a62
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bth9n 67fa7516-e313-4ade-929e-e2b66db097a7
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bth9n 1b9e00ec-c777-4930-b6e8-b6b069aa007e
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bth9n 4b780cf6-e5f3-44bc-a881-8a3a6bd1d8d0
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bth9n da9803d3-6257-4635-9b93-7068b99372cf
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bth9n 918ab3d1-de6c-40d9-b2ba-bdfc4315ac01
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bth9n 6bedeeaa-2c72-4b14-81e2-f321fadbaac7
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bth9n 3f567469-f583-479a-8131-1446892c0982
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-bth9n d31b57d9-bae1-43f9-97e8-03a2efb51568
Processed a total of 10 messages
ns:kafka-mirror topic:my-source-cluster.items partion:9 messages:[232406:232416]
==========================================================================
Processed a total of 10 messages
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-cth77 58db2671-0898-4e6a-bab5-ef8832c7e9bb
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-cth77 f683f15e-0c15-463f-bb05-c3a77062750b
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-cth77 f2896047-1595-4a0a-a94b-2be91e6efd97
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-cth77 ea820f8e-79d3-4cad-8a2d-80cc318e8717
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-cth77 77e6ce52-2f90-45a7-a000-22bbd9875752
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-cth77 30c29170-502a-43ff-8afe-16f277f030f2
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-cth77 3aa7a5c8-7bf3-4633-b355-9116fc7191fe
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-cth77 4ced8f48-35b7-429a-a282-105c46ac6b39
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-cth77 3741720d-b853-4fb5-8f45-abfc4359a78d
Thu Jun 24 17:22:31 UTC 2021 -- items-58cd7c4564-cth77 4be675cd-2650-4498-8f03-93200222c7ac
```

In both blogs and items the date partitions are distributed evenly, there is no segment 
losses we did a clean PIT caapture of the data.