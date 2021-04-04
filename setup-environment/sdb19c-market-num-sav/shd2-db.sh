#cloud-config
runcmd:
   - mount /u01
   - /u01/ocidb/GenerateNetconfig.sh > /u01/ocidb/netconfig.ini
   - SIDNAME=shd2 DBNAME=shd2 DBCA_PLUGGABLE_DB_NAME=shdpdb2 /u01/ocidb/buildsingle.sh -s