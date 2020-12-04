# Custom Data Loading

## Introduction

To learn more about Oracle Sharded Databases, download and deploy the system-managed SDB demo application. The demo application uses the SDB environment and schema you have just created to simulate the workload of an online retail store. 

Estimated Lab Time: 20 minutes.

### Objectives

In this lab, you will perform the following steps:
- Setup and Configure the sharding demo application
- Start the workload to load the demo data

### Prerequisites

This lab assumes you have already completed the following:
- Sharded Database Deployment
- Create Demo App Schema

## **Step 1:** Setup and Configure the Sharding Demo Application

1. Login to the catalog host, switch to oracle user. Make sure you are in the catalog environment.

   ```
   $ ssh -i labkey opc@152.67.196.50
   Last login: Mon Nov 30 03:06:29 2020 from 202.45.129.206
   -bash: warning: setlocale: LC_CTYPE: cannot change locale (UTF-8): No such file or directory
   [opc@cata ~]$ sudo su - oracle
   Last login: Mon Nov 30 03:06:34 GMT 2020 on pts/0
   [oracle@cata ~]$ . ./cata.sh
   [oracle@cata ~]$
   ```

   

2. Download the `sdb_demo_app.zip`  file. 

   ```
   oracle@cata ~]$ <copy>wget https://github.com/minqiaowang/oracle-sharded-database/raw/main/custom-data-loading/sdb_demo_app.zip</copy>
   ```

   

3. Unzip the file. This will create `sdb_demo_app` directory under the `/home/oracle`

   ```
   [oracle@cata ~]$ <copy>unzip sdb_demo_app.zip</copy> 
   Archive:  sdb_demo_app.zip
      creating: sdb_demo_app/
     inflating: sdb_demo_app/.DS_Store  
      creating: __MACOSX/
      creating: __MACOSX/sdb_demo_app/
     inflating: __MACOSX/sdb_demo_app/._.DS_Store  
      creating: sdb_demo_app/build/
     inflating: sdb_demo_app/build/demo.jar  
      creating: __MACOSX/sdb_demo_app/build/
     inflating: __MACOSX/sdb_demo_app/build/._demo.jar  
     inflating: __MACOSX/sdb_demo_app/._build  
     inflating: sdb_demo_app/build.xml  
     inflating: __MACOSX/sdb_demo_app/._build.xml  
      creating: sdb_demo_app/data/
     inflating: sdb_demo_app/data/first-f.txt  
      creating: __MACOSX/sdb_demo_app/data/
     inflating: __MACOSX/sdb_demo_app/data/._first-f.txt  
     inflating: sdb_demo_app/data/first-m.txt  
     inflating: __MACOSX/sdb_demo_app/data/._first-m.txt  
     inflating: sdb_demo_app/data/last.txt  
     inflating: __MACOSX/sdb_demo_app/data/._last.txt  
     inflating: sdb_demo_app/data/parts.txt  
     inflating: __MACOSX/sdb_demo_app/data/._parts.txt  
     inflating: sdb_demo_app/data/streets.txt  
     inflating: __MACOSX/sdb_demo_app/data/._streets.txt  
     inflating: sdb_demo_app/data/us-places.txt  
     inflating: __MACOSX/sdb_demo_app/data/._us-places.txt  
     inflating: __MACOSX/sdb_demo_app/._data  
     inflating: sdb_demo_app/demo.logging.properties  
     inflating: __MACOSX/sdb_demo_app/._demo.logging.properties  
     inflating: sdb_demo_app/demo.properties  
     inflating: __MACOSX/sdb_demo_app/._demo.properties  
     inflating: sdb_demo_app/fill.sh    
     inflating: __MACOSX/sdb_demo_app/._fill.sh  
     inflating: sdb_demo_app/generate_properties.sh  
     inflating: __MACOSX/sdb_demo_app/._generate_properties.sh  
      creating: sdb_demo_app/lib/
     inflating: sdb_demo_app/lib/ojdbc8.jar  
      creating: __MACOSX/sdb_demo_app/lib/
     inflating: __MACOSX/sdb_demo_app/lib/._ojdbc8.jar  
     inflating: sdb_demo_app/lib/ons.jar  
     inflating: __MACOSX/sdb_demo_app/lib/._ons.jar  
     inflating: sdb_demo_app/lib/ucp.jar  
     inflating: __MACOSX/sdb_demo_app/lib/._ucp.jar  
     inflating: __MACOSX/sdb_demo_app/._lib  
     inflating: sdb_demo_app/logging.properties  
     inflating: __MACOSX/sdb_demo_app/._logging.properties  
     inflating: sdb_demo_app/monitor-install.sh  
     inflating: __MACOSX/sdb_demo_app/._monitor-install.sh  
     inflating: sdb_demo_app/monitor.logging.properties  
     inflating: __MACOSX/sdb_demo_app/._monitor.logging.properties  
     inflating: sdb_demo_app/monitor.sh  
     inflating: __MACOSX/sdb_demo_app/._monitor.sh  
     inflating: sdb_demo_app/README _SDB_Demo_Application.pdf  
     inflating: __MACOSX/sdb_demo_app/._README _SDB_Demo_Application.pdf  
     inflating: sdb_demo_app/run.sh     
     inflating: __MACOSX/sdb_demo_app/._run.sh  
      creating: sdb_demo_app/sql/
     inflating: sdb_demo_app/sql/app_schema_auto.sql  
     inflating: sdb_demo_app/sql/app_schema_user.sql  
     inflating: sdb_demo_app/sql/catalog_monitor.sql  
      creating: __MACOSX/sdb_demo_app/sql/
     inflating: __MACOSX/sdb_demo_app/sql/._catalog_monitor.sql  
     inflating: sdb_demo_app/sql/demo_app_ext.sql  
     inflating: __MACOSX/sdb_demo_app/sql/._demo_app_ext.sql  
     inflating: sdb_demo_app/sql/global_views.header.sql  
     inflating: __MACOSX/sdb_demo_app/sql/._global_views.header.sql  
     inflating: sdb_demo_app/sql/global_views.sql  
     inflating: __MACOSX/sdb_demo_app/sql/._global_views.sql  
     inflating: sdb_demo_app/sql/shard_helpers.sql  
     inflating: __MACOSX/sdb_demo_app/sql/._shard_helpers.sql  
     inflating: __MACOSX/sdb_demo_app/._sql  
      creating: sdb_demo_app/src/
     inflating: sdb_demo_app/src/.DS_Store  
      creating: __MACOSX/sdb_demo_app/src/
     inflating: __MACOSX/sdb_demo_app/src/._.DS_Store  
      creating: sdb_demo_app/src/oracle/
     inflating: sdb_demo_app/src/oracle/ArgParser.java  
      creating: __MACOSX/sdb_demo_app/src/oracle/
     inflating: __MACOSX/sdb_demo_app/src/oracle/._ArgParser.java  
      creating: sdb_demo_app/src/oracle/demo/
      creating: sdb_demo_app/src/oracle/demo/actions/
     inflating: sdb_demo_app/src/oracle/demo/actions/AddProducts.java  
      creating: __MACOSX/sdb_demo_app/src/oracle/demo/
      creating: __MACOSX/sdb_demo_app/src/oracle/demo/actions/
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/actions/._AddProducts.java  
     inflating: sdb_demo_app/src/oracle/demo/actions/CreateOrder.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/actions/._CreateOrder.java  
     inflating: sdb_demo_app/src/oracle/demo/actions/CustomerAction.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/actions/._CustomerAction.java  
     inflating: sdb_demo_app/src/oracle/demo/actions/GenerateReport.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/actions/._GenerateReport.java  
     inflating: sdb_demo_app/src/oracle/demo/actions/OrderLookup.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/actions/._OrderLookup.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._actions  
     inflating: sdb_demo_app/src/oracle/demo/Actor.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._Actor.java  
     inflating: sdb_demo_app/src/oracle/demo/Application.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._Application.java  
     inflating: sdb_demo_app/src/oracle/demo/ApplicationException.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._ApplicationException.java  
     inflating: sdb_demo_app/src/oracle/demo/Customer.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._Customer.java  
     inflating: sdb_demo_app/src/oracle/demo/CustomerGenerator.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._CustomerGenerator.java  
     inflating: sdb_demo_app/src/oracle/demo/FillProducts.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._FillProducts.java  
     inflating: sdb_demo_app/src/oracle/demo/InfiniteGeneratingQueue.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._InfiniteGeneratingQueue.java  
     inflating: sdb_demo_app/src/oracle/demo/InstallSchema.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._InstallSchema.java  
     inflating: sdb_demo_app/src/oracle/demo/Main.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._Main.java  
     inflating: sdb_demo_app/src/oracle/demo/Product.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._Product.java  
     inflating: sdb_demo_app/src/oracle/demo/Session.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._Session.java  
     inflating: sdb_demo_app/src/oracle/demo/Statistics.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._Statistics.java  
     inflating: sdb_demo_app/src/oracle/demo/Test.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/demo/._Test.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/._demo  
     inflating: sdb_demo_app/src/oracle/JsonSerializer.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/._JsonSerializer.java  
      creating: sdb_demo_app/src/oracle/monitor/
     inflating: sdb_demo_app/src/oracle/monitor/DatabaseMonitor.java  
      creating: __MACOSX/sdb_demo_app/src/oracle/monitor/
     inflating: __MACOSX/sdb_demo_app/src/oracle/monitor/._DatabaseMonitor.java  
     inflating: sdb_demo_app/src/oracle/monitor/FileHandler.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/monitor/._FileHandler.java  
     inflating: sdb_demo_app/src/oracle/monitor/Install.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/monitor/._Install.java  
     inflating: sdb_demo_app/src/oracle/monitor/Main.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/monitor/._Main.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/._monitor  
     inflating: sdb_demo_app/src/oracle/RandomGenerator.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/._RandomGenerator.java  
     inflating: sdb_demo_app/src/oracle/SmartLogFormatter.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/._SmartLogFormatter.java  
     inflating: sdb_demo_app/src/oracle/Utils.java  
     inflating: __MACOSX/sdb_demo_app/src/oracle/._Utils.java  
     inflating: __MACOSX/sdb_demo_app/src/._oracle  
     inflating: __MACOSX/sdb_demo_app/._src  
      creating: sdb_demo_app/web/
     inflating: sdb_demo_app/web/bootstrap-theme.css  
      creating: __MACOSX/sdb_demo_app/web/
     inflating: __MACOSX/sdb_demo_app/web/._bootstrap-theme.css  
     inflating: sdb_demo_app/web/bootstrap-theme.min.css  
     inflating: __MACOSX/sdb_demo_app/web/._bootstrap-theme.min.css  
     inflating: sdb_demo_app/web/bootstrap.css  
     inflating: __MACOSX/sdb_demo_app/web/._bootstrap.css  
     inflating: sdb_demo_app/web/bootstrap.js  
     inflating: __MACOSX/sdb_demo_app/web/._bootstrap.js  
     inflating: sdb_demo_app/web/bootstrap.min.css  
     inflating: __MACOSX/sdb_demo_app/web/._bootstrap.min.css  
     inflating: sdb_demo_app/web/bootstrap.min.js  
     inflating: __MACOSX/sdb_demo_app/web/._bootstrap.min.js  
     inflating: sdb_demo_app/web/Chart.HorizontalBar.js  
     inflating: __MACOSX/sdb_demo_app/web/._Chart.HorizontalBar.js  
     inflating: sdb_demo_app/web/Chart.js  
     inflating: __MACOSX/sdb_demo_app/web/._Chart.js  
     inflating: sdb_demo_app/web/dash.html  
     inflating: __MACOSX/sdb_demo_app/web/._dash.html  
     inflating: sdb_demo_app/web/DatabaseWidgets.js  
     inflating: __MACOSX/sdb_demo_app/web/._DatabaseWidgets.js  
     inflating: sdb_demo_app/web/db.svg  
     inflating: __MACOSX/sdb_demo_app/web/._db.svg  
     inflating: sdb_demo_app/web/jquery-2.1.4.js  
     inflating: __MACOSX/sdb_demo_app/web/._jquery-2.1.4.js  
     inflating: sdb_demo_app/web/masonry.pkgd.js  
     inflating: __MACOSX/sdb_demo_app/web/._masonry.pkgd.js  
     inflating: sdb_demo_app/web/npm.js  
     inflating: __MACOSX/sdb_demo_app/web/._npm.js  
     inflating: __MACOSX/sdb_demo_app/._web  
     inflating: __MACOSX/._sdb_demo_app  
   [oracle@cata ~]$ 
   ```

   

4. Change to the `sdb_demo_app/sql` directory.

   ```
   [oracle@cata sql]$ <copy>cd ~/sdb_demo_app/sql</copy>
   [oracle@cata sql]$
   ```

   

5. View the content of the `demo_app_ext.sql`. Make sure the connect string is correct.

   ```
   [oracle@cata sql]$ <copy>cat demo_app_ext.sql</copy> 
   -- Create catalog monitor packages
   connect / as sysdba
   alter session set container=catapdb;
   @catalog_monitor.sql
   
   connect app_schema/app_schema@cata:1521/catapdb;
   
   alter session enable shard ddl;
   
   CREATE OR REPLACE VIEW SAMPLE_ORDERS AS
     SELECT OrderId, CustId, OrderDate, SumTotal FROM
       (SELECT * FROM ORDERS ORDER BY OrderId DESC)
         WHERE ROWNUM < 10;
   
   alter session disable shard ddl;
   
   -- Allow a special query for dbaview
   connect / as sysdba
   alter session set container=catapdb;
   
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

   

6. Using SQLPLUS connect as sysdba and run the script.

   ```
   [oracle@cata sql]$ sqlplus / as sysdba
   
   SQL*Plus: Release 19.0.0.0.0 - Production on Mon Nov 30 05:54:14 2020
   Version 19.7.0.0.0
   
   Copyright (c) 1982, 2020, Oracle.  All rights reserved.
   
   
   Connected to:
   Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
   Version 19.7.0.0.0
   
   SQL> @demo_app_ext.sql
   ```

   

7. The result likes the following.

   ```
   Connected.
   
   Session altered.
   
   
   Session altered.
   
   
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
   
   Session altered.
   
   
   View created.
   
   
   Session altered.
   
   Connected.
   
   Session altered.
   
   
   Grant succeeded.
   
   
   Session altered.
   
   
   User created.
   
   
   Grant succeeded.
   
   
   Grant succeeded.
   
   
   Grant succeeded.
   
   
   Session altered.
   
   
   PL/SQL procedure successfully completed.
   
   SQL> 
   ```

   

8. Change directory to the `sdb_demo_app`.

   ```
   [oracle@cata ~]$ cd ~/sdb_demo_app
   [oracle@cata sdb_demo_app]$ 
   ```

   

9. Modify the `demo.properties` file like the following. Because we have no data guard standby database setup in this lab, we also use the `oltp_rw_srvc.orasdb.oradbcloud` for the readonly service.

   ```
   name=demo
   connect_string=(ADDRESS_LIST=(LOAD_BALANCE=off)(FAILOVER=on)(ADDRESS=(HOST=cata)(PORT=1522)(PROTOCOL=tcp)))
   monitor.user=dbmonuser
   monitor.pass=TEZiPP4MsLLL
   #app.service.write=oltp_rw_srvc.cust_sdb.oradbcloud
   app.service.write=oltp_rw_srvc.orasdb.oradbcloud
   #app.service.readonly=oltp_ro_srvc.cust_sdb.oradbcloud
   app.service.readonly=oltp_rw_srvc.orasdb.oradbcloud
   app.user=app_schema
   app.pass=app_schema
   app.threads=7
   ```

   

   

## **Step 2:** Start the workload

1. Start the workload by executing command: `./run.sh demo`.

   ```
   [oracle@cata sdb_demo_app]$ <copy>./run.sh demo</copy>
   ```

   

2. The result likes the following.

   ```
   Performing initial fill of the products table...
   Syncing shards...
    RO Queries | RW Queries | RO Failed  | RW Failed  | APS 
             0            0            0            0            1
             0            0            0            0            0
            85            4            0            0           25
           639          109            0            0          191
          2508          451            0            0          636
          4731          783            0            0          746
          7212         1174            0            0          838
          9763         1543            0            0          871
         12269         1905            0            0          854
         14337         2265            0            0          701
         16250         2657            0            0          652
         18242         3020            0            0          674
         20548         3366            0            0          779
         22710         3697            0            0          742
         24959         4058            0            0          768
         26933         4405            1            0          675
         29219         4818            1            0          775
         31483         5202            1            0          758
         33654         5608            1            0          740
         36274         6092            1            0          891
    RO Queries | RW Queries | RO Failed  | RW Failed  | APS 
         38778         6546            1            0          845
         41267         6934            1            0          836
         43384         7299            1            0          727
         45840         7694            1            0          839
         48209         8066            1            0          820
         50467         8425            1            0          765
   ```

   

3. Open another terminal, connect to the catalog host, switch to oracle user. Change the directory to `sdb_demo_app`.

   ```
   $ ssh -i labkey opc@152.67.196.50
   Last login: Mon Nov 30 06:07:40 2020 from 202.45.129.206
   -bash: warning: setlocale: LC_CTYPE: cannot change locale (UTF-8): No such file or directory
   [opc@cata ~]$ sudo su - oracle
   Last login: Mon Nov 30 06:08:03 GMT 2020 on pts/0
   [oracle@cata ~]$ cd ~/sdb_demo_app
   [oracle@cata sdb_demo_app]$
   ```

   

4. Start the monitoring tool via the following command. Ignore the FileNotFoundException message.

   ```
    [oracle@cata sdb_demo_app]$ <copy>./run.sh monitor</copy>
   @oracle.monitor.Main.registerDatabase : INFO 2020-11-30T06:17:33.417 : Context : /db/demo/info
   @oracle.monitor.DatabaseMonitor$BackgroundStatusCheck.run : java.lang.ArrayIndexOutOfBoundsException : 2
   @oracle.monitor.DatabaseMonitor$BackgroundStatusCheck.run : java.lang.ArrayIndexOutOfBoundsException : 3
   java.io.FileNotFoundException: /favicon.ico
   	at oracle.monitor.FileHandler.handle(FileHandler.java:129)
   	at com.sun.net.httpserver.Filter$Chain.doFilter(Filter.java:79)
   	at sun.net.httpserver.AuthFilter.doFilter(AuthFilter.java:83)
   	at com.sun.net.httpserver.Filter$Chain.doFilter(Filter.java:82)
   	at sun.net.httpserver.ServerImpl$Exchange$LinkHandler.handle(ServerImpl.java:675)
   	at com.sun.net.httpserver.Filter$Chain.doFilter(Filter.java:79)
   	at sun.net.httpserver.ServerImpl$Exchange.run(ServerImpl.java:647)
   	at sun.net.httpserver.ServerImpl$DefaultExecutor.execute(ServerImpl.java:158)
   	at sun.net.httpserver.ServerImpl$Dispatcher.handle(ServerImpl.java:431)
   	at sun.net.httpserver.ServerImpl$Dispatcher.run(ServerImpl.java:396)
   	at java.lang.Thread.run(Thread.java:748)
   ```

   

5. From you laptop, launch a browser and use the URL: `http://xxx.xxx.xxx.xxx/8081`. Using the public ip address of the catalog host and the port number is 8081.

   ![image-20201130144513997](images/image-20201130144513997.png)

   

6. Scroll down the screen, you can see the Last inserted orders:

   ![image-20201130142515011](images/image-20201130142515011.png)

   

7. Press `Ctrl+C` to cancel the demo in both of the terminal.

   
You may proceed to the next lab.