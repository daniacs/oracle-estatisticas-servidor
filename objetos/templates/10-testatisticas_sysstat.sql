-- Tabela para armazenar os valores aferidos de GV$SYSSTAT
-- O campo serial pode ser usado para obter um conjunto de valores

CREATE PUBLIC SYNONYM TESTATISTICAS_SYSSTAT FOR @SCHEMA@.TESTATISTICAS_SYSSTAT;

CREATE TABLE TESTATISTICAS_SYSSTAT AS
  SELECT INST_ID, STAT_ID, VALUE, SYSDATE AS TIMESTAMP
  FROM GV$SYSSTAT
  WHERE 1=2;

ALTER TABLE TESTATISTICAS_SYSSTAT MOVE TABLESPACE @TS_NAME@;
QUIT;
