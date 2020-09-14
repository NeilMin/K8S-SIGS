#!/bin/bash

kubectl -n sigs exec -i prod-oozie-0 -- bash -c 'cd $OOZIE_HOME && bin/oozie-setup.sh sharelib create -fs ${CORE_CONF_fs_defaultFS}'
