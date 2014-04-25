#!/usr/bin/perl
use strict;
use Data::Dumper;
use Getopt::Long;
#innodb_stats_on_metadata=0
#http://www.mysqlperformanceblog.com/2011/12/23/solving-information_schema-slowness/

my $mysql_exe=`which mysql`;
chomp($mysql_exe);
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
my @ptosc;
my @alter;
my @fulltext;
my @report_ptosc;
my @report_ft;
my @report_alter;


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
The script *prints* the commands necessary to convert all of your MyISAM tables(except mysql,information_schema) to InnoDB. It lists all MyISAM tables with FULLTEXT indexes as well.

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
./mt-convert-all-myisam.pl --execute --user=review --passwd=xxx --host=127.0.0.1 --port=3336
EOF
exit 1;
}

my $table_stats_sql = <<END;
SELECT table_schema, 
       table_name, 
       table_rows, 
       ROUND( ( ( data_length + index_length ) / ( 1024 * 1024 ) ),2)
FROM   information_schema.tables 
WHERE  engine = 'MyISAM' 
       AND table_schema != 'information_schema' 
       AND table_schema != 'mysql' 
       AND Concat(table_schema, '.', table_name) NOT IN 
           (SELECT 
           Concat(table_schema, '.', table_name) 
                                                         FROM 
               information_schema.statistics 
                                                         WHERE 
           index_type = 'fulltext') 
ORDER BY data_length + index_length DESC;
END


my $myisam_fulltext_sql="
SELECT table_schema, table_name
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
";


my @table_stats_raw=`$mysql_exe --user $mysql_user --password=\"$mysql_passwd\" --host $mysql_host --port  $mysql_port --skip-column-names -e "$table_stats_sql" `;
foreach my $line (@table_stats_raw) {
    my ($db, $table, $num_rows, $data_size) = split(/\t/, $line);
    chomp ($db, $table, $num_rows, $data_size);
    if ( ($data_size >= $data_size_limit) or ($num_rows >= $num_rows_limit) ){
            #push @report, "$db,$table,$num_rows,$data_size,\"pt-online-schema-change  --dry-run --alter 'ENGINE=InnoDB' D=$db,t=$table,h=$mysql_host\"\n";
            push @report_ptosc, "$db,$table,$num_rows,$data_size,PT-OSC\n";
            push @ptosc, "#Table size: $data_size [limit: $data_size_limit]\n#Number of rows: $num_rows [limit:$num_rows_limit]\n#using pt-osc is recommended\n";
            push @ptosc, "pt-online-schema-change  --execute --alter 'ENGINE=InnoDB' D=$db,t=$table,h=$mysql_host\n\n";
           }
    else{
           push @report_alter, "$db,$table,$num_rows,$data_size,ALTER\n";
           push @alter, "ALTER TABLE $db.$table ENGINE=InnoDB;\n";
    } 
}

my @fulltext_tables=`$mysql_exe --user $mysql_user --password=\"$mysql_passwd\" --host $mysql_host --port  $mysql_port --skip-column-names -e "$myisam_fulltext_sql" `;
push @fulltext, "\n###Tables with FULLTEXT INDEXES";
push @report_ft, "---,---,---,---,---\n";
foreach my $line (@fulltext_tables) {
    my ($db, $table) = split(/\t/, $line);
    chomp($db,$table);
    push @fulltext, "# $db.$table\n";
    push @report_ft, "$db,$table,n/a,n/a,FULLTEXT index on table. Direct conversion is not possible\n";
}

if ( $report == 1 ){
    print "DB,TABLE,NUMBER OF ROWS, DATA+INDEX SIZE[MB], RECOMMENDED METHOD\n";
    print @report_ptosc;
    print @report_alter;
    print @report_ft;
}else{
    print @ptosc;
    print @alter;
    print @fulltext;
}

