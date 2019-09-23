#!/bin/bash
# Verifica se a estrutura de diretorios esta correta

echo "*********************** $0 ************************"

OBJDIR_SRC=objetos/templates
OBJDIR_DST=objetos/gerados
SCRIPTS_SRC=scripts/templates
SCRIPTS_DST=scripts/gerados

if ! [ -d $OBJDIR_SRC  -a -d $SCRIPTS_SRC ]; then
  echo "ERRO: Faltando diretorio $OBJDIR_SRC ou $SCRIPTS_SRC"
  echo "Abortar a instalacao"
  exit 1
fi

if ! [ -d $OBJDIR_DST ]; then
  echo "Diretorio $OBJDIR_DST nao existe. Criando.."
  mkdir -p $OBJDIR_DST
fi

if ! [ -d $SCRIPTS_DST ]; then
  echo "Diretorio $SCRIPTS_DST nao existe. Criando.."
  mkdir -p $SCRIPTS_DST
fi

echo
echo
exit 0
