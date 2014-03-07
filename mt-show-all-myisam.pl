#!/usr/bin/perl

use strict;
my $hostname=`hostname`;
my $mysql_user='root';
my $mysql_passwd="";
my $mysql_host='localhost';
my $mysql_port='3306';
chomp($hostname);
my $sql=<<END;
SELECT Concat('ALTER TABLE ', table_schema, '.', table_name, ' engine=INNODB;')
       AS
       '===== MyISAM Tables without FULLTEXT indexes ====='
FROM   information_schema.tables
WHERE  engine = 'MyISAM'
       AND table_schema <> 'mysql'
       AND table_schema <> 'information_schema'
       AND Concat(table_schema, '.', table_name) NOT IN
           (SELECT
           Concat(table_schema, '.', table_name)
                                                         FROM
               information_schema.statistics
                                                         WHERE
           index_type = 'fulltext');

SELECT Concat(table_schema, '.', table_name) AS
       '===== MyISAM Tables with FULLTEXT indexes ====='
FROM   information_schema.tables
WHERE  engine = 'MyISAM'
       AND table_schema <> 'mysql'
       AND table_schema <> 'information_schema'
       AND Concat(table_schema, '.', table_name) IN (SELECT
           Concat(table_schema, '.', table_name)
                                                     FROM
           information_schema.statistics
                                                     WHERE
           index_type = 'fulltext');
END

system ("mysql --user $mysql_user --password=\"$mysql_passwd\" --host $mysql_host --port  $mysql_port  -A -B -e\"$sql\" ");
