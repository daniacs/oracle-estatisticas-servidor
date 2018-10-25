-- PROSETANOMEMODULO(modulo, SID)
-- Procedure executada por uma aplicacao web 
-- Ex: acesso a intranet da ALMG:
--   /webs                  -> JDBC Thin Client
--   /registros_funcionais  -> registros_funcionais
--   /pagamentos            -> pagamentos

-- 1: Busca o nome do modulo atual
-- 2: Redefine o nome para PROSETANOMEMODULO
--    para nao contabilizar as estatisticas durante os INSERTS
-- 3: Grava as estatisticas do modulo atual em TESTATISTICAS_RAC
-- 4: Grava as estatisticas do proximo modulo em TESTATISTICAS_RAC
-- 5: Define o nome para o proximo modulo

-- Funciona no Oracle RAC mesmo sem utilizar as vistas GV$
-- pois ele busca a instancia em SYS_CONTEXT('USERENV', 'INSTANCE')
-- para o servidor onde esta sendo executado.

CREATE PUBLIC SYNONYM PROSETANOMEMODULO FOR @SCHEMA@.PROSETANOMEMODULO;

CREATE OR REPLACE PROCEDURE PROSETANOMEMODULO(next_mod in varchar, pSID in varchar)
IS pragma autonomous_transaction;
BEGIN
  DECLARE
    cur_mod       VARCHAR2(48);
    cur_act       VARCHAR2(32);
    cur_instance  NUMBER;
    cur_user      VARCHAR2(64);
  BEGIN
    DBMS_APPLICATION_INFO.READ_MODULE(cur_mod, cur_act);

    -- Quem roda este script eh a coleta de estatisticas do Oracle
    DBMS_APPLICATION_INFO.SET_MODULE(
      MODULE_NAME => 'PROSETANOMEMODULO',
      ACTION_NAME => 'PROSETANOMEMODULO');

    -- Buscar o SID e o usuario que esta rodando o modulo
    SELECT SYS_CONTEXT('USERENV', 'INSTANCE') INTO cur_instance FROM DUAL;
    SELECT SYS_CONTEXT('USERENV', 'SESSION_USER') INTO cur_user FROM DUAL;
    COMMIT;

    -- Somente registra as estatisticas quando o modulo for alterado
    IF cur_mod <> next_mod THEN
      -- Registra fim do modulo anterior
      INSERT INTO TESTATISTICAS_RAC
        SELECT
          cur_instance,
          A.SID, A.USERNAME, SYSDATE,
          B.STATISTIC#, B.VALUE,
          REPLACE(DECODE(A.MACHINE, NULL, 'NULL', A.MACHINE), CHR(0), ''),
          DECODE (UPPER(SUBSTR(A.PROGRAM,2,2)),
            ':\ ', 'NET8.XP',
            NULL, 'NULL',
            DECODE(A.PROGRAM,
              'dllhost.exe', cur_mod,
              'JDBC Thin Client', DECODE(cur_mod,
                'JDBC Thin Client', DECODE(A.MACHINE,
                  'almg-linux34.almg.uucp', 'Intranet - JDBC TC',
                  'almg-linux47.almg.uucp', 'Internet - JDBC TC',
                SUBSTR(A.MACHINE||' - '||cur_mod,1,48)),
              cur_mod),
            A.PROGRAM)
          ),
          2 AS EVENT,
          LOGON_TIME
        FROM
          V$SESSION A,
          V$MYSTAT B
        WHERE
          A.SID = TO_NUMBER(pSID, 'XXXX')
          AND A.SID = B.SID
          AND A.USERNAME = cur_user
          AND B.VALUE >= 0
          AND B.STATISTIC# IN (SELECT STATISTIC# FROM TTIPO_ESTATISTICA_RAC);

      -- Registra inicio do novo modulo na TESTATISTICAS_RAC
      -- O registro do modulo no Oracle eh feito ao fim da execucao
      -- Dessa forma, as estatisticas nao sao contabilizadas para o modulo
      INSERT INTO TESTATISTICAS_RAC
      SELECT
        cur_instance,
        A.SID, A.USERNAME, SYSDATE,
        B.STATISTIC#, B.VALUE, A.MACHINE, next_mod,
        2 AS EVENT,
        LOGON_TIME
      FROM
        V$SESSION A,
        V$MYSTAT B
       --WHERE A.SID = TO_NUMBER(pSID)      -- Funciona no SQLPLUS ou JAVA console
       WHERE A.SID = TO_NUMBER(pSID,'XXXX')  -- Funciona via web
         AND A.SID = B.SID
         AND A.USERNAME = cur_user
         AND B.VALUE >= 0
         AND B.STATISTIC# IN (SELECT STATISTIC# FROM TTIPO_ESTATISTICA_RAC);
       COMMIT;
     END IF;

   -- Registra o modulo no Oracle
   DBMS_APPLICATION_INFO.SET_MODULE (MODULE_NAME => next_mod, ACTION_NAME => cur_act);
   END;
END;
/

SHOW ERRORS;

QUIT;
