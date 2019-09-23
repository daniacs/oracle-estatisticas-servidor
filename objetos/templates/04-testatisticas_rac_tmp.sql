-- TESTATISTICAS_RAC_TMP: Tabela temporaria de estatisticas 
-- (nao precisa do atributo "evento", pois e usada apenas para exibicao
-- das estatisticas no SGAR ou para construir a TDW_ESTATISTICAS_RAC)
-- Toda vez que eh feito um COMMIT, a tabela eh truncada.

CREATE PUBLIC SYNONYM TESTATISTICAS_RAC_TMP FOR @SCHEMA@.TESTATISTICAS_RAC_TMP;

CREATE GLOBAL TEMPORARY TABLE TESTATISTICAS_RAC_TMP (
  INST_ID      NUMBER NOT NULL,
  SID          NUMBER NOT NULL,
  SCHEMANAME   VARCHAR2(32) NOT NULL,
  TIMESTAMP    DATE NOT NULL,
  STATISTIC#   NUMBER NOT NULL,
  VALUE        NUMBER NOT NULL,
  MACHINE      VARCHAR2(64),
  PROGRAM      VARCHAR2(64)
) ON COMMIT DELETE ROWS;
QUIT;
