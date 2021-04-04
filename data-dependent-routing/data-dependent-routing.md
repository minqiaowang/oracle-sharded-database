# Data Dependent Routing

## Introduction
In this lab you will understand how the routing works when a `sharding_key` is specified using SQL*Plus. For production application scenario, you would be using Oracle Integrated Connection pools – UCP, OCI, ODP.NET, JDBC etc which will allow direct routing based on the `sharding_key`. 

Estimated Lab Time: 30 minutes.

### Objectives

In this lab, you will perform the following steps:
- Connect to a shard by specifying a `sharding_key` - via the shard director.
- Connect to the shardcatalog via `GDS$CATALOG` service.

### Prerequisites

This lab assumes you have already completed the following:
- Sharded Database Deployment
- Create Demo App Schema

## **Step 1:** Connect to a Shard by a Sharding key

1. Login to the catalog host, switch to oracle user.

   ```
   $ ssh -i labkey opc@xxx.xxx.xxx.xxx
   Last login: Mon Nov 30 03:06:29 2020 from 202.45.129.206
   -bash: warning: setlocale: LC_CTYPE: cannot change locale (UTF-8): No such file or directory
   [opc@cata ~]$ sudo su - oracle
   Last login: Mon Nov 30 03:06:34 GMT 2020 on pts/0
   [oracle@cata ~]$ 
   ```
   

   
3. For single-shard queries, direct routing to a shard with a given sharding_key.

   ```
   [oracle@cata ~]$ <copy>sqlplus app_schema/app_schema@'(description=(address=(protocol=tcp)(host=cata)(port=1522))(connect_data=(service_name=oltp_rw_srvc.orasdb.oradbcloud)(region=region1)(SHARDING_KEY=james.parker@x.bogus)))'</copy>
   
   SQL*Plus: Release 19.0.0.0.0 - Production on Mon Nov 30 04:24:10 2020
   Version 19.3.0.0.0
   
   Copyright (c) 1982, 2019, Oracle.  All rights reserved.
   
   Last Successful login time: Mon Nov 30 2020 03:19:10 +00:00
   
   Connected to:
   Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
   Version 19.10.0.0.0
   
   SQL> 
   ```

   

4. Insert a record and commit.

   ```
   SQL> <copy>INSERT INTO Customers (CustId, FirstName, LastName, CustProfile, Class, Geo, Passwd) VALUES ('james.parker@x.bogus', 'James', 'Parker', NULL, 'Gold', 'east', hextoraw('8d1c00e'));</copy>
   
   1 row created.
   
   SQL> commit;
   
   Commit complete.
   
   SQL> 
   ```

   

5. Check current connected shard database. 

   ```
   SQL> <copy>select db_unique_name from v$database;</copy>
   
   DB_UNIQUE_NAME
   ------------------------------
   shd1
   
   SQL> 
   ```

   

6. Select from the customer table. You can see there is one record which you just insert in the table.

   ```
   SQL> <copy>select * from customers where custid in('james.parker@x.bogus','tom.edwards');</copy>
   
   CUSTID
   ------------------------------------------------------------
   FIRSTNAME
   ------------------------------------------------------------
   LASTNAME						     CLASS	GEO
   ------------------------------------------------------------ ---------- --------
   CUSTPROFILE
   --------------------------------------------------------------------------------
   PASSWD
   --------------------------------------------------------------------------------
   james.parker@x.bogus
   James
   Parker							     Gold	east
   
   CUSTID
   ------------------------------------------------------------
   FIRSTNAME
   ------------------------------------------------------------
   LASTNAME						     CLASS	GEO
   ------------------------------------------------------------ ---------- --------
   CUSTPROFILE
   --------------------------------------------------------------------------------
   PASSWD
   --------------------------------------------------------------------------------
   
   08D1C00E
   
   
   SQL> 
   ```

   

7. Exit from the sqlplus.

   ```
   SQL> exit
   Disconnected from Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
   Version 19.10.0.0.0
   [oracle@cata ~]$ 
   ```

   

8. Connect to a shard with another shard key.

   ```
   [oracle@cata ~]$ <copy>sqlplus app_schema/app_schema@'(description=(address=(protocol=tcp)(host=cata)(port=1522))(connect_data=(service_name=oltp_rw_srvc.orasdb.oradbcloud)(region=region1)(SHARDING_KEY=tom.edwards@x.bogus)))'</copy>
   
   SQL*Plus: Release 19.0.0.0.0 - Production on Mon Nov 30 04:36:45 2020
   Version 19.3.0.0.0
   
   Copyright (c) 1982, 2019, Oracle.  All rights reserved.
   
   Last Successful login time: Mon Nov 30 2020 02:54:14 +00:00
   
   Connected to:
   Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
   Version 19.10.0.0.0
   
   SQL> 
   ```

   

9. Insert another record and commit.

   ```
   SQL> <copy>INSERT INTO Customers (CustId, FirstName, LastName, CustProfile, Class, Geo, Passwd) VALUES ('tom.edwards@x.bogus', 'Tom', 'Edwards', NULL, 'Gold', 'west', hextoraw('9a3b00c'));</copy>
   
   1 row created.
   
   SQL> commit;
   
   Commit complete.
   
   SQL> 
   ```

   

10. Check current connected shard database.

    ```
    SQL> <copy>select db_unique_name from v$database;</copy>
    
    DB_UNIQUE_NAME
    ------------------------------
    shd2
    
    SQL> 
    ```

    

11. Select from the table. You can see there is only one record in the shard2 database.

    ```
    SQL> <copy>select * from customers where custid in('james.parker@x.bogus','tom.edwards');</copy>
    
    CUSTID
    ------------------------------------------------------------
    FIRSTNAME
    ------------------------------------------------------------
    LASTNAME						     CLASS	GEO
    ------------------------------------------------------------ ---------- --------
    CUSTPROFILE
    --------------------------------------------------------------------------------
    PASSWD
    --------------------------------------------------------------------------------
    tom.edwards@x.bogus
    Tom
    Edwards							     Gold	west
    
    CUSTID
    ------------------------------------------------------------
    FIRSTNAME
    ------------------------------------------------------------
    LASTNAME						     CLASS	GEO
    ------------------------------------------------------------ ---------- --------
    CUSTPROFILE
    --------------------------------------------------------------------------------
    PASSWD
    --------------------------------------------------------------------------------
    
    09A3B00C
    
    
    SQL> 
    ```

    

12. Exit from the sqlplus.

    ```
    SQL> exit
    Disconnected from Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
    Version 19.10.0.0.0
    [oracle@cata ~]$ 
    ```

    

## **Step 2:** Cross Shard Query

1. Connect to the shardcatalog (coordinator database) using the GDS$CATALOG service (from catalog or any shard host):

   ```
   [oracle@cata ~]$ <copy>sqlplus app_schema/app_schema@cata:1522/GDS\$CATALOG.oradbcloud</copy>
   
   SQL*Plus: Release 19.0.0.0.0 - Production on Mon Nov 30 04:49:23 2020
   Version 19.3.0.0.0
   
   Copyright (c) 1982, 2019, Oracle.  All rights reserved.
   
   Last Successful login time: Mon Nov 30 2020 04:49:02 +00:00
   
   Connected to:
   Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
   Version 19.10.0.0.0
   
   SQL> 
   ```

   

2. Select records from customers table. You can see all the records are selected.

   ```
   SQL> <copy>select custid from customers where custid in('james.parker@x.bogus','tom.edwards');</copy>
   
   CUSTID
   ------------------------------------------------------------
   james.parker@x.bogus
   tom.edwards@x.bogus
   
   SQL> 
   ```

   

3. Check current connected database.

   ```
   SQL> <copy>select db_unique_name from v$database;</copy>
   
   DB_UNIQUE_NAME
   ------------------------------
   cata
   
   SQL> 
   ```

   

4. Exit from the sqlplus

   ```
   
   SQL> exit
   Disconnected from Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
   Version 19.10.0.0.0
   [oracle@cata ~]$ 
   ```

   

You may proceed to the next lab.