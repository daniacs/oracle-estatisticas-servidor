HOJE=`date +'%d%m%Y'`
AMANHA=`date --date='tomorrow' +'%d%m%Y'`
HORA=`date +%H`
OPTS=" --inicio $HOJE --fim $AMANHA --tabin TESTATISTICAS_RAC --tabout TANALISE_ESTATISTICAS_SESSOES --truncate "
if [ $HORA -ge 7 ]; then
  OPTS="$OPTS --worktime"
fi

cd @SCRIPTS_DIR_STR@
@SCRIPTS_DIR_STR@/analisa_sessoes.pl $OPTS
