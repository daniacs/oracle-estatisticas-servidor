-- TABLESPACE utilizada para armazenamento das estatisticas: TS_ESTATISTICAS
-- SCHEMA: ABD7
-- ALTERAR ESSES PARAMETROS NO ARQUIVO CASO SEJA NECESSARIO OUTROS VALORES

-- TESTATISTICAS_RAC: Tabela para armazenamento de estatisticas do Oracle RAC
-- INST_ID: Instancia do Oracle RAC
-- SID: Sessao de usuario na GV$SESSION
-- SCHEMANAME: Nome do usuario/schema logado na sessao
-- TIMESTAMP: Horario em que a estatistica eh armazenada
-- STATISTIC#: Referencia para a tabela GV$STATNAME e TTIPO_ESTATISTICA_RAC
-- VALUE: Valor da estatistica no tempo da coleta (GV$SESSTAT.VALUE)
-- MACHINE: GV$SESSION.MACHINE
-- PROGRAM: Adequacao de GV$SESSION.PROGRAM/MODULE
-- EVENT:
--   1: Estatistica periodica / crontab
--   2: Estatistica por mudanca de modulo / web
--   3: Estatistica de logoff
--   4: Estatistica nao categorizada

CREATE PUBLIC SYNONYM TESTATISTICAS_RAC FOR @SCHEMA@.TESTATISTICAS_RAC;

CREATE TABLE TESTATISTICAS_RAC (
  INST_ID      NUMBER NOT NULL,
  SID          NUMBER NOT NULL,
  SCHEMANAME   VARCHAR2(32) NOT NULL,
  TIMESTAMP    DATE NOT NULL,
  STATISTIC#   NUMBER NOT NULL,
  VALUE        NUMBER NOT NULL,
  MACHINE      VARCHAR2(64),
  PROGRAM      VARCHAR2(64),
  EVENT        NUMBER NOT NULL,
  LOGON_TIME   DATE
) TABLESPACE @TS_NAME@;
QUIT;
