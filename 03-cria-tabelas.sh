#!/bin/bash
# Verifica na lista de tabelas se alguma ja existe
# O script so cria as tabelas se nenhuma delas existir no banco

echo "*********************** $0 ************************"

ARQ_LISTA="objetos/lista-objetos.txt"
LISTA_TABELAS=`cat $ARQ_LISTA | awk '{print $1}' |
  sed "s/\([A-Z0-9_]*\)/'\1'/g" | tr '\n' ',' | sed 's/,$//'`;
LISTA_TABELAS_SQL=`cat $ARQ_LISTA | awk '{print $2}'`
TMPFILE=`mktemp`

LC_ALL=C sqlplus -s  $USUARIO/$SENHA@$ORACLE_SID <<EOF >$TMPFILE
  SET HEAD OFF
  SET FEEDBACK OFF
  SELECT TABLE_NAME
  FROM USER_TABLES
  WHERE TABLE_NAME IN ($LISTA_TABELAS);
  QUIT;
EOF

# Verificar quantas tabelas da lista foram registradas
# na lista temporaria
EXISTENTES=`grep -v ^$ $TMPFILE | wc -l`

if [ $EXISTENTES -lt 1 ]; then
  cat $ARQ_LISTA | while read tabela sql_arq; do
    TAB_SQL=objetos/templates/$sql_arq
    TAB_SQLOUT=objetos/gerados/$sql_arq
    rm -f $TAB_SQLOUT
    cp $TAB_SQL $TAB_SQLOUT
    sed -i "s/@SCHEMA@/$USUARIO/"  $TAB_SQLOUT
    sed -i "s/@TS_NAME@/$TS_NAME/" $TAB_SQLOUT
    echo "Criando $tabela"
    sqlplus -s $USUARIO/$SENHA@$ORACLE_SID @$TAB_SQLOUT
  done
else
  echo "As seguintes tabelas ja existem no schema $USUARIO:"
  cat $TMPFILE
  echo "Remove-las ou cria-las em outro schema/user"
fi
rm $TMPFILE

echo
echo
exit
