#!/bin/sh
# Insere dados de todas as sessões ativas na TESTATISTICAS_RAC.

. /etc/profile.d/oracle.sh
. @SETUSRSID@
SCRIPT=@SCRIPTS_DIR_STR@/roda-amostragem.sql
INSTANCIA=$ORACLE_SID

sqlplus $USUARIO@$INSTANCIA/$SENHA <<!FIM!
@$SCRIPT
!FIM!
