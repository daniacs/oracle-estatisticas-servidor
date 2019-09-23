#!/bin/bash

# Leitura dos parametros de instalacao/configuracao
echo "* Leitura dos parametros de instalacao/configuracao"
. env.sh

if [ "$SENHA" = "" -o "$SENHADBA" = "" ]; then
  echo "Configurar corretamente os parametros no arquivo env.sh"
  exit 1
fi

INSTALL_LOG=instala.log
[ -f $INSTALL_LOG ] && rm -f $INSTALL_LOG

# Checagem preliminar
./00-check.sh
if [ $? -ne 0 ]; then
  echo "Checagem preliminar falhou. Abortando a instalacao."
  exit 1
fi

# Criacao da tablespace
echo "* Criando a tablespace"
./01-cria-tablespace.sh >> $INSTALL_LOG

# Criacao do usuario
echo "* Criando o usuario/schema onde estarao os objetos"
./02-cria-schema.sh >> $INSTALL_LOG

# Cria as tabelas e vistas
echo "* Criando as tabelas de estatistica"
./03-cria-tabelas.sh >> $INSTALL_LOG

# Criacao dos scripts
echo "* Gerando os scripts"
./04-cria-scripts.sh >> $INSTALL_LOG

# Criacao dos objetos
echo "* Criando arquivo de parametros de login"
./05-gera-parametros-login.sh >> $INSTALL_LOG

# Criacao das procedures e triggers
echo "* Criando as procedures e triggers"
./06-cria-procs.sh >> $INSTALL_LOG

# Geracao da crontab para executar os scripts
echo "* Registro dos scripts no crontab do usuario $USER"
./07-gera-crontab.sh >> $INSTALL_LOG

echo "* Limpando arquivos gerados e concedendo os GRANTS"
./08-limpa-gerados.sh >> $INSTALL_LOG

#echo "***************************************************************"
#echo "   REMOVER OS PARAMETROS DE IDENTIFICACAO NO ARQUIVO env.sh"
#echo "***************************************************************"
