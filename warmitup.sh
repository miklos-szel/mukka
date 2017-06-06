#!/bin/bash
from_ip=$1
to_ip=$2

db_user="rdsops"
db_pass=""
user="root"
ret=$(mysql -h $from_ip --user=$db_user -p${db_pass} -e "SET GLOBAL innodb_buffer_pool_dump_now=ON;select sleep(5);SHOW STATUS LIKE 'Innodb_buffer_pool_dump_status';")
if [ $# -ne 2 ]
then
    echo "Dump buffer pool from remote machine and load it to another isntance"
    echo "usage $0 from_ip to_ip"
fi
if [ "$(echo $ret |grep -c 'dump completed' )" == "1" ]
then
    echo "1. Buffer Pool Dump completed on $from_ip"
else
    echo "Failed to dump buffer_pool on $from_ip"
    exit 1
fi

datadir=$(mysql -NB  -h $from_ip --user=$db_user -p${db_pass} -e "SELECT @@datadir;")
echo "2. Transferring buffer_pool from $from_ip to $to_ip"
echo $datadir
scp -o StrictHostKeyChecking=no  -o UserKnownHostsFile=/dev/null $user@$from_ip:$datadir/ib_buffer_pool $user@$to_ip:$datadir/ib_buffer_pool
ssh -o StrictHostKeyChecking=no $user@$to_ip chown mysql:mysql $datadir/ib_buffer_pool

if [ $? -ne 0 ]
then
    echo "Failed to transfer the buffer_pool file from $ip"
fi
echo "3. Load buffer pool to $to_ip[this can take a long while]"
ret=$(mysql -h $to_ip --user=$db_user -p${db_pass} -e "SET GLOBAL innodb_buffer_pool_load_now=ON;select sleep(5);SHOW STATUS LIKE 'Innodb_buffer_pool_load_status';")
echo $ret
