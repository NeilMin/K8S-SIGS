#!/bin/bash

kubectl -n sigs exec -i prod-meta-mysql-0 -- mysql -ppassword < metastore-setup.sql
echo '/entrypoint.sh && cd $HIVE_HOME && bin/schematool -dbType mysql -initSchema' | kubectl -n sigs exec -i prod-hive-hiveserver2-0 -- bash
