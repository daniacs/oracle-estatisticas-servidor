#!/bin/bash

echo "*********************** $0 ************************"

# Arquivos que serao copiados e executados pela crontab
ARQ_LISTA="scripts/lista-objetos.txt"
ARQ_CRON=`mktemp`
BKP_CRON=/tmp/crontab.$USER.backup

crontab -l > $ARQ_CRON
cp -f $ARQ_CRON $BKP_CRON

echo "Incluindo as entradas no crontab"
echo "############################ Estatisticas do Oracle" >>$ARQ_CRON
cat $ARQ_LISTA | grep ^ENTRY | while read col1 arq resto; do
  ARQ_DEST=`echo $arq| sed 's/^[^-]*-//'`
  ARQ_DEST="$SCRIPTS_DIR_STR/$ARQ_DEST"
  HORARIO=`echo $resto | awk -F '+' '{print $1}'`
  PARAMS=`echo $resto | awk -F '+' '{print $2}'`
  if  [ ! "$PARAMS" = "" ]; then
    echo "$HORARIO $ARQ_DEST $PARAMS"
  else
    echo "$HORARIO $ARQ_DEST" | tr '@' '*' >>$ARQ_CRON
  fi
done
crontab $ARQ_CRON
rm -f $ARQ_CRON
echo "Crontab atualizada. Backup criado em $BKP_CRON"


echo
echo
