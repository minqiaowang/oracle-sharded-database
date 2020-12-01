#cloud-config
runcmd:
   - mount /u01
   - /u01/ocidb/GenerateNetconfig.sh > /u01/ocidb/netconfig.ini
   - SIDNAME=shd3 DBNAME=shd3 DBCA_PLUGGABLE_DB_NAME=shdpdb3 /u01/ocidb/buildsingle.sh -s