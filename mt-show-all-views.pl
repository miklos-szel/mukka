#!/usr/bin/perl

use strict;
my $hostname=`hostname`;
my $mysql_user='root';
my $mysql_passwd="";
my $mysql_host='localhost';
my $mysql_port='3306';
chomp($hostname);

my @list_of_views=`mysql --user $mysql_user --password="$mysql_passwd" --host $mysql_host --port  $mysql_port -B -A --skip-column-names -e"SELECT CONCAT(table_schema,'.',table_name) FROM information_schema.tables WHERE engine IS NULL"`;
print "\nList of all views on '$hostname':\n\n";
print @list_of_views;

foreach my $view (@list_of_views){
    chomp($view);
    print "\n\nSHOW CREATE VIEW $view;\n";
    system("mysql --user $mysql_user --password=\"$mysql_passwd\" --host $mysql_host --port  $mysql_port -e 'SHOW CREATE VIEW '$view' \\G' ");
}
