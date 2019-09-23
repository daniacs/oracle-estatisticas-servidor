#!/bin/sh

. /etc/profile.d/oracle.sh
. @SETUSRSID@
PATH=$PATH:$ORACLE_HOME/bin:$ORACLE_HOME/lbin
NLS_LANG="BRAZILIAN PORTUGUESE"_BRAZIL.WE8DEC
export PATH
export NLS_LANG

DIR=`dirname $0`
EXE=`basename $0`
ARQ=${EXE%.*}
LOG="$DIR/${ARQ}.log"
SCRIPT=@SCRIPTS_DIR_STR@/sumariza-amostragem.sql

printf "Agrupando as estatisticas em TDW_ESTATISTICAS_RAC " > $LOG
echo "e removendo registros antigos." >> $LOG
date >> $LOG

sqlplus -s 2>&1 >>$LOG <<!FIM!
$USUARIO/$SENHA
@$SCRIPT
!FIM!

echo "Termino do script $EXE" >>$LOG
date >> $LOG

cat $LOG | mail -s "Arquiva amostragem" gti-dba@almg.gov.br
