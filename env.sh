# Arquivo de variaveis para instalacao do pacote de coleta de estatisticas
# do Oracle. Cada uma delas deve ser revista antes da instalacao.

# TODO: 
# 1. nao deixar o arquivo $SCRIPT_LOGIN em texto plano.

#echo "VERIFIQUE AS SENHAS NO ARQUIVO E COMENTE ESTA LINHA" && exit

# Variavel de caminho da instancia do Oracle
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/dbhome_1
# Instancia do Oracle (deve estar configurada no tnsnames.ora)
export ORACLE_SID="P10"
# Servidor do Oracle
export ORACLE_SRV=localhost

# Caminho padrao de onde estao as tablespaces (datafiles)
# Se usar o Oracle ASM, fica algo do tipo +DATA/oradata
export TS_PATH="/u01/app/oracle/oradata/$ORACLE_SID"

# Parametros da tablespace onde estarao as estatisticas
export TS_NAME="TS_ESTATISTICAS"
export TS_DATAFILE="$TS_PATH/ts_estatisticas.dbf"
export TS_SIZE="256M"
export TS_MAXSIZE="32767M"

# Dados de usuarios para execucao dos scripts
# REMOVER APOS TERMINO DA INSTALACAO
export USUARIO=abd7mlima
export SENHA=
export DBA=sys
export SENHADBA=

# Onde vao ficar os scripts que sao executados pela crontab
export SCRIPTS_DIR=$ORACLE_HOME/plus/admin/estatisticas
# Precisa da string sem substituir a variavel para registro nos scripts
export SCRIPTS_DIR_STR='$ORACLE_HOME/plus/admin/estatisticas'


# Parametros de conexao para executar os scripts
export SCRIPT_LOGIN_DIR=$ORACLE_HOME/plus/admin
export SCRIPT_LOGIN=$SCRIPT_LOGIN_DIR/set_usrsid-teste.sh
# Precisa da string sem substituir a variavel para registro nos scripts
export SCRIPT_LOGIN_STR='$ORACLE_HOME/plus/admin/set_usrsid-teste.sh'


# Os scripts de insert nas tabelas estao com texto em UTF-8
export NLS_LANG="BRAZILIAN PORTUGUESE_BRAZIL.AL32UTF8"

# Logs de instalacao e desinstalacao
export INSTALL_LOG="`dirname $0`/instala.log"
export UNINSTALL_LOG="`dirname $0`/desinstala.log"

# Onde fica a senha criptografada do Oracle para os scripts perl
export ENC_ORAPWD=$SCRIPTS_DIR/pwd.enc
