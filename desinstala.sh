#!/bin/bash

# Desinstalacao dos objetos
. env.sh

if [ "$SENHA" = "" -o "$SENHADBA" = "" ]; then
  echo "Configurar corretamente os parametros no arquivo env.sh"
  exit 1
fi

# Confirmacao se deve remover o usuario e / ou a tablespace
printf "Remover o usuario $USUARIO e TODOS os objetos contidos no schema s/[n]/c? "
read REMOVE_USUARIO
if [ "$REMOVE_USUARIO" = "s" -o "$REMOVE_USUARIO" = "S" ]; then
  echo "Usuario $USUARIO sera removido com todos os objetos"
  printf "TEM MESMO CERTEZA s/[n]?????? "
  read REMOVE_USUARIO
elif [ "$REMOVE_USUARIO" = "c" -o "$REMOVE_USUARIO" = "C" ]; then
  echo "Desinstalacao interrompida"
  exit 0;
fi

printf "Remover a tablespace $TS_NAME e TODOS os objetos contidos nela s/[n]/c? "
read REMOVE_TABLESPACE
if [ "$REMOVE_TABLESPACE" = "s" -o "$REMOVE_TABLESPACE" = "S" ]; then
  echo "Tablespace $TABLESPACE sera removida com todos os objetos"
elif [ "$REMOVE_TABLESPACE" = "c" -o "$REMOVE_TABLESPACE" = "C" ]; then
  echo "Desinstalacao interrompida"
  exit 0;
fi

LOG=desinstala.log

[ -f $LOG ] && rm -f $LOG

# Remocao da crontab
echo "Removendo entradas do crontab"
CRONTMP=`mktemp`
crontab -l >$CRONTMP
for script in `cat scripts/lista-objetos.txt | grep CRON | awk '{print $3}'`;
do
  script=`echo $script | sed 's/^[^-]*-//'`
  sed -i "/$script/ d" $CRONTMP
done
sed -i "/#### Estatisticas do Oracle/ d" $CRONTMP
crontab $CRONTMP
rm -f $CRONTMP


# Remocao das procedures e triggers
echo "Removendo procedures e triggers"
OBJS=`cat scripts/lista-objetos.txt | grep ^OBJETO | awk '{print $2}'`
for obj in $OBJS; do
  objeto=${obj#*/}
  tipo=${obj%/*}
  if [ "$tipo" = "P" ]; then
    SQL="DROP PROCEDURE $USUARIO.$objeto"
  elif [ "$tipo" = "T" ]; then
    SQL="DROP TRIGGER $USUARIO.$objeto"
  fi
  SQLSYN="DROP PUBLIC SYNONYM $objeto"

  echo "  Removendo $tipo $objeto"
  if [ "$SQL" != "" ]; then
    sqlplus $DBA/$SENHADBA@$ORACLE_SID as sysdba <<EOF >>$LOG
    SET ECHO ON;
    $SQL;
    $SQLSYN;
    QUIT;
EOF
  fi
done


# Remocao das tabelas
echo "Removendo as tabelas"
OBJS=`cat objetos/lista-objetos.txt | awk '{print $1}'`
for obj in $OBJS; do
  SQL="DROP TABLE $USUARIO.$obj"
  SQLSYN="DROP PUBLIC SYNONYM $obj"

  echo "  Removendo tabela $obj"
  echo $SQL >>$LOG
    sqlplus $DBA/$SENHADBA@$ORACLE_SID as sysdba <<EOF >>$LOG
    SET ECHO ON;
    $SQL;
    $SQLSYN;
    QUIT;
EOF
done

# Remocao do usuario
if [ "$REMOVE_USUARIO" = "s" -o "$REMOVE_USUARIO" = "S" ]; then
  echo "REMOVENDO USUARIO $USUARIO"
  SQL="DROP USER $USUARIO CASCADE"
  echo $SQL >>$LOG
      sqlplus $DBA/$SENHADBA@$ORACLE_SID as sysdba <<EOF >>$LOG
      SET ECHO ON;
      $SQL;
      QUIT;
EOF
else
  echo "Usuario $USUARIO nao removido"
fi

# Remocao da tablespace
if [ "$REMOVE_TABLESPACE" = "s" -o "$REMOVE_TABLESPACE" = "S" ]; then
  echo "Removendo TABLESPACE $TS_NAME e todos os seus objetos"
  SQL="DROP TABLESPACE $TS_NAME INCLUDING CONTENTS AND DATAFILES"
  echo $SQL >> $LOG
      sqlplus $DBA/$SENHADBA@$ORACLE_SID as sysdba <<EOF >>$LOG
      SET ECHO ON;
      $SQL;
      QUIT;
EOF
  # Em teoria ja deveria ter sido removido no comando DROP TABLESPACE ...
  rm -fv $TS_DATAFILE >>$LOG
else
  echo "Tablespace $TS_NAME nao removida"
fi

# Remocao dos scripts
if [ "$SCRIPTS_DIR" != "" ]; then
  echo "Removendo os scripts em $SCRIPTS_DIR/"
  rm -rfv $SCRIPTS_DIR/* >>$LOG
fi
