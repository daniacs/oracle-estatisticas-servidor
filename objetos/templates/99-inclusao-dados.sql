-----------------------------------------------------------
------------------ INCLUSÃO DE DADOS ----------------------
-----------------------------------------------------------

-- Incluir um script que execute de 10 em 10 minutos:
-- SELECT SEQ_ESTATISTICAS_SYSSTAT.NEXTVAL FROM DUAL;
-- INSERT INTO TESTATISTICAS_SYSSTAT
--   SELECT SEQ_ESTATISTICAS_SYSSTAT.CURRVAL, S.*
--   FROM (
--     SELECT INST_ID, STAT_ID, VALUE, SYSDATE AS TIMESTAMP
--   	FROM GV$SYSSTAT
--   	WHERE STAT_ID IN (SELECT STAT_ID FROM TTIPO_ESTATISTICA_SYSSTAT)
--   	ORDER BY STAT_ID
--   ) S;
-- COMMIT;
-- 
-- SELECT SEQ_ESTATISTICAS_SYS_TIME_MOD.NEXTVAL FROM DUAL;
-- INSERT INTO TESTATISTICAS_SYS_TIME_MODEL
--   SELECT SEQ_ESTATISTICAS_SYS_TIME_MOD.CURRVAL, S.*
--   FROM (
--     SELECT INST_ID, STAT_ID, VALUE, SYSDATE AS TIMESTAMP
--   	FROM GV$SYS_TIME_MODEL
--   	ORDER BY STAT_ID
--   ) S;
-- 
-- COMMIT;
QUIT;
