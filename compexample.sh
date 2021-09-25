#!/bin/bash
# Copyright (c) 2021 John Faturoti
#
# URL: https://www.linkedin.com/in/john-faturoti/
#
# AUTHOR: John Faturoti
#
# NAME: compexample.sh
#
# DESCRIPTION: component used for demo
#
# SUMMARY OF STEPS:
# 1. drop application schema (JOHN)
# 2. recreaate schema (JOHN)
# 3. add access controls 

# main
# declare variables
APPLICATION_SCHEMA=JOHN

# obtain password (hashed on terminal) for app schema
prompt="Enter Password '${APPLICATION_SCHEMA}' : "

while IFS= read -p "$prompt" -r -s -n 1 char
do
  if [[ $char == $'\0' ]]
  then
    break
  fi
 
  prompt='*'
  newpassword+="$char"
done

# recreate app schema
# grant ACL to app schema
sqlplus -S / as sysdba << EOF 
  SET NEWPAGE 0
  SET SPACE 0
  SET PAGESIZE 0
  SET VERIFY OFF
  SET MARKUP HTML OFF SPOOL OFF
  SET TERMOUT OFF
  SET LONG 100000
  SET TRIMSPOOL ON
  SET TIMING OFF
  
  set echo off
  set feedback off
  set heading off
  set linesize 200
  spool "/tmp/${APPLICATION_SCHEMA}.sql" 
  select 'create user ' || u.USERNAME || ' identified by values ''' || s.password || ''' default tablespace ' || u.DEFAULT_TABLESPACE  || ' temporary tablespace ' || u.TEMPORARY_TABLESPACE ||' quota unlimited on ' || u.DEFAULT_TABLESPACE || ';' from dba_users u, SYS.APPLICATION_SCHEMA$ s
  where u.USERNAME = s.NAME and u.USERNAME = '${APPLICATION_SCHEMA}';
  
  select 'grant ' || granted_role || ' to ' || grantee || ' with admin option' || ';' from dba_role_privs where grantee in (select username from dba_users where username = '${APPLICATION_SCHEMA}') and ADMIN_OPTION = 'YES';
  
  select 'grant ' || granted_role || ' to ' || grantee || ';' from dba_role_privs where grantee in (select username from dba_users where username  = '${APPLICATION_SCHEMA}');
  
  select 'grant ' || privilege || ' to ' || grantee || ';' from dba_sys_privs where grantee in (select username from dba_users where username = '${APPLICATION_SCHEMA}');
  
  select 'grant ' || privilege || ' on ' || owner || '.' || table_name || ' to '  || grantee ||' with grant option ' || ';' from dba_tab_privs where grantee in (select username from dba_users where username = '${APPLICATION_SCHEMA}') and grantable = 'YES';
  
  select 'grant ' || privilege || ' on ' || owner || '.' || table_name || ' to '  || grantee || ';' from dba_tab_privs where grantee in (select username from dba_users where username = '${APPLICATION_SCHEMA}') and grantable = 'NO';
  
  spool off
  
  drop user $APPLICATION_SCHEMA cascade;
  
  @/tmp/${APPLICATION_SCHEMA}.sql
  
  BEGIN
  DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE('/sys/acls/power_users.xml','${APPLICATION_SCHEMA}', TRUE, 'connect');
  END;
  /
	 
  EXIT;
EOF

impdp \'/ as sysdba\' directory=$impDir dumpfile=$dmpFile logfile=refresh_${ORACLE_SID}_`date +%m%d%y`.log
