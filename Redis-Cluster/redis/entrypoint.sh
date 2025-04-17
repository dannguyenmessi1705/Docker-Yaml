#!/bin/sh

# Using the redis-cli tool available as default in the Redis base image
# we need to create the cluster so they can coordinate with each other
# which key slots they need to hold per shard

# wait a little so we give some time for the Redis containers
# to spin up and be available on the network
sleep 5
# redis-cli doesn't support hostnames, we must match the
# container IP addresses from our docker-compose configuration.
# `--cluster-replicas 1` Will make sure that every master node will have its replica node
echo "yes" | redis-cli -a 17052002 --cluster create \
  192.168.1.12:7001 \
  192.168.1.12:7002 \
  192.168.1.12:7003 \
  192.168.1.12:7004 \
  192.168.1.12:7005 \
  192.168.1.12:7006 \
  --cluster-replicas 1
echo "🚀 Redis cluster ready."