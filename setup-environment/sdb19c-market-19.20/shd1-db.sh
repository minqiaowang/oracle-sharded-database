#cloud-config
runcmd:
   - mount /u01
   - /u01/ocidb/GenerateNetconfig.sh > /u01/ocidb/netconfig.ini
   - SIDNAME=shd1 DBNAME=shd1 DBCA_PLUGGABLE_DB_NAME=shdpdb1 /u01/ocidb/buildsingle.sh -s