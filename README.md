## MySQL scripts and tools to help dealing with common DBA tasks

note: every script here is designed to be harmless and won't make actual changes without user confirmation.

### what you need

  - Perl
  - MySQL client in PATH  

install the code:
```bash
git clone https://github.com/mszel-blackbirdit/mukka
```
#### [mt-rds-diff.pl] (https://github.com/mszel-blackbirdit/mukka/blob/master/mt-rds-diff.pl)

**DESCRIPTON:**

The script will print the difference between the settings of the currently running MySQL instance and the Parameter Group config. It's useful when the RDS instance in Paramter Group(Pending Reboot) but you don't know what Paramter Group options have changed. 


**IMPACT:**
NONE, it compares two config files

**INPUT:**
Save MySQL config from the RDS instances with:
```
mysql --batch --skip-column-names -h rds_hostname -u username -p -e "show global variables" >rds_mysql_config
````

Save RDS Parameter Group settings:
```
rds-describe-db-parameters [--region rds_region] --db-parameter-group-name param_group_name --source user --show-long >rds_pg_config
```

**OUTPUT:**
```
./mt-rds-diff.pl rds_mysql_config  rds_pg_config
Setting name                        MySQL value                      RDS Parameter Group value
general_log                         OFF                              ON
long_query_time                     0.000000                         3

```


#### [mt-show-all-myisam.pl] (https://github.com/mszel-blackbirdit/mukka/blob/master/mt-show-all-myisam.pl)

**DESCRIPTON:**

The script **prints** the ALTER commands necessary to convert all of your MyISAM tables(except `mysql`,`information_schema`) to InnoDB. It lists all MyISAM tables with FULLTEXT indexes as well.

**The last thing I'drecommend to run these ALTER-s without considering the cons and pros, handle the output as a kind of hint.** 

It's also not recommended to run many alters each after another on big tables as it could easily kill the server. On large tables using pt-online-schema-change is the preferred way to alter tables without locking.

The script run the following SQL(included in the mt-show-all-myisam.pl):

https://github.com/mszel-blackbirdit/mukka/blob/master/sql/show_all_myisam.sql


**IMPACT:** 
It WON'T MAKE ANY CHANGES, however it could take some time to run if you have plenty tables on the server

**INPUT:**
None 
(by default the host=localhost, user=root, password=''. These can be changed in the header (will change this in the future)

**OUTPUT:**

```
[vagrant@vagrant-centos65 mukka]$ ./mt-show-all-myisam.pl

===== MyISAM Tables without FULLTEXT indexes =====
ALTER TABLE test.test2 engine=INNODB;
ALTER TABLE test.gezemice engine=INNODB;
ALTER TABLE test.morenbuk engine=INNODB;

===== MyISAM Tables with FULLTEXT indexes =====
test.searchindex
```


#### [mt-show-all-views.pl] (https://github.com/mszel-blackbirdit/mukka/blob/master/mt-show-all-views.pl)


**DESCRIPTON:**

The script **prints** the list of all views and the query for each VIEW.

**IMPACT:**
None. It WON'T MAKE ANY CHANGES.

**INPUT:**
None 
(by default the host=localhost, user=root, password=''. These can be changed in the header (will change this in the future)

**OUTPUT:**
```
[vagrant@vagrant-centos65 mukka]$ ./mt-show-all-views.pl

List of all views on 'vagrant-centos65.vagrantup.com':

test.a
test.another_view
test.v


SHOW CREATE VIEW test.a;
*************************** 1. row ***************************
                View: a
         Create View: CREATE ALGORITHM=UNDEFINED DEFINER=``@`localhost` SQL SECURITY DEFINER VIEW `test`.`a` AS select `test`.`t`.`a` AS `a`,`test`.`t`.`b` AS `b` from `test`.`t`
character_set_client: utf8
collation_connection: utf8_general_ci


SHOW CREATE VIEW test.another_view;
*************************** 1. row ***************************
                View: another_view
         Create View: CREATE ALGORITHM=UNDEFINED DEFINER=``@`localhost` SQL SECURITY DEFINER VIEW `test`.`another_view` AS select `test`.`t`.`a` AS `a`,`test`.`t`.`b` AS `b` from `test`.`t`
character_set_client: utf8
collation_connection: utf8_general_ci


SHOW CREATE VIEW test.v;
*************************** 1. row ***************************
                View: v
         Create View: CREATE ALGORITHM=UNDEFINED DEFINER=``@`localhost` SQL SECURITY DEFINER VIEW `test`.`v` AS select `test`.`t`.`a` AS `a`,`test`.`t`.`b` AS `b` from `test`.`t`
character_set_client: utf8
collation_connection: utf8_general_ci
```

