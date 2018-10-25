#!/bin/bash

echo "*********************** $0 ************************"

if [ -d $SCRIPT_LOGIN_DIR ]; then
  echo "Diretorio $SCRIPT_LOGIN_DIR ja existe."
else
  echo "Criando diretorio $SCRIPT_LOGIN_DIR"
  mkdir -p $SCRIPT_LOGIN_DIR
fi

# TODO: criar um perl pra gravar esse arquivo em binario
echo "Gerando arquivo $SCRIPT_LOGIN"
cat <<EOF >$SCRIPT_LOGIN
export ORACLE_SID=$ORACLE_SID
USUARIO=$USUARIO
SENHA=$SENHA
EOF

chmod 700 $SCRIPT_LOGIN


# Geracao de arquivo criptografado:
echo "Gerando senha criptografada"
AUX=`mktemp`
printf "$SENHA" > $AUX
$SCRIPTS_DIR/gera-senha.pl $AUX
mv /tmp/pwd.enc $ENC_ORAPWD
chown oracle $ENC_ORAPWD
chmod 600 $ENC_ORAPWD

echo
echo
exit
