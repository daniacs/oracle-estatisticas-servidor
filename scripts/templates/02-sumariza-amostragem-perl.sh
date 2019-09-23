#!/bin/sh
# TODO: explicar o porque dos parametros

ONTEM=`date --date='yesterday' +'%d%m%Y'`
HOJE=`date +'%d%m%Y'`
AMANHA=`date --date='tomorrow' +'%d%m%Y'`
HORA=`date +%H`
OPTS=" --tabin TESTATISTICAS_RAC "

# CURRENT: Estatisticas do dia, a partir de 0:00 (TABELA TEMPORARIA)
# CURRENT_WORKTIME: Estatisticas do dia, a partir das 7:30 as 22:15 (TABELA TEMPORARIA)
# WORKTIME: Agregar a tabela de historico com as estatisticas de 7:30 as 22:15
# SEM PARAMETRO: Agregar a tabela de historico com as estatisticas de 0:00 as 23:00

if [ "$1" == "CURRENT" ]; then
  OPTS="$OPTS --inicio $HOJE --fim $AMANHA --tabout TANALISE_ESTATISTICAS --truncate "
elif [ "$1" == "CURRENT_WORKTIME" ]; then
  OPTS="$OPTS --inicio $HOJE --fim $AMANHA --tabout TANALISE_ESTATISTICAS --worktime --truncate "
elif [ "$1" == "WORKTIME" ]; then
  OPTS="$OPTS --inicio $HOJE --fim $AMANHA --tabout TANALISE_ESTATISTICAS_HORA --worktime "
else
  OPTS="$OPTS --inicio $ONTEM --fim $HOJE --tabout TANALISE_ESTATISTICAS_HORA24 "
fi

#cd $ORACLE_HOME/plus/admin/estatisticas
cd @SCRIPTS_DIR_STR@
#echo $ORACLE_HOME/plus/admin/estatisticas/sumariza-amostragem.pl $OPTS
echo @SCRIPTS_DIR_STR@/sumariza-amostragem.pl $OPTS
#$ORACLE_HOME/plus/admin/estatisticas/sumariza-amostragem.pl $OPTS
@SCRIPTS_DIR_STR@/sumariza-amostragem.pl $OPTS
