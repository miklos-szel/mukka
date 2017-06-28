#!/bin/bash
if [ $#  -lt 1 ]; then
		echo "usage $0 ip-address(es)"
		echo "example: $0 10.77.5.152 10.77.5.109"
                exit 1
fi
host_watchlist=$*
echo "running continously and killing all queries on hosts: $host_watchlist where there is at least one thread in  'Waiting for table metadata lock' state"

echo -n "Do you really want to run this(NO/yes)?"
read confirm

if [ "$confirm" != "yes" ]
then
       	echo "answer wasn't 'yes', quit!"
       	exit 2
fi


while [ "1"  ]
do
	for host in $host_watchlist
	do
		num_locks=$(mysql -h $host -u root -e "SELECT count(*) FROM information_schema.PROCESSLIST WHERE STATE='Waiting for table metadata lock'" information_schema -NB)
		echo -e "host: $host, num_locks: $num_locks"
			if [ "$num_locks" -gt "0" ]
			then
				echo "killing all nylas-proxysql queries on host: $host "
				echo "Num_locks: $num_locks"
				#kill them:
				for i in `mysql -h $host -u root -e "SELECT trx_mysql_thread_id FROM INNODB_TRX JOIN PROCESSLIST ON trx_mysql_thread_id=PROCESSLIST.ID WHERE user='nylas_proxysql' " information_schema -NB` ; do echo "KILL $i;" ; done | mysql -h $host -u root -f
	        		fi

	done
sleep 0.5
echo "--"
done
