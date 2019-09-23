-- Coleta informacoes de utilizacao dos objetos do Oracle
-- para definir o nivel de atividade de tabelas, indices e lobs.
-- Se o "delta" entre duas coletas for muito baixo, o nivel de
-- utilizacao foi baixo.
-- STATISTIC_NAME: 
--   logical reads, db block changes,
--   physical reads, physical writes, 
--   space used, space allocated, segment scans
-- OBJECT_TYPE: TABLE, INDEX, LOB

INSERT INTO TESTATISTICAS_SEGMENTOS
SELECT
  OWNER,
  OBJECT_NAME,
  SUBOBJECT_NAME,
  TABLESPACE_NAME,
  OBJECT_TYPE,
  SYSDATE AS TIMESTAMP,
  SUM(VALUE) AS VALOR,
  STATISTIC_NAME,
  STATISTIC#
FROM GV$SEGMENT_STATISTICS
WHERE OWNER NOT IN 
('ANONYMOUS','CTXSYS','DBSNMP','DIP','DVF','DVSYS', 
  'EXFSYS','LBACSYS','MDDATA',
  'MDSYS','MGMT_VIEW','ODM','ODM_MTR', 
  'OLAPSYS','ORDPLUGINS', 'ORDSYS', 
  'OSE$HTTP$ADMIN','OUTLN','PERFSTAT', 
  'PUBLIC','REPADMIN','RMAN','SI_INFORMTN_SCHEMA', 
  'SYS','SYSMAN','SYSTEM','TRACESVR',
  'TSMSYSWK_TEST','WKPROXY','WKSYS', 
  'WKUSER','WMSYS','XDB', 'OWBSYS_AUDIT', 'OWBSYS'
)
AND STATISTIC# IN (0, 3, 4, 5, 18, 19, 21)
GROUP BY (OWNER, OBJECT_NAME, SUBOBJECT_NAME, TABLESPACE_NAME, OBJECT_TYPE, SYSDATE, STATISTIC_NAME, STATISTIC#)
ORDER BY STATISTIC#;

