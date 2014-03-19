#!/usr/bin/perl
use strict;
use Data::Dumper;

my $mysql_output = $ARGV[0];
my $rds_output = $ARGV[1];
if ( ($mysql_output eq "") or ($rds_output eq "") ){
    print <<EOF;
The script will print the difference between the settings of the currently running MySQL instance and the Parameter Group config. It's useful when the RDS instance in Paramter Group(Pending Reboot) but you don't know what Paramter Group options have changed. 

Save MySQL config from the RDS instances with:
mysql --batch --skip-column-names -h rds_hostname -u username -p -e "show global variables" >rds_mysql_config

Save RDS Parameter Group settings:
rds-describe-db-parameters [--region rds_region] --db-parameter-group-name param_group_name --source user --show-long --delimiter '#' >rds_pg_config

EXAMPLE:
$0 rds_mysql_config rds_pg_config  

EOF
exit 1;
}
my $mysql = {};
my $rds = {};

open FILE1, $mysql_output or die;

while (my $line=<FILE1>) {
   chomp($line);
   (my $word1,my $word2) = split /\t/, $line;
   $mysql->{$word1} = $word2;
}
close FILE1;

printf "%-35s %-32s %-32s\n", "Setting name","MySQL value", "RDS Parameter Group value";

open RDS, $rds_output or die;
while (my $rds_line=<RDS>) {
    chomp($rds_line);
    ##print $rds_line,"\n";
    my @fields = split(/#/, $rds_line);
    $fields[2] = "ON" if $fields[2] eq "1" and $fields[5] ne "float";
    $fields[2] = "OFF" if $fields[2] eq "0" and $fields[5] ne "float";

    if ($mysql->{$fields[1]} ne $fields[2]) {
        printf "%-35s %-32s %-32s\n", $fields[1],$mysql->{$fields[1]},$fields[2];
    }

}
close RDS;
