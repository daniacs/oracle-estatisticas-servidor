#!/bin/bash
# Verifica a tablespace ja existe. 
# Se existir, nao cria o arquivo e retorna erro.

echo "*********************** $0 ************************"

VERIFICA=`sqlplus -s $DBA/$SENHADBA@$ORACLE_SID as sysdba <<EOF
  SET HEAD OFF
  SELECT TABLESPACE_NAME, FILE_NAME
  FROM SYS.DBA_DATA_FILES
  WHERE TABLESPACE_NAME='$TS_NAME';
  QUIT;
EOF`
VERIFICA_TS=`echo $VERIFICA | tr -d '\n' | awk '{print $1}'`
VERIFICA_DF=`echo $VERIFICA | tr -d '\n' | awk '{print $2}'`

# Gera o script de criacao da tablespace em $TS_SQLOUT
if [ "$VERIFICA_TS" = $TS_NAME ]; then
  echo "Ja existe a tablespace $TS_NAME em $VERIFICA_DF"
else
  echo "Criando tablespace $TS_NAME"
  TS_SQL=objetos/templates/01-create_tablespace.sql
  TS_SQLOUT=objetos/gerados/01-create_tablespace.sql
  rm -f $TS_SQLOUT
  cp $TS_SQL $TS_SQLOUT
  sed -i "s/@TS_NAME@/$TS_NAME/"           $TS_SQLOUT
  sed -i "s%@TS_DATAFILE@%$TS_DATAFILE%"   $TS_SQLOUT
  sed -i "s/@TS_SIZE@/$TS_SIZE/"           $TS_SQLOUT
  sed -i "s/@TS_MAXSIZE@/$TS_MAXSIZE/"     $TS_SQLOUT
  sqlplus $DBA/$SENHADBA@$ORACLE_SID as sysdba @$TS_SQLOUT
fi
echo
echo
exit
