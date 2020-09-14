#!/bin/bash

kubectl -n sigs exec -i prod-meta-mysql-0 -- mysql -ppassword < ooziedb-setup.sql