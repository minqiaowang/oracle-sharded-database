#cloud-config
runcmd:
   - mount /u01
   - /u01/ocidb/GenerateNetconfig.sh > /u01/ocidb/netconfig.ini
   - SIDNAME=cata DBNAME=cata DBCA_PLUGGABLE_DB_NAME=catapdb /u01/ocidb/buildsingle.sh -s