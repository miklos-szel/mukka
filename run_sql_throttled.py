#!/usr/bin/python

import MySQLdb
import os
import pprint
import sys
import logging
import time

logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')


db = MySQLdb.connect(host="localhost",
                     user="root",
                     passwd="",
                     db="test")

cur = db.cursor()
tablename = "users"
chunk_size = 100000
min_id = 0
max_id_sql = "select max(id) from %s;" % (tablename)

cur.execute(max_id_sql)
for row in cur.fetchone():
       	max_id = row

print "max_user_id=%s" % (max_id)
while (min_id <= max_id):
       	to_id = min_id  + chunk_size
       	update_sql = "UPDATE table SET column = 6 WHERE user_id>%s AND user_id < %s ;" % (min_id,to_id)
       	print update_sql
       	percent = 100*min_id/max_id
       	print "PROGRESS: %s%%" % (percent)
       	try:
       		cur.execute(update_sql)
        except (MySQLdb.Error, MySQLdb.Warning) as e:
               	print(e)


       	min_id += chunk_size +1
       	time.sleep(1)




exit ()
