#!/usr/bin/env python
#Following command will print documentation of iseg_SHQ226L.py:
#pydoc hvb_db_utility 

"""
AUTHORS:
Bronson Edralin <bedralin@hawaii.edu>
University of Hawaii at Manoa
Instrumentation Development Lab (IDLab), WAT214

OVERVIEW:
This is a database utility used for IDLab. It will automatically take your csv file and upload it to IDLab's postgreSQL database on IDLab's server which lies on idlab.phys.hawaii.edu

dbname = postgres
superuser = postgres
password = ????

create ssh tunnel before you use this:
ssh -L 3000:localhost:3000 postgres@idlab.phys.hawaii.edu
    ** Then enter password for postgres **

Then use settings to access postgreSQL database:
host = 'localhost',
port = '3000',
dbname = 'postgres',
user = 'postgres',
password = 'pass123'
"""

import datetime
import time
import os
import psycopg2
import logging
import csv


DEBUG=False # NOT NECESSARY because error is printed in HVB_ASSEMBLY_DB_log file
      	    # setting DEBUG=True will print error to screen.

if DEBUG:
    print "Entering DEBUG Mode...\n"

# logfile for errors that may occur in uploading data from csv to database
logging.basicConfig(filename='HVB_ASSEMBLY_DB_log',level=logging.DEBUG,format='%(asctime)s %(message)s')

class DatabaseUtility:
    '''
    Consider this as a package for interfacing with postgres database
    through python. This is basically an API that controls actions
    done to database utilizing the psycopg2 package.
    '''
    def __init__(self,host='localhost',port='3000',dbname='mydb',user='bronson',password='pass123'):

	#ssh -L 5432:localhost:5432 bronson@193.163.153.108 
	
	DatabaseInfo = 'host='+host+ ' port='+port+' dbname='+dbname+' user='+user+' password='+password
	print "Connecting to database\n ->%s\n"%(DatabaseInfo)
	self.conn = psycopg2.connect(DatabaseInfo)
	self.cur = self.conn.cursor()

    def insert_data_into_database(self, insertFilename, tableName):
	'''
	given: a file name of a csv file and a table name in string form
	return: nothing, but inputs the data into a postgresql database 
		instead of psql command line on local computer into 
		specified table name. You need to use port forwarding
		if you want to upload to a remote database.
	'''
	#setup the csv reader object
	insertFile = open(insertFilename,'r')
	reader = csv.reader(insertFile)
	#start a counter to keep track of how many errors occurred
	error = 0
	print "Inserting data into the "+tableName+" now ..."
	
	#this block of code feeds into the database one entry at a time
	#if there is an error during insertion eg, violates primary key
	#constraints, then it counts the error and outputs it to the 
	#user.
	for row in reader:
	    if (row[0]!="Purpose"):
		try:
		    #keeps a savepoint so that in the event there
		    #is an error, then it will roll back in the 
		    #exception block of code
		    self.cur.execute("BEGIN;")
		    self.cur.execute("SAVEPOINT my_savepoint;")
		    #create the command name here
		    sql = "INSERT INTO "+tableName+" (DateTime,SerialNumber,"+\
		    "BoardName,Channel,ISEG_V,LoadRelay1,LoadRelay2,K,"+\
		    "MCPAT,MCPAB,MCPBT,MCPBB,Result_V) VALUES ('"+row[1]\
		    +"','"+row[2]+"','"+row[3]+"',"+row[4]+","+row[5]+\
		    ","+row[6]+","+row[7]+","+row[8]+","+row[9]+\
		    ","+row[10]+","+row[11]+","+row[12]+","+row[13]+\
		    ");"
		    #this executes the command stored in sql
		    #it acts like you just typed the command line
		    #at the psql prompt
		    self.cur.execute(sql)
		    #this commits the command in the psql
		    #similar to hitting enter
		    self.conn.commit()
		    #time.sleep(0.2)
		except Exception, e:
		    self.cur.execute("ROLLBACK TO SAVEPOINT my_savepoint;")
		    logging.warning('Did not insert data into table "'+tableName+\
		    '"\n'+'\tError occured: '+str(e)+'\t'+str(row[1])+","+\
		    str(row[2])+","+str(row[3])+","+str(row[4])+","+str(row[5])+\
		    ","+str(row[6])+","+str(row[7])+","+str(row[8])+","+str(row[9])\
		    +","+str(row[10])+","+str(row[11])+","+str(row[12])+","+\
		    str(row[13])+"\n")
		    if DEBUG:
			print 'Did not insert data into table "'+tableName+\
			'"\n'+'\tError occured: %s',e
		    #keeps record of how many errors occured
		    error = error + 1
	#output to the user stating at what time the insertion
	#finished and how many errors there were
        print "\nAt "+str(datetime.datetime.now())+", "+str(error)+" error(s) occured."
        print "\t-> Please refer to 'HVB_ASSEMBLY_DB_log' file for more information.\n"
	insertFile.close()

    def create_table(self,tableName):
	'''
	given: a string
	return: nothing but creates a table in the psql database with
	       the string as the name
	'''
	#this checks to see if the table already exists in the database
	#if the specified table name exists then it ends the method
	#with a return of 1
	error=0
	if self.check_table_exists(tableName) == True:
	    return 1
	    
	try:
	    #otherwise the program creates the command string
	    sql = 'CREATE TABLE '+tableName+'( DateTime timestamp with no '+\
		'time zone NOT NULL, SerialNumber character varying NOT NULL, BoardName '+\
		'character varying NOT NULL, Channel integer NOT NULL, ISEG_V '\
		'integer NOT NULL, LoadRelay1 integer NOT NULL, LoadRelay2 integer '\
		'NOT NULL, K integer NOT NULL, MCPAT integer NOT NULL, MCPAB '+\
		'integer NOT NULL, MCPBT integer NOT NULL, MCPBB integer NOT NULL, '\
		+'Result_V double precision, CONSTRAINT '+tableName+'_prim_key '+\
		'PRIMARY KEY (DateTime, SerialNumber, BoardName, Channel,ISEG_V,LoadRelay1'+\
		',LoadRelay2,K,MCPAT,MCPAB,MCPBT,MCPBB,Result_V)) WITH( OIDS=FALSE);'	    
	    # this types it out at psql prompt
	    self.cur.execute(sql)
	    # this hits enter to commit command
	    self.conn.commit()
	    # Owner of table is changed to postgres for security reasons
	    # Most likely it defaults to postgres, but we are
	    # ensuring that this happens
	    sql = 'ALTER TABLE '+tableName+' OWNER TO postgres;'
	    # execute lets you type out command at psql prompt
	    self.cur.execute(sql)
	    # commit() lets you hit enter at psql prompt
	    self.conn.commit()
	    print 'Successfully inserted table '+tableName
	except Exception, e:
	    # If an error occur with code above, software will
	    # print the error in the logfile that was specified earlier
	    # You should be able to know exactly where the error occured
            logging.warning('Did not create table "'+tableName+'"\n'+'\tError occured: %s',e)
	    if DEBUG:
		print 'Did not create table "'+tableName+'"\n'+'\tError occured: %s',e 
	    error+=1
	
	print "\nAt "+str(datetime.datetime.now())+", "+str(error)+" error(s) occured."
	print "\t-> Please refer to 'HVB_ASSEMBLY_log' file for more information.\n"

    def close_conn(self):
	'''
	given: nothing
	return: nothing but closes the connection
	'''
	self.conn.close()

    def check_table_exists(self,tableName):
	'''
	given: a string of the name of the table desired
	return: a True or False to say if the specified table name
	       does indeed exist
	'''
	# queries database to see if table is within list
	# of tables that's in the database's schema
	self.cur.execute("select exists(select * from information_schema.tables where table_name=%s)", (tableName,))
	#return True or False if the specified table name exists or not
	true_or_false=False
	if self.cur.fetchone()[0]==1:
	    self.cur.close()
	    true_or_false=True
	if true_or_false==True:
	    print 'Table "'+tableName+'" already exists...'
	return true_or_false

def upload_to_database(csv_file_name,table_name):
    db=DatabaseUtility()

    # db.create_table("HVB_RawTest")  # creating new table with headers
    # insert data into database
    # db.insert_data_into_database("BARCODENUM_hvb_test_raw_r1BE.csv","HVB_RawTest")
    # db.close_conn()    # close connection to database


