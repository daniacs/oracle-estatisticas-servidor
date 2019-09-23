#!/bin/bash
# Verifica se o usuario que armazena as estatisticas ja existe.
# Se ja existir, nao gera a SQL que cria o usuario.

echo "*********************** $0 ************************"

# Usuario no oracle eh sempre maiusculo
USUARIO=`echo $USUARIO | tr 'a-z' 'A-Z'`

echo "Verificando se existe o usuario $USUARIO"
VERIFICA=`sqlplus -s $DBA/$SENHADBA@$ORACLE_SID as sysdba <<EOF
  SET HEAD OFF
  SELECT USERNAME
  FROM SYS.DBA_USERS
  WHERE USERNAME=UPPER('$USUARIO');
  QUIT;
EOF`
VERIFICA=`echo $VERIFICA | tr -d '\n' | awk '{print $1}'`

# Geracao do script de criar usuario
if [ "$VERIFICA" = $USUARIO ]; then
  echo "Usuario $USUARIO ja existe"
else
  echo "Criando o usuario/schema $USUARIO"
  USER_SQL=objetos/templates/02-create_schema.sql
  USER_SQLOUT=objetos/gerados/02-create_schema.sql
  rm -f $USER_SQLOUT
  cp $USER_SQL $USER_SQLOUT
  sed -i "s/@SCHEMA@/$USUARIO/"    $USER_SQLOUT
  sed -i "s/@SENHA@/$SENHA/"       $USER_SQLOUT
  sed -i "s/@TS_NAME@/$TS_NAME/"   $USER_SQLOUT
  sqlplus $DBA/$SENHADBA@$ORACLE_SID as sysdba @$USER_SQLOUT
fi

echo
echo
exit
