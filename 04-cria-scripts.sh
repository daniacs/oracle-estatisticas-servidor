#!/bin/bash

echo "*********************** $0 ************************"

# Cria o diretorio de arquivos gerados temporariamente
! [ -d scripts/gerados ] && mkdir scripts/gerados

# Cria o diretorio que contem os scripts que serao executados
if [ -d $SCRIPTS_DIR ]; then
  echo "Diretorio $SCRIPTS_DIR existe!"
else
  echo "Criando diretorio $SCRIPTS_DIR"
  mkdir -p $SCRIPTS_DIR
fi

# Arquivos que serao copiados e executados pela crontab
ARQ_LISTA="scripts/lista-objetos.txt"

cat $ARQ_LISTA | grep ^SCRIPT | while read col1 tipo arq; do
  ARQ_TEMPLATE=scripts/templates/$arq
  ARQ_OUT=scripts/gerados/$arq
  ARQ_DEST=`echo $arq| sed 's/^[^-]*-//'`
  cp -rf $ARQ_TEMPLATE $ARQ_OUT

  # Subdiretorios nao devem usar template
  # Sao copiados diretamente para o destino
  if [ "$tipo" = "DIR" ]; then
    cp -vr $ARQ_TEMPLATE $SCRIPTS_DIR
  else
    sed -i "s!@SETUSRSID@!$SCRIPT_LOGIN_STR!"        $ARQ_OUT
    sed -i "s!@SCRIPTS_DIR@!$SCRIPTS_DIR!"           $ARQ_OUT
    sed -i "s!@SCRIPTS_DIR_STR@!$SCRIPTS_DIR_STR!"   $ARQ_OUT
    sed -i "s!@SCRIPT@!$SCRIPTS_DIR_STR/$ARQ_DEST!"  $ARQ_OUT
    sed -i "s!@ENC_ORAPWD@!$ENC_ORAPWD!"             $ARQ_OUT
    sed -i "s!@ORACLE_SRV@!$ORACLE_SRV!"             $ARQ_OUT
    sed -i "s!@ORACLE_SID@!$ORACLE_SID!"             $ARQ_OUT
    sed -i "s!@USUARIO@!$USUARIO!"             $ARQ_OUT
    cp -v $ARQ_OUT $SCRIPTS_DIR/$ARQ_DEST
    if [ "$tipo" = "CRON" ]; then
      chmod 755 $SCRIPTS_DIR/$ARQ_DEST
    fi
  fi
  echo
done

echo
echo
exit
