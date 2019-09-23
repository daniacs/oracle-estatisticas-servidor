#!/bin/bash

. env.sh

echo "Concedendo GRANTS aos objetos criados"
ARQ_GRANTS=objetos/templates/20-grants.sql
GRANTS=objetos/gerados/20-grants.sql
sed  "s/@SCHEMA@/$USUARIO/g;" $ARQ_GRANTS >> $GRANTS
cat $GRANTS
sqlplus $DBA/$SENHADBA@$ORACLE_SID as sysdba @$GRANTS

echo "Limpando objetos gerados"
rm -rfv objetos/gerados/*
rm -rfv scripts/gerados/*

echo
echo
