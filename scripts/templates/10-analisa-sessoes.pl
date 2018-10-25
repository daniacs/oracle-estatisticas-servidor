#!/usr/bin/perl

use strict;
use lib "@SCRIPTS_DIR@/lib";
use Oracle;
use Senha;
use Data;
use Data::Dumper;
use Getopt::Long;
use Time::HiRes qw(time);
use Time::Local;
use Array::Transpose;

# Parametros de conexao com o Banco de dados
use constant ORA_SRV   =>  'localhost';
use constant ORA_INST  =>  'P10';
use constant ORA_USR   =>  'ABD7';
use constant ORA_PWD_FILE => '@ENC_ORAPWD@';
use constant LOGOFF   =>  4;
use constant DEFAULT_STAT => 19;
use constant DEFAULT_TABIN => 'TESTATISTICAS_RAC';
use constant DEFAULT_TABOUT => 'TANALISE_ESTATISTICAS_SESSOES';
use constant HORA_LIMIT_INF => 730;
use constant HORA_LIMIT_SUP => 2215;

sub ajuda {
  print "Analisa a tabela <TABIN> e grava o processamento em <TABOUT>\n";
  print "Utilizar: $0 [--inicio <DATA_0>] [--fim <DATA_F>] [--stat STAT#] ";
  print "[--log <ARQ_LOG>] [--tabin TABIN] [--tabout TABOUT] [--truncate] ";
  print "[--debug] [--worktime] [--limit] [--skip n] \n";
  print "Formato da data: DDMMAAAA ou DDMMAAAA-[hhmm] ou DD-MM-AAAA\n";
  exit(0);
}

# Se houver log de execucao, quem recebe?
my $emails = 'gti-dba@almg.gov.br';

# Parametros
my $data0;
my $dataF;
my $formato_data0 = "DDMMYYYY";
my $formato_dataF = "DDMMYYYY";
my $mostra_ajuda = 0;
my $debug = 0;
my $rowlimit;
my $log_file;
my $table_in;
my $table_out;
my $truncate = 0;
my $program;
my $stat_num;
my $schema = "abd7";
my $worktime = 0;
my $skip = 0;

# Tempos de execucao
my $tempoInicio = time();
my $checkpoint;
my $deltaT = 0;

GetOptions(
  'inicio=s'  =>  \$data0,
  'fim=s'     =>  \$dataF,
  'worktime'  =>  \$worktime,
  'help'      =>  \$mostra_ajuda,
  'ajuda'     =>  \$mostra_ajuda,
  'debug'     =>  \$debug,
  'limit=i'   =>  \$rowlimit,
  'log=s'     =>  \$log_file,
  'tabin=s'   =>  \$table_in,
  'tabout=s'  =>  \$table_out,
  'stat=i'    =>  \$stat_num,
  'truncate'  =>  \$truncate,
  'skip=i'    =>  \$skip,
  'prog=s'    =>  \$program)
  or die("Parametros passados de forma incorreta. Usar --help/--ajuda.");

if ($mostra_ajuda) {
  ajuda();
}

# Se tiver algum arquivo de saida, redireciona o STDOUT pra ele
if ($log_file) {
  close(STDOUT);
  open(STDOUT, ">>", $log_file);
}

if ($data0) {
  ($data0, $formato_data0) = Data::dataPadrao($data0);
}
else {
  $data0 = Data::data(-1);
}

if ($dataF) {
  ($dataF, $formato_dataF) = Data::dataPadrao($dataF);
}
else {
  $dataF = Data::data(0);
}


# Definicao dos nomes das tabelas analisada e gerada e codigo da estatistica.
$table_in = DEFAULT_TABIN if (!$table_in);
$table_out = DEFAULT_TABOUT if (!$table_out);

# Verificar quantos programas serao analisados e se foram 
# delimitados corretamente, usando aspas simples
my $numprogs = 0;
if ($program) {
  my @arr = split(/,/, $program);
  my @validos;
  $numprogs = @arr;
  if ($numprogs > 1) {
    foreach my $item(@arr) {
      $item =~ s/^\s+//;    # Se tiver espacos do tipo "'p1', 'p2'"
      if (!($item =~ /^'([^']+)'/)) {
        die("Forma incorreta de $1\n");
      }
      else {
        push(@validos, $item);
      }
    }
    $program = join(",", @validos);
  }
}
$program = uc($program);

print localtime()." - Inicio da execucao\n";
print "Data inicial: $data0\n";
print "Data final  : $dataF\n";
print "Estatistica : $stat_num\n\n" if ($stat_num);

my $credenciais = Senha::getPwd({arquivo=>ORA_PWD_FILE});
my $db_ora = Oracle::conexaoOracle(
  {host=>ORA_SRV,base=>ORA_INST,usuario=>ORA_USR,senha=>$credenciais}
);

######### Criacao da tabela que recebe o processamento

my $retorno;
my $sql;
my $sth;
my $rows;
my $result;

$sql = "SELECT TABLE_NAME FROM USER_TABLES WHERE TABLE_NAME = '"
  .uc($table_out)."'";

$sth = $db_ora->prepare($sql);
$rows = $sth->execute();
$result = $sth->fetchrow_hashref();

if (not defined($result->{"TABLE_NAME"})) {
  $db_ora->do(qq{
    CREATE TABLE $schema.$table_out (
    INST_ID    NUMBER,
    SID        NUMBER,
    SCHEMA     VARCHAR(60),
    PROGRAM    VARCHAR(60),
    MACHINE    VARCHAR(60),
    STAT       NUMBER,
    TIMESTAMP  DATE,
    LOGON_TIME DATE,
    TOTAL      NUMBER) TABLESPACE TS_ADMIN NOLOGGING });
  $retorno = $db_ora->commit();
  if ($retorno < 0) {
    die($DBI::errstr);
  }
}
else {
  0;
  # TODO: verificar se a estrutura eh valida para receber os valores.
  # Se nao for, abortar a execucao.
}

if ($truncate) {
  $db_ora->do(qq{TRUNCATE TABLE $schema.$table_out});
  $retorno = $db_ora->commit();
  if ($retorno < 0) {
    print $DBI::errstr;
  }
}

$checkpoint = time();
$deltaT = $checkpoint - $tempoInicio;
printf("CREATE/TRUNCATE TABLE: %.2f s\n", $deltaT);

# Consulta da tabela de estatisticas para processamento.
# Os parametros "schemaname, machine" NÃO fazem parte do grupo de janela!
$sql = qq{
  SELECT 
    rowid, inst_id, sid, program, schemaname, machine, timestamp, 
    extract(year from timestamp) as year, 
    extract(month from timestamp) as month, 
    extract(day from timestamp) as day, 
    extract(hour from cast(timestamp as timestamp)) as hour,
    extract(minute from cast(timestamp as timestamp)) as minute,
    statistic#,
    value,
    coalesce(lag(value) over (
      partition by statistic#, inst_id, sid, schemaname
      order by timestamp, value, event),
      0) as lastval,
    coalesce(value - lag(value) over (
      partition by statistic#, inst_id, sid, schemaname
      order by timestamp, value, event),
      0) as delta,
    event,
    logon_time
  FROM $schema.$table_in
  WHERE 
    timestamp >= TO_DATE('$data0', '$formato_data0')
    AND timestamp <  TO_DATE('$dataF', '$formato_dataF')
};

if ($stat_num) {
  $sql .= "    AND statistic# = $stat_num\n";
}

if ($numprogs == 1) {
  $sql .= "    AND UPPER(program) = $program\n";
}
elsif ($numprogs > 1) {
  $sql .= "    AND UPPER(program) IN ($program)\n";
}

if ($rowlimit) {
  $sql .= "    AND ROWNUM <= $rowlimit\n";
}

$sql .= "  ORDER BY 
    statistic#, inst_id, sid, schemaname, logon_time, timestamp, value, event";

print("SQL: $sql\n") if ($debug);

$sth = $db_ora->prepare($sql);
$rows = $sth->execute();
#print("$sql\n") if ($debug);
$deltaT = time() - $checkpoint;
$checkpoint = time();
printf("SELECT:                %.2f s\n", $deltaT);

my $rowid;
my $inst;
my $sid;
my $prog;
my $schema;
my $machine;
my $timestamp;
my $timemask;
my $year;
my $month;
my $day;
my $hour;
my $min;
my $stat;
my $val;
my $lastval;
my $delta;
my $event;
my $logon_time;
my $hashkey;
my %table;
my $last_sid;
my $last_event;
my $cond1;
my $cond2;
my $cond3;
my $cond4;
my $incremento;
my $horario;

# O incremento do valor deve ser feito da seguinte forma:
# SID == LAST_SID?
# SIM: Mesmo numero de sessao. Continuada ou reiniciada?
#   Ultimo evento == LOGOFF?
#   SIM -> Sessao foi reaproveitada. Incremento = $val
#   NAO -> Sessao continuada.        Incremento = $delta
# NAO: SIDs diferentes! Registro unico ou inicio de outra com mais registros?
#   Evento == LOGOFF?
#   SIM -> So teve um registro pra essa sessao. Incremento = $val
#   NAO -> Sessao pode ou nao ser continuada.   Incremento = 0.

$result = $sth->fetchrow_arrayref();
if (! $result) {
  print "Nao ha registros em $table_in no periodo ($data0 - $dataF)\n";
  $sth->finish;
  $db_ora->disconnect;
  exit(1);
}

# Primeira linha:

($rowid, $inst, $sid, $prog, $schema, $machine,
  $timestamp, $year, $month, $day, $hour, $min, $stat,
  $val, $lastval, $delta, $event, $logon_time) = @$result;

if ($debug) {
  print "prog;inst;sid;last_sid;schema;timestamp;stat;val;lastval;";
  print "delta;event;last_event;incr;acumulado;logon_time\n";
  printf("%s;%d;%.4d;%.4d;%s;%s;%d;%.6d;%.6d;%.6d;%d;%d;%.6d;%.5d\n",
    $prog, $inst, $sid, $last_sid, $schema, $timestamp, $stat, $val, $lastval,
    $delta, $event, $last_event, $incremento, $table{$hashkey}, $logon_time);
}

$rows = 1;
$skip *= 86400;

while ($result = $sth->fetchrow_arrayref()) {
  ($rowid, $inst, $sid, $prog, $schema, $machine, 
    $timestamp, $year, $month, $day, $hour, $min, $stat,
    $val, $lastval, $delta, $event, $logon_time) = @$result;

  $delta = 0 if $delta < 0;
  $timemask = substr($timestamp, 0, 10);
  $hashkey = "$inst\t$sid\t".uc($schema)."\t".uc($prog)
    ."\t$machine\t$stat\t$timemask\t$logon_time";
  
  # $hour e $min entre 00 e 09 da problema se nao for com sprintf
  $horario = sprintf("%.2d%.2d",$hour,$min);

  $cond1 = ($sid == $last_sid);
  $cond2 = ($last_event == LOGOFF);
  $cond3 = ($event == LOGOFF);


  $incremento = (1 - $cond1)*$val*($cond3) + $cond1*(
    $cond2*$val + (1 - $cond2)*$delta
  );

  if ($worktime) {
    $cond4 = (($horario >= HORA_LIMIT_INF)&&($horario <= HORA_LIMIT_SUP));
    $table{$hashkey} += $incremento*$cond4;
  }
  else {
    $table{$hashkey} += $incremento;
  }

  #$table{$hashkey} += $incremento * ($timestamp_ts >= ($timestamp_hoje-$skip));

  if ($debug) {
    printf("%s;%d;%.4d;%.4d;%s;%s;%d;%.6d;%.6d;%.6d;%d;%d;%.6d;%.5d;%s\n",
      $prog, $inst, $sid, $last_sid, $schema, $timestamp, $stat, $val, $lastval,
      $delta, $event, $last_event, $incremento, $table{$hashkey}, $logon_time);
  }

  $last_event = $event;
  $last_sid = $sid;
  $rows++;
}

$sth->finish;
$deltaT = time() - $checkpoint;
$checkpoint = time();
printf("PERL PROCESSING        %.2f s\n", $deltaT);


######## Insercao na tabela de saida
# Pegar a tabela gerada por [$hashkey, $table] e transpor
# Fazer o bind das linhas (antigas colunas) para utilizar o execute_array
# Fica BEM mais rapido que o execute linha a linha

# VALUES: ($hashkey, $table{$hashkey})
# INST_ID, SID, SCHEMA, PROG, MACHINE, STAT#, TIMESTAMP(DAY), LOGON_TIME, VALUE
$sql = "INSERT INTO $table_out VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
$sth = $db_ora->prepare_cached($sql);

my $matrix;
my $rows_ora = 0;
foreach $hashkey (keys(%table)) {
  my @array = split(/\t/, $hashkey);
  push(@array, $table{$hashkey});
  push(@{$matrix}, \@array);
#  $sth->execute(@array);
  $rows_ora++;
}

$matrix = transpose($matrix);
for (my $i = 0; $i < @{$matrix}; $i++) {
  $sth->bind_param_array($i+1, $matrix->[$i]);
}
my %attr;
$sth->execute_array(\%attr);
$sth->finish;

$deltaT = time() - $checkpoint;
$checkpoint = time();
$checkpoint -= $tempoInicio;

printf("ORACLE INSERT          %.2f s\n", $deltaT);
printf("Tempo total:           %.2f s\n", $checkpoint);
printf("Total agregada:        %d\n", $rows);
printf("Total copiada:         %d\n", $rows_ora);
printf("Reducao:               %.2f%%\n", 100*(1-$rows_ora/$rows));

$db_ora->disconnect if defined($db_ora);
