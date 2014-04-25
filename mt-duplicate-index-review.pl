#!/usr/bin/perl
use strict;
use Data::Dumper;
use Getopt::Long;
#innodb_stats_on_metadata=0
#http://www.mysqlperformanceblog.com/2011/12/23/solving-information_schema-slowness/

my $mysql_exe=`which mysql`;
#my $pt_dk="/home/vagrant/percona-toolkit-2.2.7/bin/pt-duplicate-key-checker";
my $pt_dk=`which pt-duplicate-key-checker`;
chomp($mysql_exe);
chomp($pt_dk);

my $mysql_user='root';
my $mysql_passwd="";
my $mysql_host='localhost';
my $mysql_port='3306';
#data size limit in mb
my $data_size_limit = 100;
#number of rows where we start using pt-osc
my $num_rows_limit = 500000;
my $execute=0;
my $report=0;
my $table;
my ($data_size,$index_size,$num_rows);

GetOptions ("user=s"                   => \$mysql_user,
            "password=s"               => \$mysql_passwd,
            "host=s"                   => \$mysql_host,
            "port=i"                   => \$mysql_port,
            "data\-size\-limit=i"      => \$data_size_limit,
            "num\-rows\-limit=i"       => \$num_rows_limit,
            "execute"                  => sub { $execute = 1 },
            "report"                  => sub { $report = 1 }
)
or die("Error in command line arguments\n");
if  ($execute == 0)  {
    print <<EOF;
The script *prints* the commands necessary to remove your duplicated indexes via ALTER TABLE or PT-OSC depending on the thresholds.

options:
--user              MySQL username [default: root]
--password          MySQL password [default: none]
--host              MySQL host     [default: localhost]
--port              MySQL port     [default: 3306]
--data-size-limit   if data+index size of the table exceeds this value in MB the script will advise using pt-online-schema-change [default:100]
--num-rows-limit    if table size exceeds this value the script will advise using pt-online-schema-change [default:500000]
--execute           without this the script only print this help screen
--report            instead of printing the commands it generate a csv available for making reports

IMPACT: It WON'T MAKE ANY CHANGES just print hints however accessing table statistics require opening the tables

example:
$0 --execute --user=review --passwd=xxx --host=127.0.0.1 --port=3336
EOF
exit 1;
}


my @dk_nc=`$pt_dk --no-cluster|grep ALTER`;
#my @dk_c=`$pt_dk --cluster|grep "ADD INDEX"`;
print "DB,TABLE,REDUNDANT INDEX NAME,TABLE DATA SIZE[MB],TABLE INDEX SIZE[MB],NUM ROWS,RECOMMENDED METHOD\n" if $report == 1;

foreach my $index (@dk_nc){
	if ($index =~ /^ALTER TABLE \`([\w]+?)\`\.\`([\w]+)\` DROP INDEX \`([\w]+)\`;$/i) {
		my ($curr_db,$curr_table,$curr_index)=($1,$2,$3);

		#get the status only once per table
        if ($2 ne $table){
		    ($data_size,$index_size,$num_rows) = &get_table_size($curr_db,$curr_table);
            $table = $2;
        }

	    if ( (($data_size+$index_size) >= $data_size_limit) or ($num_rows >= $num_rows_limit) ){
		print "$curr_db,$curr_table,$curr_index,$data_size,$index_size,$num_rows,PT-OSC\n";
	    }else{
			print "$curr_db,$curr_table,$curr_index,$data_size,$index_size,$num_rows,ALTER TABLE\n";
		}
    }
}

sub get_table_size{
	my $db 		= shift;
	my $table 	= shift;
	my $sql_size="SELECT  ROUND((  data_length  / ( 1024 * 1024 ) ),2), ROUND(( index_length / ( 1024 * 1024 ) ),2) ,table_rows FROM information_schema.tables WHERE table_schema='$db' and table_name ='$table'";
	my $size=`$mysql_exe --user $mysql_user --password=\"$mysql_passwd\" --host $mysql_host --port  $mysql_port --skip-column-names -e "$sql_size" `;
	chomp ($size);
	my ($data_size,$index_size,$num_rows) = split (/\t/, $size);
	return ($data_size,$index_size,$num_rows);
}
