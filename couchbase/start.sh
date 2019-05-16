#!/bin/bash

set -m 
#Starting couchbase server and sleeping for 60sec.
/entrypoint.sh couchbase-server &

sleep 60

echo "Cluster Init"

couchbase-cli cluster-init --cluster-username Administrator \
 --cluster-password password --cluster-ramsize 1024

echo "Creating  a new user spp"
#Creating a new user spp
couchbase-cli user-manage -c localhost:8091 -u Administrator \
 -p password --set --rbac-username spp --rbac-password password \
 --rbac-name "spp" --roles admin \
 --auth-domain local

echo "Creating a new bucket spp"
#Creating the spp bucket
couchbase-cli bucket-create -c localhost:8091 -u spp -p password --bucket spp --bucket-type couchbase \
   --bucket-ramsize 100 --bucket-replica 1
tail -f /opt/couchbase/var/lib/couchbase/logs/couchdb.log
