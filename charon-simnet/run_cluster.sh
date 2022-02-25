#!/bin/sh
trap "exit" INT TERM ERR
trap "kill 0" EXIT

 node0/run.sh &
 node1/run.sh &
 node2/run.sh &
 node3/run.sh


wait