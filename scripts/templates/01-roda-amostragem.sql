-- Script agendado via cron (periodicidade conforme demanda)

-- Substitui a versao antiga do script com as seguintes mudancas:
--  Tabela TESTATISTICAS_ORACLE substituida por TESTATISTICAS_RAC
--    * Passa a conter o campo INST_ID
--  Tabela TTIPO_ESTATISTICA_COLETADA substituida por TTIPO_ESTATISTICA_RAC
--    * O Oracle RAC possui valores diferentes do Oracle "single" no campo
--      STATISTIC#

EXECUTE DBMS_APPLICATION_INFO.SET_MODULE (MODULE_NAME =>'roda_amostragem', ACTION_NAME => NULL);
COMMIT;

INSERT INTO TESTATISTICAS_RAC
SELECT
  A.INST_ID, A.SID, A.USERNAME, SYSDATE,
  B.STATISTIC#, B.VALUE,
  REPLACE(DECODE(A.MACHINE, NULL, 'NULL', A.MACHINE), CHR(0), ''),
  DECODE (UPPER(SUBSTR(A.PROGRAM,2,2)),
    ':\', 'NET8.XP',
    NULL, 'NULL',
    DECODE(A.PROGRAM,
      'dllhost.exe', A.MODULE,
      'JDBC Thin Client', DECODE(A.MODULE,
        'JDBC Thin Client', DECODE(A.MACHINE,
          'almg-linux34.almg.uucp', 'Intranet - JDBC TC',
          'almg-linux47.almg.uucp', 'Internet - JDBC TC',
          SUBSTR(A.MACHINE||' - '||A.MODULE,1,48)),
        A.MODULE),
      A.PROGRAM)
  ),
  1,
  LOGON_TIME
FROM
  GV$SESSION A,
  GV$SESSTAT B
WHERE
  A.SID = B.SID
  AND A.INST_ID = B.INST_ID
  AND B.VALUE >= 0
  AND A.SCHEMANAME NOT IN ('SYS', 'SYSMAN')
  AND NOT REGEXP_LIKE(A.PROGRAM ,' (\(J00[0-9]\))|(PZ[0-9])')
  AND B.STATISTIC# IN (SELECT STATISTIC# FROM TTIPO_ESTATISTICA_RAC);

COMMIT;

-------------------------------------------
-- Dados de desempenho global do banco ----
-------------------------------------------

INSERT INTO TESTATISTICAS_SYSSTAT
  SELECT INST_ID, STAT_ID, VALUE, SYSDATE AS TIMESTAMP
  FROM GV$SYSSTAT
  WHERE STAT_ID IN (SELECT STAT_ID FROM TTIPO_ESTATISTICA_SYSSTAT)
  ORDER BY STAT_ID;
COMMIT;

INSERT INTO TESTATISTICAS_SYS_TIME_MODEL
  SELECT INST_ID, STAT_ID, VALUE, SYSDATE AS TIMESTAMP
  FROM GV$SYS_TIME_MODEL
  ORDER BY STAT_ID;
COMMIT;

QUIT;
