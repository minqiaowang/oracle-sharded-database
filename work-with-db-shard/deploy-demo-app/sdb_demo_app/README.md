# Sharding Beta Demo

[Support Training Materials are here](https://orahub.oraclecorp.com/sharding/demo/wikis/introduction)

This demo consists of the workload simulation application and the monitoring tool.

## Requirements

* All the following commands are expected to be run under the environment, which
have `JAVA_HOME` set to JDK8 home and `ORACLE_HOME` set in such a way, that
`$ORACLE_HOME/jdk/bin/java` is a valid Java 8 executable.

* You need an `ant` tool to build the application, which can be downloaded from
[Apache Ant](http://ant.apache.org/ "Apache Ant"). It is also available from
most of the Linux package repositories.

* And for sure you need a sharding environment already set up. You can have any
number of chunks and database nodes, but this particular demo requires the catalog
set up for **automatic** sharding.

* Also the default application settings has gsm endpoint set to `localhost:1571`. If your gsm is on a
different port or different machine, please fix the `demo.properties` to provide a valid connect string.
Please note, that EZ-connect is not supported there.

## Installation

The steps below require the ORACLE environment to be set. It's recommended to use the **GSM** (Shard Director)
environment. `JAVA_HOME` should be set to the JDK8.

1. Extract zip file. All the following steps are described in assumption, that you are in the directory,
where the application files are extracted into.

    ```sh
    unzip demo.zip
    cd demo
    ```

2. Build the demo application. From the demo application directory run `ant`. It will create the `demo.jar`
file in the build directory.

    ```sh
    ant
    ```

    **Alternative**: if you have an already compiled jar file, you can put it into the build directory. I this case
    you will not need Apache ant at all.

3. Create application schema and users. For simple installation, go to `sql` directory and run `sqlplus`
to connect to sys as sysdba (you may need to switch to the catalog environment).
To create user execute `app_schema_user.sql` and to create a schema execute `app_schema_auto.sql`.
We provide you with a script to create all the important parts at `demo_app_ext.sql`. You can just run it from `sqlplus` as `sysdba`.

    Here is the example:

    ```sh
    # Switch to the catalog environment
    cd sql # (important!)
    sqlplus / as sysdba
    SQL>@demo_app_ext.sql
    ```

    **Note:** if you have a catalog on a different host, you may need to fix `all_auto.sql` file to provide the
    connection strings to your catalog database.

    **Important:** the script assumes that you have a default shardspace, named shardspaceora. If you have
    created a different shardspace, please fix `create tablespace set` statement in the `app_schema_auto.sql`
    script.

4. Create services for the application. The application requires one service for readonly workload and
one for read/write (you may have to switch back to GSM environment):

    ```sh
    gdsctl add service -service oltp_rw_srvc -role PRIMARY
    gdsctl start service -service oltp_rw_srvc
    gdsctl add service -service oltp_ro_srvc
    gdsctl start service -service oltp_ro_srvc
    ```

    **Note:** if you want to create services with different names OR you have different shard pool name,
    please fix the `demo.properties` file.

5. Run the application. From the demo (you may have to leave `sql` directory), run:

    ```sh
    ./run.sh demo
    ```

    The application will first populate the products table. The the 1-hour workload will be started.
    You can interrupt it any time with SIG_INT (Ctrl-C). You can also run it in background.

6. Run the monitoring tool in a separate terminal:

    ```sh
    ./run.sh monitor
    ```

    Please see the description of the monitoring app below.

## Sharding Schema

The schema for the application and the sharding syntax can be found in `sql/app_schema_auto.sql` file.
The schema demonstrates the following features:

* JSON fields. Note, that `varchar2` field is used for JSON due to the beta limitation. LOB fields are also supported.
* Child tables with references.
* Shard-local sequences.
* PL/SQL functions in shard environment.

## Demo Application

TBD

### Data Generation

In the data subdirectory there is a set of files with input data, used for generating random data.
All the input data are from the public domain and can be downloaded freely.

* data/first-f.txt  -- The set of the popular female first names
* data/first-m.txt  -- The set of the popular male first names
* data/last.txt  -- The set of the popular last names
* data/parts.txt  -- Input data for product generation: list of the Wikipedia automotive part articles.
* data/streets.txt  -- Input data for the address generation: list for US street names.
* data/us-places.txt  -- Input data for the address generation: list of US zip codes.

#### Customer generation

We use email as a customer ID in our demo application. The random customer email generation is a key point of
our data insertion process. The process is implemented by `oracle.demo.CustomerGenerator` class.
First, we randomly select a customer gender. Then, the email is generated as:
[random first name].[random last name]@x.bogus.

At first, there are no customers with the given names. But the total set of possible emails is limited and at
some point generated names start to collide with each other. We treat that as the returning customer.

### Workload

Demo application executes an open workload with 4 kinds of transactions.

1. **Create a customer order**. First, random customer name is generated. We connect to the shard, providing this
customer name as a key. Is the customer does not exist, we insert a new record into the `CUSTOMERS` table,
creating a new customer. Then, we add an order for that customer, randomly selecting a number of products from
the `PRODUCTS` duplicated table. Please check the `oracle.demo.actions.CreateOrder` class for the implementation.

2. **Lookup the list of orders**. Again, we connect with a randomly generated customer name.
If the customer exists, we acquire the full history of his orders. If the customer does not exist, we
select random products from the `PRODUCTS` table. Please check the `oracle.demo.actions.OrderLookup`
class for the implementation.

3. Once in while, we **create a new product**. Generate a random product name and insert a new product into
the `PRODUCTS` table. This query is executed on the catalog database. Please check `oracle.demo.actions.AddProducts`
class for implementation.

4. Execute **cross-shard query with report generation**. The report is the aggregation of sales (`LINE_ITEMS` table)
by products. This is executed on the catalog side. The report is then put into the `/tmp` directory.
Please see `oracle.demo.actions.GenerateReport` class.

## Monitoring Tool

The monitoring tool provides an example of simple DIY-style sharding 
management tools. It uses the `dbms_global_views` package (currently
still in beta).

The purpose of this demo is to show that it is possible to monitor the status 
of shards using only the catalog connection. In fact, the monitoring 
applocation does not make any connections to shards directly.

The `dbms_global_views` package creates a public `shard_dblinks_view` and a 
public dblink to each shard.

To run the monitoring demo, execute:

```
./run.sh monitor.sh
```

Note, it is normal to see some errors about missing files, like `favicon`.

### Screen Description

When the monitor is running it starts up the web server, which is by default
on `localhost:8081`. Currently it is only tested to work in the Firefox browser.
On the web page, you can find several demo widgets.

#### Shard Widgets

Each shard widget shows the shard name, its status, and the list of chunks,
which belong to that shard. It also shows the status of the chunk, by using 
different colors: yellow-ish chunk means read/write state, while red chunk means 
read-only state. The color transition can be noticed during chunk move.

#### Service Workload Widget

User Calls per Second (UCPS) value from the `gv$service_metric` view on 
each shard. The color of each line corresponds to the color, which is shown 
in the corresponding Shard widget (at the top).

This is queried as:
```
select PUBLIC_DBNAME, 0, 0, sum(CALLSPERSEC) 
  from SGV$SERVICEMETRIC 
    where service_name like 'oltp%' and group_id=10 group by PUBLIC_DBNAME
```

where `SGV$SERVICEMETRIC` is created by the `dbms_global_views` package as:

```
exec dbms_global_views.create_gv('SERVICEMETRIC');
```

where `create_gv` is a function which creates a catalog view, based on 
shards' `gv$` view.

#### Active Sessions

This chart shows the number of open **user** sessions to each of the databases.
Usually, even with the demo app running, this number is not very big due to 
low number of default threads (4) in the demo app.

#### Order Row Distribution

This chart shows the distribution of orders across partitions, which 
corresponds to particular chunks. This is gathered querying the view 
`GLOBAL_DBA_TAB_PARTITIONS`, which is defined as an aggregation view:

```
exec dbms_global_views.create_dba_view('DBA_TAB_PARTITIONS');
```

Note, that this is an aggregation across all the partitions, so the total
number of rows from this char is twice as the actual number of rows (in presence of
one standby per primary).

#### Order Table Sampling

This widget shows a random sample from recently inserted Order table rows.
The query is the aggregation of the `SAMPLE_ORDERS` view, which is defined 
on __each shard__ as follows:

```
CREATE OR REPLACE VIEW SAMPLE_ORDERS AS
  SELECT OrderId, CustId, OrderDate, SumTotal FROM
    (SELECT * FROM ORDERS ORDER BY OrderId DESC)
      WHERE ROWNUM < 10; 
```

# Troubleshooting

### After incremental deploy new shards are not represented in the monitor or monitor logs an exception

Since the monitoring package is in beta stage, there may be a problem
with shard list trigger. To manually update the monitored shard list,
execute the following line from sys as sysdba:

```
dbms_global_views.create_all_database_links();
```

### Monitoring tool only shows four or less shards

The problem may be in `open_links` parameter on the catalog database. 
You can check that by running `sqlplus / as sysdba` in the catalog environment 
and executing:

```
show parameter open_links
```

The value of this parameter determines the maximum number of shards
we can connect to. Set it to some higher number:

```
alter system set open_links=64 scope=SPFILE;
```

Resetting this parameter (SPFILE only) requires catalog restart.
