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
echo "yes" | redis-cli --cluster create \
  10.207.248.53:7001 \
  10.207.248.53:7002 \
  10.207.248.53:7003 \
  10.207.248.53:7004 \
  10.207.248.53:7005 \
  10.207.248.53:7006 \
  --cluster-replicas 1
echo "🚀 Redis cluster ready."