#/usr/bin/perl

# Busca a utilização de espaço dentro do Oracle ASM
# através da vista V$ASM_DISKGROUPS e insere os dados
# na tabela TESTATISTICAS_DISKGROUPS

# Deve ser executado como usuario "grid", pois eh o
# unico usuario que pode conectar nas duas instancias
# como sysasm (em +ASM1) e sysdba (em P101) sem 
# a necessidade de usar senha.

use strict;
use DBI;
use DBD::Oracle qw(:ora_session_modes);
use Data::Dumper;

$ENV{'ORACLE_SID'} = '+ASM1';
$ENV{'ORACLE_BASE'} = '/u01/app/grid';
$ENV{'ORACLE_HOME'} = '/u01/app/11.2.0/grid';

my $dbh = DBI->connect('dbi:Oracle:', "", "", { ora_session_mode => ORA_SYSASM })
  or die "$DBI::errstr";

my $sql_dg = '
  SELECT TO_CHAR(SYSDATE, \'DD/MM/YYYY HH24:MI\') TIMESTAMP,
  NAME, STATE, TYPE, TOTAL_MB, FREE_MB
  FROM V$ASM_DISKGROUP';

my $sth = $dbh->prepare($sql_dg)
  or die "$DBI::errstr";

# XXX: Armazena os diskgroups e seus valores em $hash
$sth->execute() or die "couldn't execute statement";
my $hash = $sth->fetchall_hashref('NAME');

$dbh->disconnect;


################### Conectar a P101 e transferir os dados

$ENV{'ORACLE_SID'} = 'P101';
$ENV{'ORACLE_BASE'} = '/u01/app/oracle';
$ENV{'ORACLE_HOME'} = '/u01/app/oracle/product/11.2.0/dbhome_1';

$dbh = DBI->connect('dbi:Oracle:', "", "", { ora_session_mode => ORA_SYSDBA })
  or die "$DBI::errstr";

$dbh->{RaiseError}   = 1;
$dbh->{AutoCommit}   = 0;
$dbh->{RowCacheSize} = 0;

# XXX pega os valores de $hash e jogam na tabela TESTATISTICAS_DISKGROUPS
# Nao usar o $dbh->do dentro de um loop. Fazer o prepare antes do loop e
# deixar os execute dentro.

$sth = $dbh->prepare("
  INSERT INTO TESTATISTICAS_DISKGROUPS (
    NAME,
    TIMESTAMP,
    TOTAL_MB,
    FREE_MB,
    STATE)
  VALUES (?, TO_DATE(?, 'DD/MM/YYYY HH24:MI'), ?, ?, ?)");

eval {
  foreach my $dg (keys %$hash) {
    my @params = (
      $hash->{$dg}->{NAME},
      $hash->{$dg}->{TIMESTAMP},
      $hash->{$dg}->{TOTAL_MB},
      $hash->{$dg}->{FREE_MB},
      $hash->{$dg}->{STATE}
    );
    print join(", ", @params), "\n";
    my $ret = $sth->execute(@params);
  }
};

if ($@) {
  print "Erro ao processar a transação: ", $DBI::errst, "\n";
  $dbh->rollback;
}
else {
  $dbh->commit;
}

$dbh->disconnect;

exit(0);