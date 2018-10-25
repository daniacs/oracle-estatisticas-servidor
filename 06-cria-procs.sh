#!/bin/bash

echo "*********************** $0 ************************"

OBJ_DIR=$SCRIPTS_DIR/objetos

if [ -d $OBJ_DIR ]; then
  echo "Diretorio $OBJ_DIR existe!"
else
  echo "Criando diretorio $OBJ_DIR"
  mkdir -p $OBJ_DIR
fi

ARQ_LISTA="scripts/lista-objetos.txt"
cat $ARQ_LISTA | grep ^OBJETO | while read col1 obj arq; do
  ARQ_TEMPLATE=scripts/templates/$arq
  ARQ_OUT=scripts/gerados/$arq
  ARQ_DEST=`echo $arq| sed 's/^[^-]*-//'`
  cp -f $ARQ_TEMPLATE $ARQ_OUT
  sed -i "s!@SCHEMA@!$USUARIO!"  $ARQ_OUT
  echo "Criando objeto $obj"
  sqlplus $USUARIO/$SENHA@$ORACLE_SID @$ARQ_OUT
  if [ $? -eq 0 ]; then
    echo "Objeto criado"
    cp $ARQ_OUT -v $OBJ_DIR/$ARQ_DEST
    echo; echo; echo;
  else
    echo "Falha ao criar objeto $ARQ_DEST"
  fi
done

echo
echo
