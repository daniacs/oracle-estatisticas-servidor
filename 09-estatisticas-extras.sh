#!/bin/bash
# Verifica na lista de tabelas se alguma ja existe
# O script so cria as tabelas se nenhuma delas existir no banco

. env.sh

echo "*********************** $0 ************************"
echo
ARQ="objetos/templates/05-ttipo_estatistica_rac-extra.sql"
SQL="objetos/gerados/05-ttipo_estatistica_rac-extra.sql"
TAB="TTIPO_ESTATISTICA_RAC"

EXISTE=`sqlplus -s  $USUARIO/$SENHA@$ORACLE_SID <<EOF | grep $TAB
  SET HEAD OFF
  SET FEEDBACK OFF
  SELECT TABLE_NAME
  FROM USER_TABLES
  WHERE TABLE_NAME = '$TAB';
  QUIT;
EOF`

if [ "$EXISTE" = "$TAB" ]; then
  cp $ARQ $SQL
  echo "Inserindo valores extras em $TAB"
  echo "************ IMPORTANTE *******************"
  echo "Tabela TESTATISTICAS_RAC ira crescer MUITO rapido."
  echo "Atentar para os procedimentos de arquivamento da mesma!"
  sqlplus $USUARIO/$SENHA@$ORACLE_SID @$SQL
else
  echo "A tabela $TAB nao existe no banco de dados."
  echo "Ou a instalacao nao foi feita ou algum procedimento falhou!"
  echo "Verificar os logs de instalacao em $INSTALL_LOG"
fi

echo
echo
exit
