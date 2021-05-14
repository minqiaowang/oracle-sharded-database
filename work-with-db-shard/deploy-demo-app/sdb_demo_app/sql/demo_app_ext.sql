-- Create catalog monitor packages
connect sys/your-own-sys-password@sdbsc0:1521/sdbpdb as sysdba
@catalog_monitor.sql

connect app_schema/App_Schema_Pass_123@sdbsc0:1521/sdbpdb;

alter session enable shard ddl;

CREATE OR REPLACE VIEW SAMPLE_ORDERS AS
  SELECT OrderId, CustId, OrderDate, SumTotal FROM
    (SELECT * FROM ORDERS ORDER BY OrderId DESC)
      WHERE ROWNUM < 10;

alter session disable shard ddl;

-- Allow a special query for dbaview
connect sys/your-own-sys-password@sdbsc0:1521/sdbpdb as sysdba

-- For demo app purposes
grant shard_monitor_role, gsmadmin_role to app_schema;

alter session enable shard ddl;

create user dbmonuser identified by TEZiPP4_MsLLL_1;
grant connect, alter session, shard_monitor_role, gsmadmin_role to dbmonuser;

grant all privileges on app_schema.products to dbmonuser;
grant read on app_schema.sample_orders to dbmonuser;

alter session disable shard ddl;
-- End workaround

exec dbms_global_views.create_any_view('SAMPLE_ORDERS', 'APP_SCHEMA.SAMPLE_ORDERS', 'GLOBAL_SAMPLE_ORDERS', 0, 1);
