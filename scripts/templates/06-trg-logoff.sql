-- Caso o usuário faça logoff do sistema, as estatisticas atuais de sessão
-- são registradas para um determinado módulo 
-- (procedure DBMS_APPLICATION_INFO.SET_MODULE)
-- CHANGELOG agora vai ficar no GIT

CREATE OR REPLACE TRIGGER TRG_LOGOFF
BEFORE LOGOFF ON DATABASE
DECLARE
  cur_user      VARCHAR2(64);
  cur_module    VARCHAR2(48);
  cur_action    VARCHAR2(32);
  cur_instance  NUMBER;
BEGIN
  DBMS_APPLICATION_INFO.READ_MODULE (cur_module, cur_action);
  cur_user := SYS_CONTEXT('USERENV','SESSION_USER');
  cur_instance := SYS_CONTEXT('USERENV', 'INSTANCE');

  IF (cur_user <> 'SYS') AND (cur_user <> 'SYSTEM') THEN
    DBMS_APPLICATION_INFO.SET_MODULE (MODULE_NAME => 'ESTATISTICAS_RAC_TRG_LOGOFF', ACTION_NAME => 'TRG_LOGOFF');
    INSERT INTO TESTATISTICAS_RAC
      SELECT
        cur_instance,
        A.SID, A.USERNAME, SYSDATE,
        B.STATISTIC#, B.VALUE,
        REPLACE(DECODE(A.MACHINE, NULL, 'NULL', A.MACHINE), CHR(0), ''),
        DECODE (UPPER(SUBSTR(A.PROGRAM,2,2)),
          ':\', 'NET8.XP',
          NULL, 'NULL',
          DECODE(A.PROGRAM,
            'dllhost.exe', cur_module,
            'JDBC Thin Client', DECODE(cur_module,
              'JDBC Thin Client', DECODE(A.MACHINE,
                'almg-linux34.almg.uucp', 'Intranet - JDBC TC',
                'almg-linux47.almg.uucp', 'Internet - JDBC TC',
                SUBSTR(A.MACHINE||' - '||cur_module,1,48)),
              cur_module),
            A.PROGRAM)
        ),
        4 AS EVENT,
        LOGON_TIME
      FROM
        V$SESSION A,
        V$MYSTAT B
      WHERE
        A.SID = B.SID
        AND A.SID = SYS_CONTEXT('USERENV','SID')
        AND B.VALUE >= 0
        AND A.USERNAME = cur_user
        AND A.SCHEMANAME NOT IN ('SYS', 'SYSMAN')
        AND NOT REGEXP_LIKE(A.PROGRAM ,'(\(J00[0-9]\))|(PZ[0-9])')
        AND B.STATISTIC# IN (SELECT STATISTIC# FROM TTIPO_ESTATISTICA_RAC);
    COMMIT;
    DBMS_APPLICATION_INFO.SET_MODULE (MODULE_NAME => cur_module, ACTION_NAME => cur_action);
  END IF;
END;
/

ALTER TRIGGER TRG_LOGOFF ENABLE;
SHOW ERRORS;
QUIT;
