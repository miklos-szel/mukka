#!/usr/bin/perl
use strict;

my $file = $ARGV[0];
if ( $file eq "") {
    print <<EOF;
The script will simplify the output of the pt-duplicate-key-checker.
example: 
pt-duplicate-key-checker >duplicate_keys.log
mt-dk-parser duplicate_keys.log

EOF
exit 1;
}
open (FILE, $file);
my $table = "";

while (<FILE>){

    if ($_ =~ /(^ALTER TABLE (\`[\w]+?\`\.\`[\w]+\`).+?$)/i) {
        if ($2  ne $table){
            print "\n# ########################################################################\n";
            print "# TABLE NAME: $2\n";
            print "# SHOW CREATE TABLE $2\\G\n";
            print "# ########################################################################\n\n";
            $table = $2;
        }
        print $1."\n";
    }
    
}
