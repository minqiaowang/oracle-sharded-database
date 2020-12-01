#!/bin/sh
CSTR='(description=(ADDRESS=(HOST=shard0)(PORT=1571)(PROTOCOL=tcp))(connect_data=(service_name=GDS$CATALOG.oradbcloud)))'
echo -e '@sql/1_dba_global_views.sql\n' | sqlplus -S sys/oracle@$CSTR as sysdba
echo -e '@sql/b3_mon_views.sql\n' | sqlplus -S app_schema/app_schema@$CSTR
echo -e '@sql/b4_mon_all.sql\n' | sqlplus -S sys/oracle@$CSTR as sysdba
