[root@prod-mysql-ansible3-i-a61bfdaa no_pk]# cat no_pk.sh
#!/bin/bash
MYSQLUSER="root"
MYSQLPASS=""
SQL="select tbl.table_schema, tbl.table_name, round( (INDEX_LENGTH+INDEX_LENGTH) /1024/1024) as Full_Size, TABLE_ROWS from information_schema.tables tbl left join key_column_usage kcu ON (tbl.table_schema = kcu.table_schema and tbl.table_name = kcu.table_name and kcu.constraint_name = 'PRIMARY') where kcu.constraint_name is null and tbl.table_schema not in ('information_schema', 'performance_schema', 'mysql') and table_comment <> 'VIEW' and tbl.engine = 'InnoDB';"
for CLUSTER in `cat clusters`
do
echo $CLUSTER
mysql  --host $CLUSTER  -u $MYSQLUSER -p$MYSQLPASS information_schema -e "${SQL}"

done
