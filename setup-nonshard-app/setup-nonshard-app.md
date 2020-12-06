# Setup a Non-Sharded Application

## Introduction

In this lab, you will setup a non-sharded database application. You will migrate the schema and data to the sharded database in the next lab. The demo java application is designed for sharded database, but also can work with the non-sharded database with a little modified. In order to save the resource, we will use a PDB in the shard3 host to simulate a non-sharded instance.

Estimated Lab Time: 20 minutes.

### Objectives

In this lab, you will perform the following steps:

- Create a non-sharded instance.
- Create the demo schema
- Setup and run the demo application
- Export the demo data.



### Prerequisites

This lab assumes you have already completed the following:

- Environment setup 



## **Step 1:** Create a Non-Sharded Instance

1. Connect to the shard3 host, switch to the oracle user.

   ```
   $ ssh -i labkey opc@xxx.xxx.xxx
   Last login: Mon Nov 30 11:24:36 2020 from 59.66.120.23
   -bash: warning: setlocale: LC_CTYPE: cannot change locale (UTF-8): No such file or directory
   
   [opc@shd3 ~]$ sudo su - oracle
   Last login: Mon Nov 30 11:27:34 GMT 2020 on pts/0
   [oracle@shd3 ~]$ 
   ```

   

2. Connect to the database as sysdba.

   ```
   [oracle@shd3 ~]$ sqlplus / as sysdba
   
   SQL*Plus: Release 19.0.0.0.0 - Production on Fri Dec 4 11:32:41 2020
   Version 19.7.0.0.0
   
   Copyright (c) 1982, 2020, Oracle.  All rights reserved.
   
   
   Connected to:
   Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
   Version 19.7.0.0.0
   
   SQL> 
   ```

   

3. Create a new pdb name sipdb.

   ```
   SQL> CREATE PLUGGABLE DATABASE nspdb ADMIN USER admin IDENTIFIED BY Ora_DB4U 
     DEFAULT TABLESPACE users DATAFILE '/u01/app/oracle/oradata/SHD3/nspdb/users01.dbf' 
     SIZE 10G AUTOEXTEND ON 
     FILE_NAME_CONVERT = ('/pdbseed/', '/nspdb/');  2    3    4  
   
   Pluggable database created.
   
   SQL>
   ```

   

4. Open the PDB.

   ```
   SQL> alter pluggable database nspdb open;
   
   Pluggable database altered.
   
   SQL>
   ```

   

5. Connect to the PDB as sysdba.

   ```
   SQL> alter session set container = nspdb;
   
   Session altered.
   
   SQL>
   ```

   

6. Create a service named `GDS$CATALOG.ORADBCLOUD` and start it in order to run the demo application correctly (The service name is hard code in the demo application).

   ```
   SQL> BEGIN
     DBMS_SERVICE.create_service(
       service_name => 'GDS$CATALOG.ORADBCLOUD',
       network_name => 'GDS$CATALOG.ORADBCLOUD'
     );
   END;
   /  2    3    4    5    6    7  
   
   PL/SQL procedure successfully completed.
   
   SQL> BEGIN
     DBMS_SERVICE.start_service(
       service_name => 'GDS$CATALOG.ORADBCLOUD'
     );
   END;
   /  2    3    4    5    6  
   
   PL/SQL procedure successfully completed.
   
   SQL> 
   ```

   

7. Exit from the sqlplus.

   ```
   SQL> exit
   Disconnected from Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
   Version 19.7.0.0.0
   [oracle@shd3 ~]$ 
   ```




## **Step 2:** Create the Demo Schema

1. Still in the shard3 host with oracle user. Download the SQL script `nonshard-app-schema.sql`.

   ```
   
   ```

   

2. Review the content in the sql scripts file.

   ```
   [oracle@shd3 ~]$ cat nonshard-app-schema.sql 
   set echo on 
   set termout on
   set time on
   spool /home/oracle/nonshard_app_schema.lst
   REM
   REM Connect to the pdb and Create Schema
   REM
   connect / as sysdba
   alter session set container=nspdb;
   create user app_schema identified by app_schema;
   grant connect, resource, alter session to app_schema;
   grant execute on dbms_crypto to app_schema;
   grant create table, create procedure, create tablespace, create materialized view to app_schema;
   grant unlimited tablespace to app_schema;
   grant select_catalog_role to app_schema;
   grant all privileges to app_schema;
   grant dba to app_schema;
   
   REM
   REM Create tables
   REM
   connect app_schema/app_schema@localhost:1521/nspdb
   
   REM
   REM Create for Customers  
   REM
   CREATE TABLE Customers
   (
     CustId      VARCHAR2(60) NOT NULL,
     FirstName   VARCHAR2(60),
     LastName    VARCHAR2(60),
     Class       VARCHAR2(10),
     Geo         VARCHAR2(8),
     CustProfile VARCHAR2(4000),
     Passwd      RAW(60),
     CONSTRAINT pk_customers PRIMARY KEY (CustId),
     CONSTRAINT json_customers CHECK (CustProfile IS JSON)
   ) TABLESPACE USERS
   PARTITION BY HASH (CustId) PARTITIONS 12;
   
   REM
   REM Create table for Orders
   REM
   CREATE TABLE Orders
   (
     OrderId     INTEGER NOT NULL,
     CustId      VARCHAR2(60) NOT NULL,
     OrderDate   TIMESTAMP NOT NULL,
     SumTotal    NUMBER(19,4),
     Status      CHAR(4),
     constraint  pk_orders primary key (CustId, OrderId),
     constraint  fk_orders_parent foreign key (CustId) 
       references Customers on delete cascade
   ) TABLESPACE USERS
   partition by reference (fk_orders_parent);
   
   REM
   REM Create the sequence used for the OrderId column
   REM
   CREATE SEQUENCE Orders_Seq;
   
   REM
   REM Create table for LineItems
   REM
   CREATE TABLE LineItems
   (
     OrderId     INTEGER NOT NULL,
     CustId      VARCHAR2(60) NOT NULL,
     ProductId   INTEGER NOT NULL,
     Price       NUMBER(19,4),
     Qty         NUMBER,
     constraint  pk_items primary key (CustId, OrderId, ProductId),
     constraint  fk_items_parent foreign key (CustId, OrderId)
       references Orders on delete cascade
   ) TABLESPACE USERS
   partition by reference (fk_items_parent);
   
   REM
   REM Create table for Products
   REM
   CREATE TABLE Products
   (
     ProductId  INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
     Name       VARCHAR2(128),
     DescrUri   VARCHAR2(128),
     LastPrice  NUMBER(19,4)
   ) TABLESPACE USERS;
   
   REM
   REM Create functions for Password creation and checking – used by the REM demo loader application
   REM
   
   CREATE OR REPLACE FUNCTION PasswCreate(PASSW IN RAW)
     RETURN RAW
   IS
     Salt RAW(8);
   BEGIN
     Salt := DBMS_CRYPTO.RANDOMBYTES(8);
     RETURN UTL_RAW.CONCAT(Salt, DBMS_CRYPTO.HASH(UTL_RAW.CONCAT(Salt, PASSW), DBMS_CRYPTO.HASH_SH256));
   END;
   /
   
   CREATE OR REPLACE FUNCTION PasswCheck(PASSW IN RAW, PHASH IN RAW)
     RETURN INTEGER IS
   BEGIN
     RETURN UTL_RAW.COMPARE(
         DBMS_CRYPTO.HASH(UTL_RAW.CONCAT(UTL_RAW.SUBSTR(PHASH, 1, 8), PASSW), DBMS_CRYPTO.HASH_SH256),
         UTL_RAW.SUBSTR(PHASH, 9));
   END;
   /
   
   REM
   REM
   select table_name from user_tables;
   REM
   REM
   spool off
   
   [oracle@shd3 ~]$ 
   ```

   

3. Use SQLPLUS to run this sql scripts.

   ```
   [oracle@shd3 ~]$ sqlplus /nolog
   
   SQL*Plus: Release 19.0.0.0.0 - Production on Sat Dec 5 01:44:19 2020
   Version 19.7.0.0.0
   
   Copyright (c) 1982, 2020, Oracle.  All rights reserved.
   
   SQL> @nonshard-app-schema.sql
   ```

   

4. The result screen like the following:

   ```
   Connected.
   02:37:45 SQL> 
   02:37:45 SQL> REM
   02:37:45 SQL> REM Create for Customers
   02:37:45 SQL> REM
   02:37:45 SQL> CREATE TABLE Customers
   02:37:45   2  (
   02:37:45   3  	CustId	    VARCHAR2(60) NOT NULL,
   02:37:45   4  	FirstName   VARCHAR2(60),
   02:37:45   5  	LastName    VARCHAR2(60),
   02:37:45   6  	Class	    VARCHAR2(10),
   02:37:45   7  	Geo	    VARCHAR2(8),
   02:37:45   8  	CustProfile VARCHAR2(4000),
   02:37:45   9  	Passwd	    RAW(60),
   02:37:45  10  	CONSTRAINT pk_customers PRIMARY KEY (CustId),
   02:37:45  11  	CONSTRAINT json_customers CHECK (CustProfile IS JSON)
   02:37:45  12  ) TABLESPACE USERS
   02:37:45  13  PARTITION BY HASH (CustId) PARTITIONS 12;
   
   Table created.
   
   02:37:45 SQL> 
   02:37:45 SQL> REM
   02:37:45 SQL> REM Create table for Orders
   02:37:45 SQL> REM
   02:37:45 SQL> CREATE TABLE Orders
   02:37:45   2  (
   02:37:45   3  	OrderId     INTEGER NOT NULL,
   02:37:45   4  	CustId	    VARCHAR2(60) NOT NULL,
   02:37:45   5  	OrderDate   TIMESTAMP NOT NULL,
   02:37:45   6  	SumTotal    NUMBER(19,4),
   02:37:45   7  	Status	    CHAR(4),
   02:37:45   8  	constraint  pk_orders primary key (CustId, OrderId),
   02:37:45   9  	constraint  fk_orders_parent foreign key (CustId)
   02:37:45  10  	  references Customers on delete cascade
   02:37:45  11  ) TABLESPACE USERS
   02:37:45  12  partition by reference (fk_orders_parent);
   
   Table created.
   
   02:37:45 SQL> 
   02:37:45 SQL> REM
   02:37:45 SQL> REM Create the sequence used for the OrderId column
   02:37:45 SQL> REM
   02:37:45 SQL> CREATE SEQUENCE Orders_Seq;
   
   Sequence created.
   
   02:37:45 SQL> 
   02:37:45 SQL> REM
   02:37:45 SQL> REM Create table for LineItems
   02:37:45 SQL> REM
   02:37:45 SQL> CREATE TABLE LineItems
   02:37:45   2  (
   02:37:45   3  	OrderId     INTEGER NOT NULL,
   02:37:45   4  	CustId	    VARCHAR2(60) NOT NULL,
   02:37:45   5  	ProductId   INTEGER NOT NULL,
   02:37:45   6  	Price	    NUMBER(19,4),
   02:37:45   7  	Qty	    NUMBER,
   02:37:45   8  	constraint  pk_items primary key (CustId, OrderId, ProductId),
   02:37:45   9  	constraint  fk_items_parent foreign key (CustId, OrderId)
   02:37:45  10  	  references Orders on delete cascade
   02:37:45  11  ) TABLESPACE USERS
   02:37:45  12  partition by reference (fk_items_parent);
   
   Table created.
   
   02:37:45 SQL> 
   02:37:45 SQL> REM
   02:37:45 SQL> REM Create table for Products
   02:37:45 SQL> REM
   02:37:45 SQL> CREATE TABLE Products
   02:37:45   2  (
   02:37:45   3  	ProductId  INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
   02:37:45   4  	Name	   VARCHAR2(128),
   02:37:45   5  	DescrUri   VARCHAR2(128),
   02:37:45   6  	LastPrice  NUMBER(19,4)
   02:37:45   7  ) TABLESPACE USERS;
   
   Table created.
   
   02:37:45 SQL> 
   02:37:45 SQL> REM
   02:37:45 SQL> REM Create functions for Password creation and checking – used by the REM demo loader application
   02:37:45 SQL> REM
   02:37:45 SQL> 
   02:37:45 SQL> CREATE OR REPLACE FUNCTION PasswCreate(PASSW IN RAW)
   02:37:45   2  	RETURN RAW
   02:37:45   3  IS
   02:37:45   4  	Salt RAW(8);
   02:37:45   5  BEGIN
   02:37:45   6  	Salt := DBMS_CRYPTO.RANDOMBYTES(8);
   02:37:45   7  	RETURN UTL_RAW.CONCAT(Salt, DBMS_CRYPTO.HASH(UTL_RAW.CONCAT(Salt, PASSW), DBMS_CRYPTO.HASH_SH256));
   02:37:45   8  END;
   02:37:45   9  /
   
   Function created.
   
   02:37:45 SQL> 
   02:37:45 SQL> CREATE OR REPLACE FUNCTION PasswCheck(PASSW IN RAW, PHASH IN RAW)
   02:37:45   2  	RETURN INTEGER IS
   02:37:45   3  BEGIN
   02:37:45   4  	RETURN UTL_RAW.COMPARE(
   02:37:45   5  	    DBMS_CRYPTO.HASH(UTL_RAW.CONCAT(UTL_RAW.SUBSTR(PHASH, 1, 8), PASSW), DBMS_CRYPTO.HASH_SH256),
   02:37:45   6  	    UTL_RAW.SUBSTR(PHASH, 9));
   02:37:45   7  END;
   02:37:45   8  /
   
   Function created.
   
   02:37:45 SQL> 
   02:37:45 SQL> REM
   02:37:45 SQL> REM
   02:37:45 SQL> select table_name from user_tables;
   
   TABLE_NAME
   --------------------------------------------------------------------------------
   CUSTOMERS
   ORDERS
   LINEITEMS
   PRODUCTS
   
   02:37:45 SQL> REM
   02:37:45 SQL> REM
   02:37:45 SQL> spool off
   02:37:45 SQL> 
   ```

   

5. The single instance demo schema is created. Exit the sqlplus. and Exit the Shard3 host.

   ```
   02:37:45 SQL> exit
   Disconnected from Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
   Version 19.7.0.0.0
   [oracle@shd3 ~]$ exit
   logout
   [opc@shd3 ~]$ exit
   logout
   Connection to 152.67.196.227 closed.
   $ 
   ```




## **Step 3:** Setup and Run the Demo Application

1. Connect to the catalog host, switch to the oracle user.

   ```
   $ ssh -i labkey opc@152.67.196.50
   Last login: Fri Dec  4 06:48:49 2020 from 202.45.129.206
   -bash: warning: setlocale: LC_CTYPE: cannot change locale (UTF-8): No such file or directory
   [opc@cata ~]$ sudo su - oracle
   Last login: Fri Dec  4 06:48:55 GMT 2020 on pts/0
   [oracle@cata ~]$ 
   ```

   

2. Download the `sdb_demo_app.zip`  file.

   ```
   
   ```

   

3. Unzip the file. This will create `sdb_demo_app` directory under the `/home/oracle`.

   ```
   [oracle@cata ~]$ unzip sdb_demo_app.zip 
   Archive:  sdb_demo_app.zip
      creating: sdb_demo_app/
     inflating: sdb_demo_app/demo.properties  
     inflating: __MACOSX/sdb_demo_app/._demo.properties  
     inflating: sdb_demo_app/logging.properties  
     inflating: __MACOSX/sdb_demo_app/._logging.properties  
     inflating: sdb_demo_app/README _SDB_Demo_Application.pdf  
     inflating: __MACOSX/sdb_demo_app/._README _SDB_Demo_Application.pdf  
     inflating: sdb_demo_app/.DS_Store  
     inflating: __MACOSX/sdb_demo_app/._.DS_Store  
     inflating: sdb_demo_app/monitor.logging.properties  
     inflating: __MACOSX/sdb_demo_app/._monitor.logging.properties  
     inflating: sdb_demo_app/generate_properties.sh  
     inflating: __MACOSX/sdb_demo_app/._generate_properties.sh  
     inflating: sdb_demo_app/build.xml  
     inflating: __MACOSX/sdb_demo_app/._build.xml  
      creating: sdb_demo_app/web/
     inflating: sdb_demo_app/run.sh     
     inflating: __MACOSX/sdb_demo_app/._run.sh  
     inflating: sdb_demo_app/monitor-install.sh  
     inflating: __MACOSX/sdb_demo_app/._monitor-install.sh  
     inflating: sdb_demo_app/fill.sh    
     inflating: __MACOSX/sdb_demo_app/._fill.sh  
      creating: sdb_demo_app/lib/
     inflating: sdb_demo_app/demo.logging.properties  
     inflating: __MACOSX/sdb_demo_app/._demo.logging.properties  
     inflating: sdb_demo_app/monitor.sh  
     inflating: __MACOSX/sdb_demo_app/._monitor.sh  
      creating: sdb_demo_app/build/
      creating: sdb_demo_app/data/
      creating: sdb_demo_app/src/
      creating: sdb_demo_app/sql/
     inflating: sdb_demo_app/web/bootstrap.min.css  
     inflating: __MACOSX/sdb_demo_app/web/._bootstrap.min.css  
     inflating: sdb_demo_app/web/npm.js  
     inflating: __MACOSX/sdb_demo_app/web/._npm.js  
     inflating: sdb_demo_app/web/Chart.js  
     inflating: __MACOSX/sdb_demo_app/web/._Chart.js  
     inflating: sdb_demo_app/web/bootstrap.css  
     inflating: __MACOSX/sdb_demo_app/web/._bootstrap.css  
     inflating: sdb_demo_app/web/DatabaseWidgets.js  
     inflating: __MACOSX/sdb_demo_app/web/._DatabaseWidgets.js  
     inflating: sdb_demo_app/web/jquery-2.1.4.js  
     inflating: __MACOSX/sdb_demo_app/web/._jquery-2.1.4.js  
     inflating: sdb_demo_app/web/Chart.HorizontalBar.js  
     inflating: __MACOSX/sdb_demo_app/web/._Chart.HorizontalBar.js  
     inflating: sdb_demo_app/web/bootstrap.js  
     inflating: __MACOSX/sdb_demo_app/web/._bootstrap.js  
     inflating: sdb_demo_app/web/masonry.pkgd.js  
     inflating: __MACOSX/sdb_demo_app/web/._masonry.pkgd.js  
     inflating: sdb_demo_app/web/bootstrap.min.js  
     inflating: __MACOSX/sdb_demo_app/web/._bootstrap.min.js  
     inflating: sdb_demo_app/web/dash.html  
     inflating: __MACOSX/sdb_demo_app/web/._dash.html  
     inflating: sdb_demo_app/web/bootstrap-theme.css  
     inflating: __MACOSX/sdb_demo_app/web/._bootstrap-theme.css  
     inflating: sdb_demo_app/web/db.svg  
     inflating: __MACOSX/sdb_demo_app/web/._db.svg  
     inflating: sdb_demo_app/web/bootstrap-theme.min.css  
     inflating: __MACOSX/sdb_demo_app/web/._bootstrap-theme.min.css  
     inflating: sdb_demo_app/lib/ojdbc8.jar  
     inflating: __MACOSX/sdb_demo_app/lib/._ojdbc8.jar  
     inflating: sdb_demo_app/lib/ons.jar  
     inflating: __MACOSX/sdb_demo_app/lib/._ons.jar  
     inflating: sdb_demo_app/lib/ucp.jar  
     inflating: __MACOSX/sdb_demo_app/lib/._ucp.jar  
     inflating: sdb_demo_app/build/demo.jar  
     inflating: __MACOSX/sdb_demo_app/build/._demo.jar  
     inflating: sdb_demo_app/data/streets.txt  
     inflating: __MACOSX/sdb_demo_app/data/._streets.txt  
     inflating: sdb_demo_app/data/first-m.txt  
     inflating: __MACOSX/sdb_demo_app/data/._first-m.txt  
     inflating: sdb_demo_app/data/us-places.txt  
     inflating: __MACOSX/sdb_demo_app/data/._us-places.txt  
     inflating: sdb_demo_app/data/first-f.txt  
     inflating: __MACOSX/sdb_demo_app/data/._first-f.txt  
     inflating: sdb_demo_app/data/parts.txt  
     inflating: __MACOSX/sdb_demo_app/data/._parts.txt  
     inflating: sdb_demo_app/data/last.txt  
     inflating: __MACOSX/sdb_demo_app/data/._last.txt  
     inflating: sdb_demo_app/src/.DS_Store  
     inflating: __MACOSX/sdb_demo_app/src/._.DS_Store  
      creating: sdb_demo_app/src/oracle/
     inflating: sdb_demo_app/sql/app_schema_auto.sql  
     inflating: sdb_demo_app/sql/demo_app_ext.sql  
     inflating: __MACOSX/sdb_demo_app/sql/._demo_app_ext.sql  
     inflating: sdb_demo_app/sql/catalog_monitor.sql  
     inflating: __MACOSX/sdb_demo_app/sql/._catalog_monitor.sql  
     inflating: sdb_demo_app/sql/app_schema_user.sql  
     inflating: __MACOSX/sdb_demo_app/sql/._app_schema_user.sql  
     inflating: sdb_demo_app/sql/global_views.sql  
     inflating: __MACOSX/sdb_demo_app/sql/._global_views.sql  
     inflating: sdb_demo_app/sql/shard_helpers.sql  
     inflating: __MACOSX/sdb_demo_app/sql/._shard_helpers.sql  
     inflating: sdb_demo_app/sql/global_views.header.sql  
     inflating: __MACOSX/sdb_demo_app/sql/._global_views.header.sql  
      creating: sdb_demo_app/src/oracle/demo/
     inflating: sdb_demo_app/src/oracle/ArgParser.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/._ArgParser.java  
      creating: sdb_demo_app/src/oracle/monitor/
     inflating: sdb_demo_app/src/oracle/.DS_Store  
     inflating: __MACOSX/sdb_demo_app/src/oracle/._.DS_Store  
     inflating: sdb_demo_app/src/oracle/RandomGenerator.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/._RandomGenerator.java  
     inflating: sdb_demo_app/src/oracle/Utils.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/._Utils.java  
     inflating: sdb_demo_app/src/oracle/SmartLogFormatter.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/._SmartLogFormatter.java  
     inflating: sdb_demo_app/src/oracle/JsonSerializer.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/._JsonSerializer.java  
     inflating: sdb_demo_app/src/oracle/demo/InfiniteGeneratingQueue.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._InfiniteGeneratingQueue.java  
     inflating: sdb_demo_app/src/oracle/demo/.DS_Store  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._.DS_Store  
     inflating: sdb_demo_app/src/oracle/demo/Application.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._Application.java  
     inflating: sdb_demo_app/src/oracle/demo/CustomerGenerator.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._CustomerGenerator.java  
     inflating: sdb_demo_app/src/oracle/demo/Product.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._Product.java  
     inflating: sdb_demo_app/src/oracle/demo/Customer.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._Customer.java  
     inflating: sdb_demo_app/src/oracle/demo/Statistics.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._Statistics.java  
     inflating: sdb_demo_app/src/oracle/demo/Test.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._Test.java  
     inflating: sdb_demo_app/src/oracle/demo/ApplicationException.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._ApplicationException.java  
     inflating: sdb_demo_app/src/oracle/demo/InstallSchema.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._InstallSchema.java  
     inflating: sdb_demo_app/src/oracle/demo/Actor.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._Actor.java  
     inflating: sdb_demo_app/src/oracle/demo/Main.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._Main.java  
      creating: sdb_demo_app/src/oracle/demo/actions/
     inflating: sdb_demo_app/src/oracle/demo/FillProducts.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._FillProducts.java  
     inflating: sdb_demo_app/src/oracle/demo/Session.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._Session.java  
     inflating: sdb_demo_app/src/oracle/monitor/Install.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/monitor/._Install.java  
     inflating: sdb_demo_app/src/oracle/monitor/Main.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/monitor/._Main.java  
     inflating: sdb_demo_app/src/oracle/monitor/FileHandler.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/monitor/._FileHandler.java  
     inflating: sdb_demo_app/src/oracle/monitor/DatabaseMonitor.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/monitor/._DatabaseMonitor.java  
     inflating: sdb_demo_app/src/oracle/demo/actions/CreateOrder.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/actions/._CreateOrder.java  
     inflating: sdb_demo_app/src/oracle/demo/actions/CustomerAction.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/actions/._CustomerAction.java  
     inflating: sdb_demo_app/src/oracle/demo/actions/OrderLookup.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/actions/._OrderLookup.java  
     inflating: sdb_demo_app/src/oracle/demo/actions/GenerateReport.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/actions/._GenerateReport.java  
     inflating: sdb_demo_app/src/oracle/demo/actions/AddProducts.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/actions/._AddProducts.java  
   [oracle@cata ~]$ 
   ```

   

4. Change to the `sdb_demo_app/sql` directory.

   ```
   [oracle@cata ~]$ cd sdb_demo_app/sql
   [oracle@cata sql]$
   ```

   

5. View the content of the `nonshard_demo_app_ext.sql`. Make sure the connect string is correct to the non-sharded instance pdb.

   ```
   [oracle@cata sql]$ cat nonshard_demo_app_ext.sql 
   -- Create catalog monitor packages
   connect sys/Ora_DB4U@shd3:1521/sipdb as sysdba;
   @catalog_monitor.sql
   
   connect app_schema/app_schema@shd3:1521/sipdb;
   
   alter session enable shard ddl;
   
   CREATE OR REPLACE VIEW SAMPLE_ORDERS AS
     SELECT OrderId, CustId, OrderDate, SumTotal FROM
       (SELECT * FROM ORDERS ORDER BY OrderId DESC)
         WHERE ROWNUM < 10;
   
   alter session disable shard ddl;
   
   -- Allow a special query for dbaview
   connect sys/Ora_DB4U@shd3:1521/sipdb as sysdba;
   
   -- For demo app purposes
   grant shard_monitor_role, gsmadmin_role to app_schema;
   
   alter session enable shard ddl;
   
   create user dbmonuser identified by TEZiPP4MsLLL;
   grant connect, alter session, shard_monitor_role, gsmadmin_role to dbmonuser;
   
   grant all privileges on app_schema.products to dbmonuser;
   grant read on app_schema.sample_orders to dbmonuser;
   
   alter session disable shard ddl;
   -- End workaround
   
   exec dbms_global_views.create_any_view('SAMPLE_ORDERS', 'APP_SCHEMA.SAMPLE_ORDERS', 'GLOBAL_SAMPLE_ORDERS', 0, 1);
   [oracle@cata sql]$ 
   ```

   

6. Using SQLPLUS to run the script.

   ```
   [oracle@cata sql]$ sqlplus /nolog
   
   SQL*Plus: Release 19.0.0.0.0 - Production on Fri Dec 4 12:23:11 2020
   Version 19.7.0.0.0
   
   Copyright (c) 1982, 2020, Oracle.  All rights reserved.
   
   SQL> @single_demo_app_ext.sql
   ```

   

7. The result screen like the following. Ignore the `ORA-02521` error because it's not a shard database.

   ```
   Connected.
   ERROR:
   ORA-02521: attempted to enable shard DDL in a non-shard database
   
   
   
   Role created.
   
   
   Grant succeeded.
   
   
   Grant succeeded.
   
   
   Grant succeeded.
   
   
   Grant succeeded.
   
   
   Session altered.
   
   
   Package created.
   
   No errors.
   
   Package body created.
   
   No errors.
   
   PL/SQL procedure successfully completed.
   
   
   Type created.
   
   
   Type created.
   
   
   Package created.
   
   No errors.
   
   Package body created.
   
   No errors.
   
   Package body created.
   
   No errors.
   
   Grant succeeded.
   
   
   Grant succeeded.
   
   
   Grant succeeded.
   
   
   PL/SQL procedure successfully completed.
   
   
   PL/SQL procedure successfully completed.
   
   
   PL/SQL procedure successfully completed.
   
   
   PL/SQL procedure successfully completed.
   
   
   PL/SQL procedure successfully completed.
   
   Connected.
   ERROR:
   ORA-02521: attempted to enable shard DDL in a non-shard database
   
   
   
   View created.
   
   
   Session altered.
   
   Connected.
   
   Grant succeeded.
   
   ERROR:
   ORA-02521: attempted to enable shard DDL in a non-shard database
   
   
   
   User created.
   
   
   Grant succeeded.
   
   
   Grant succeeded.
   
   
   Grant succeeded.
   
   
   Session altered.
   
   
   PL/SQL procedure successfully completed.
   
   SQL> 
   ```

   

8. Exit the sqlplus. Then change directory to the `sdb_demo_app`.

   ```
   [oracle@cata sql]$ cd ~/sdb_demo_app
   [oracle@cata sdb_demo_app]$ 
   ```

   

9. Review the `nonsharddemo.properties` file content. Make sure the `connect_string` and service name  is correct.

   ```
   [oracle@cata sdb_demo_app]$ cat nonsharddemo.properties 
   name=demo
   connect_string=(ADDRESS_LIST=(LOAD_BALANCE=off)(FAILOVER=on)(ADDRESS=(HOST=shd3)(PORT=1521)(PROTOCOL=tcp)))
   monitor.user=dbmonuser
   monitor.pass=TEZiPP4MsLLL
   app.service.write=sipdb
   app.service.readonly=sipdb
   app.user=app_schema
   app.pass=app_schema
   app.threads=7
   
   [oracle@cata sdb_demo_app]$
   ```

   

10. Start the workload by executing command: `./run.sh demo nonsharddemo.properties`.

   ```
   [oracle@cata sdb_demo_app]$ ./run.sh demo nonsharddemo.properties
   ```

   

11. The result likes the following.

    ```
    Performing initial fill of the products table...
    Syncing shards...
     RO Queries | RW Queries | RO Failed  | RW Failed  | APS 
              0            0            0            0            1
            176            1            0            0           55
           1604          244            0            0          485
           3441          545            0            0          624
           5684          910            0            0          763
           7949         1253            0            0          769
          10301         1614            0            0          801
          12416         2001            0            0          718
          14631         2400            0            0          743
          17073         2764            0            0          831
          19470         3179            0            0          816
          22016         3575            0            0          870
          24515         3937            0            0          851
          27001         4284            0            0          848
          29488         4671            0            0          858
          31894         5085            0            0          811
          34461         5552            0            0          884
          37305         6030            0            0          965
          40308         6541            0            0         1031
          43059         7012            0            0          948
     RO Queries | RW Queries | RO Failed  | RW Failed  | APS 
          45949         7463            0            0          989
          48781         7892            0            0          968
          51623         8379            0            0          970
          54354         8842            0            0          927
          57469         9335            0            0         1059
          60949         9895            0            0         1191
          63983        10394            0            0         1032
          67194        10857            0            0         1116
          69907        11308            0            0          932
          72584        11802            0            0          928
          75207        12272            0            0          905
          78075        12713            0            0          999
    ```

    

12. Wait the application run some times and press `Ctrl-C` to exit the application. Remember the values of the APS.

    ```
         122102        20078            0            0          891
         124764        20536            0            0          931
         127037        20950            0            0          801
         129717        21401            0            0          930
         132596        21818            0            0         1002
         135125        22227            0            0          882
         137690        22682            0            0          895
         140398        23127            0            0          946
    ^C[oracle@cata sdb_demo_app]$ 
    ```




## **Step 4:** Export the Demo Data and Copy DMP File

In this step, you will export the demo application data. You will import the data to the shard database in the next lab.

1. Connect to the shard3 host, switch to the oracle user.

   ```
   $ ssh -i labkey opc@152.67.196.227
   Last login: Mon Nov 30 11:24:36 2020 from 59.66.120.23
   -bash: warning: setlocale: LC_CTYPE: cannot change locale (UTF-8): No such file or directory
   
   [opc@shd3 ~]$ sudo su - oracle
   Last login: Mon Nov 30 11:27:34 GMT 2020 on pts/0
   [oracle@shd3 ~]$ 
   ```

   

2. Connect to the non-sharded database as `app_schema` user with SQLPLUS.

   ```
   [oracle@shd3 ~]$ sqlplus app_schema/app_schema@shd3:1521/sipdb
   
   SQL*Plus: Release 19.0.0.0.0 - Production on Sat Dec 5 07:43:15 2020
   Version 19.7.0.0.0
   
   Copyright (c) 1982, 2020, Oracle.  All rights reserved.
   
   Last Successful login time: Sat Dec 05 2020 07:33:33 +00:00
   
   Connected to:
   Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
   Version 19.7.0.0.0
   
   SQL> 
   ```

   

3. Create a dump directory and exit the SQLPLUS.

   ```
   SQL> create directory demo_pump_dir as '/home/oracle';
   
   Directory created.
   
   SQL> exit
   Disconnected from Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
   Version 19.7.0.0.0
   [oracle@shd3 ~]$
   ```

   

4. Run the following command to export the demo data.

   - `data_option= GROUP_PARTITION_TABLE_DATA `: Unloads all partitions as a single operation producing a single partition of data in the dump file. Subsequent imports will not know this was originally made up of multiple partitions.

   ```
   [oracle@shd3 ~]$ expdp app_schema/app_schema@shd3:1521/sipdb directory=demo_pump_dir \
     dumpfile=original.dmp logfile=original.log \
     schemas=app_schema data_options=group_partition_table_data
   ```

   

5. The result screen like the following.

   ```
   Export: Release 19.0.0.0.0 - Production on Sat Dec 5 09:48:25 2020
   Version 19.7.0.0.0
   
   Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.
   
   Connected to: Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
   Starting "APP_SCHEMA"."SYS_EXPORT_SCHEMA_01":  app_schema/********@shd3:1521/sipdb directory=demo_pump_dir dumpfile=original.dmp logfile=original.log schemas=app_schema data_options=group_partition_table_data 
   Processing object type SCHEMA_EXPORT/TABLE/TABLE_DATA
   Processing object type SCHEMA_EXPORT/TABLE/INDEX/STATISTICS/INDEX_STATISTICS
   Processing object type SCHEMA_EXPORT/TABLE/STATISTICS/TABLE_STATISTICS
   Processing object type SCHEMA_EXPORT/STATISTICS/MARKER
   Processing object type SCHEMA_EXPORT/USER
   Processing object type SCHEMA_EXPORT/SYSTEM_GRANT
   Processing object type SCHEMA_EXPORT/ROLE_GRANT
   Processing object type SCHEMA_EXPORT/DEFAULT_ROLE
   Processing object type SCHEMA_EXPORT/PRE_SCHEMA/PROCACT_SCHEMA
   Processing object type SCHEMA_EXPORT/SEQUENCE/SEQUENCE
   Processing object type SCHEMA_EXPORT/TABLE/TABLE
   Processing object type SCHEMA_EXPORT/TABLE/GRANT/OWNER_GRANT/OBJECT_GRANT
   Processing object type SCHEMA_EXPORT/TABLE/COMMENT
   Processing object type SCHEMA_EXPORT/TABLE/IDENTITY_COLUMN
   Processing object type SCHEMA_EXPORT/FUNCTION/FUNCTION
   Processing object type SCHEMA_EXPORT/FUNCTION/ALTER_FUNCTION
   Processing object type SCHEMA_EXPORT/VIEW/VIEW
   Processing object type SCHEMA_EXPORT/VIEW/GRANT/OWNER_GRANT/OBJECT_GRANT
   Processing object type SCHEMA_EXPORT/TABLE/INDEX/INDEX
   Processing object type SCHEMA_EXPORT/TABLE/CONSTRAINT/CONSTRAINT
   Processing object type SCHEMA_EXPORT/TABLE/CONSTRAINT/REF_CONSTRAINT
   . . exported "APP_SCHEMA"."CUSTOMERS"                    3.313 MB   14707 rows
   . . exported "APP_SCHEMA"."PRODUCTS"                     27.26 KB     480 rows
   . . exported "APP_SCHEMA"."ORDERS"                       1.099 MB   22021 rows
   . . exported "APP_SCHEMA"."LINEITEMS"                    1.558 MB   39195 rows
   Master table "APP_SCHEMA"."SYS_EXPORT_SCHEMA_01" successfully loaded/unloaded
   ******************************************************************************
   Dump file set for APP_SCHEMA.SYS_EXPORT_SCHEMA_01 is:
     /home/oracle/original.dmp
   Job "APP_SCHEMA"."SYS_EXPORT_SCHEMA_01" successfully completed at Sat Dec 5 09:49:47 2020 elapsed 0 00:01:22
   
   [oracle@shd3 ~]$ ls -l
   total 13924
   -rw-r-----.  1 oracle dba      7028736 Dec  5 09:49 original.dmp
   -rw-r--r--.  1 oracle dba         2357 Dec  5 09:49 original.log
   -rw-r--r--.  1 oracle dba         4680 Dec  5 07:45 original_table.log
   -rw-r-----.  1 oracle dba      7192576 Dec  5 07:45 original_tables.dmp
   -rw-r--r--.  1 oracle oinstall    5213 Dec  4 12:07 single_app_schema.lst
   -rw-r--r--.  1 oracle oinstall    2939 Dec  4 11:49 single-app-schema.sql
   drwx------. 12 root   root        4096 Oct 23  2018 swingbench
   [oracle@shd3 ~]$ 
   ```

   

6. From the shard3 host, create a ssh key pair. Press **Enter** to accept all the default values.

   ```
   [oracle@shd3 ~]$ ssh-keygen -t rsa
   Generating public/private rsa key pair.
   Enter file in which to save the key (/home/oracle/.ssh/id_rsa): 
   Created directory '/home/oracle/.ssh'.
   Enter passphrase (empty for no passphrase): 
   Enter same passphrase again: 
   Your identification has been saved in /home/oracle/.ssh/id_rsa.
   Your public key has been saved in /home/oracle/.ssh/id_rsa.pub.
   The key fingerprint is:
   SHA256:3K6FxUIvo04bOYn0LxH0WMf89VRGvomJWsL9ob/bYDU oracle@shd3
   The key's randomart image is:
   +---[RSA 2048]----+
   |         o     .=|
   |      . . +   .o.|
   |     . +.. . . o.|
   |      ooo+. o o +|
   |    .  .So=+ + E |
   |   . o.+ B+ o o .|
   |    . O...o. +   |
   |     o.= o  o o  |
   |      o.o    +o. |
   +----[SHA256]-----+
   [oracle@shd3 ~]$ 
   ```

   

7. View the content of the public key.

   ```
   [oracle@shd3 ~]$ cat .ssh/id_rsa.pub
   ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5MxF+Vt+SILTrw+iXxzpPo277RL1KAOT9YQW3ZfbFY5f08THsbzeyt1ecRZjeSUfG+V2iTOWii+GHtBg4yylzYkzBoTinZ72MkW62t1XcV7w1GIOnDbIX0AG7JD6OURDm8br6+4bjNNKkRjmEZPuJ/KiB4FVcfk3heNG0K6s99OUh7EQsEb2guvalp2KTP9gL6UJRcVeY6omzk5+VeEP0Sm285ev9nQ2/SWgqb1qz7241WP89REIZMEuIJ/g2h8yhXvoCoK59WiZYJuzGWV4AX57t/8viH948suHN4sfabQT9DWuAAJAYryAZPqVwvTgRNMaQRuhUxQB2lwKcMY5N oracle@shd3
   [oracle@shd3 ~]$ 
   ```

   

8. Open another terminal to connect to the cata host. Switch to oracle user.

   ```
   $ ssh -i labkey opc@152.67.196.240
   Last login: Mon Nov 30 11:22:42 2020 from 59.66.120.23
   -bash: warning: setlocale: LC_CTYPE: cannot change locale (UTF-8): No such file or directory
   [opc@shd1 ~]$ sudo su - oracle
   Last login: Sun Nov 29 03:15:53 GMT 2020 on pts/0
   [oracle@cata ~]$ 
   ```

   

9. Make a `.ssh` directory and edit the authorized_keys file.

   ```
   [oracle@cata ~]$ mkdir .ssh
   [oracle@cata ~]$ vi .ssh/authorized_keys
   ```

   

10. Copy all the content of the SSH public key from Shard3 host. Save the file and chmod the file.

   ```
   [oracle@shd1 ~]$ chmod 600 .ssh/authorized_keys 
   [oracle@shd1 ~]$
   ```

   

11. **Repeat do the same steps**  from previous steps 8 - 10. This time connect to the Shard1 and Shard2 host.

12. From Shard3 host side. Copy the dmp file to the catalog, shard1 and shard2 host. Press yes when prompt ask if you want to  continue.

    ```
    [oracle@shd3 ~]$ scp original.dmp oracle@cata:~
    The authenticity of host 'shd1 (10.0.0.3)' can't be established.
    ECDSA key fingerprint is SHA256:fdIUiIXRNQ8LsOsDjN1/OLeLaz2kDeIzpLngV/15tPs.
    ECDSA key fingerprint is MD5:ea:d8:d5:fe:6e:a4:98:3e:e3:a4:dc:a3:24:ed:40:65.
    Are you sure you want to continue connecting (yes/no)? yes
    Warning: Permanently added 'cata,10.0.0.2' (ECDSA) to the list of known hosts.
    original.dmp                                                  100% 6864KB  46.0MB/s   00:00    
    
    [oracle@shd3 ~]$ scp original.dmp oracle@shd1:~
    The authenticity of host 'shd1 (10.0.0.3)' can't be established.
    ECDSA key fingerprint is SHA256:fdIUiIXRNQ8LsOsDjN1/OLeLaz2kDeIzpLngV/15tPs.
    ECDSA key fingerprint is MD5:ea:d8:d5:fe:6e:a4:98:3e:e3:a4:dc:a3:24:ed:40:65.
    Are you sure you want to continue connecting (yes/no)? yes
    Warning: Permanently added 'shd1,10.0.0.3' (ECDSA) to the list of known hosts.
    original.dmp                                                  100% 6864KB  46.0MB/s   00:00    
    
    [oracle@shd3 ~]$ scp original.dmp oracle@shd2:~
    The authenticity of host 'shd2 (10.0.0.4)' can't be established.
    ECDSA key fingerprint is SHA256:DZD3FA2afLdsB17yvn1IoGxHqmTiei6fiqnUHRJXVNw.
    ECDSA key fingerprint is MD5:49:b0:06:11:14:1f:85:76:47:4f:9c:04:d2:15:a9:00.
    Are you sure you want to continue connecting (yes/no)? yes
    Warning: Permanently added 'shd2,10.0.0.4' (ECDSA) to the list of known hosts.
    original.dmp                                                  100% 6864KB  49.6MB/s   00:00    
    [oracle@shd3 ~]$ 
    ```

    

    

You may proceed to the next lab.

