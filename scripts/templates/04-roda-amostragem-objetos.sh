#!/bin/sh
# Insere dados de estatisticas de objetos em TESTATISTICAS_SEGMENTOS

. /etc/profile.d/oracle.sh
. @SETUSRSID@
SCRIPT=@SCRIPTS_DIR_STR@/roda-amostragem-objetos.sql
INSTANCIA=$ORACLE_SID

sqlplus $USUARIO@$INSTANCIA/$SENHA <<!FIM!
@$SCRIPT
!FIM!
