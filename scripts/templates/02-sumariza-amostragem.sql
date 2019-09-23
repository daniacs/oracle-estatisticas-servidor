-- Script apaga amostras com mais de trinta e um dias.
-- Criado:
--    02/04/2004 - Leonardo H. Liporati
--    12/03/2007 - mmrr - O Hannas pediu para guardar durante um ano.
--    03/06/2009 - LHL - apaga tambem a tabela temporaria e arquiva na tabela
--                       Data Warehouse a somatoria diaria por programa entre
--                       7AM e o momento da execucao deste script.
--    30/07/2009 - LHL - Armazenando 6 meses para compensar o DW e os
--                       registros extras gerados na WEB (testaconectado.asp)
--    31/07/2009 - LHL - Trocado testatisticas_oracle_temp por
--                       testatisticas_oracle_tmp
--    29/05/2015 - LHL - Armazenando 4 meses para compensar a trigger de
--                       logoff (trg_logoff)
--    13/01/2016 - DACS - Adequacao do script para execucao no Oracle RAC:
--                        TDW_ESTATISTICAS_RAC.ANUM_ESTATISTICA foi definido
--                        como NUMBER, pois o numero de itens medidos passou
--                        de 3 para 16 na tabela TESTATISTICAS_RAC
--                        Foi necessario mudar a PROGASTOSESTATISTICANOPERIODO
--                        para adequar ao Oracle RAC. O campo ACOD_ESTATISTICA
--                        foi mantido para compatibilidade.
--    14/01/2016 - DACS - Script renomeado para arquiva-amostragem.
--    11/02/2016 - DACS - Criacao do sinonimo TDW_ESTATISTICAS_ORACLE
--                        apontando para TDW_ESTATISTICAS_RAC
--    06/09/2016 - DACS - Modificação do script para iniciar no horário núcleo
--                        (a partir de 7:30AM) -> data_inicio

-- QUANDO FOR NECESSÁRIO RODAR PARA DATAS ANTERIORES:
--   DESCOMENTAR:
--     data_inicio := '##/##/####'
--     data_fim    := '##/##/####'
--   COMENTAR:
--     EXECUTE PRO_TOTAIS_ESTATISTICAS_RAC
--   DESCOMENTAR:
--     EXECUTE PRO_TOTAIS_ESTATISTICAS_DATA('##/##/####');

SET serveroutput ON SIZE 20000
SET lines 120

-- Prepara a tabela TESTATISTICAS_RAC_TMP
DECLARE
  estat NUMBER;
  data_inicio VARCHAR2(32);
  data_fim    VARCHAR2(32);
  CURSOR dados IS
    SELECT STATISTIC# FROM TTIPO_ESTATISTICA_RAC;
BEGIN
  -- Definicao do intervalo de tempo das estatisticas temporarias geradas
  data_inicio := TO_CHAR(TRUNC(SYSDATE)+(7.5/24), 'DD/MM/YYYY HH24:MI');
  data_fim    := TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI');
--  data_inicio := '01/02/2016 07:00';
--  data_fim    := '01/02/2016 22:15';

  OPEN dados;
  FETCH dados INTO estat;
  IF dados%NOTFOUND THEN
    DBMS_OUTPUT.PUT_LINE('***** TTIPO_ESTATISTICA_RAC SEM REGISTROS *****');
    GOTO fim;
  END IF;
  DBMS_OUTPUT.PUT_LINE('Gerando estatisticas temporarias no intervalo entre '||
    data_inicio||' e '||data_fim);
  LOOP
    PROGASTOSESTATISTICANOPERIODO(data_inicio, data_fim, estat);
    FETCH dados INTO estat;
    IF dados%NOTFOUND THEN
      GOTO fim;
    END IF;
    -- DBMS_OUTPUT.PUT_LINE(estat);
  END LOOP;
<<fim>>
  CLOSE dados;
END;
/

-- Transfere os dados totais da TESTATISTICAS_RAC_TMP para TDW_ESTATISTICAS_RAC
-- Ao executar o commit, todos os dados da tabela temporaria
-- TESTATISTICAS_RAC_TMP sao apagados.
-- O GROUP BY TRUNC(TIMESTAMP) eh necessario pois as estatisticas devem
-- ser do dia inteiro.
EXECUTE DBMS_OUTPUT.PUT_LINE('Inserindo dados em TDW_ESTATISTICAS_RAC');
INSERT INTO TDW_ESTATISTICAS_RAC (PROGRAM, TIMESTAMP, ANUM_ESTATISTICA, ACOD_ESTATISTICA, VALUE)
  SELECT
    UPPER(PROGRAM) PROGRAM,
    TRUNC(TIMESTAMP) TIMESTAMP,
    STATISTIC# ANUM_ESTATISTICA,
    DECODE(STATISTIC#, 19, 'C', 100, 'A', 14, 'L', NULL) ACOD_ESTATISTICA,
    SUM(VALUE) VALUE
  FROM TESTATISTICAS_RAC_TMP
  WHERE PROGRAM IS NOT NULL
  GROUP BY STATISTIC#, TRUNC(TIMESTAMP), UPPER(PROGRAM);
COMMIT;

SELECT 'Calculando ICCO para TDW_ESTATISTICAS_RAC em '||COUNT(1)||' entradas'
  AS "Entradas (C, A, L)"
  FROM TDW_ESTATISTICAS_RAC
  WHERE ACOD_ESTATISTICA IS NOT NULL AND TRUNC(TIMESTAMP) = TRUNC(SYSDATE);

EXECUTE PRO_TOTAIS_ESTATISTICAS_RAC
--EXECUTE PRO_TOTAIS_ESTATISTICAS_DATA('24/02/2016');
COMMIT;
SELECT 'Entradas ICCO calculadas: '||COUNT(1) AS "Entradas ICCO"
  FROM TDW_ESTATISTICAS_RAC
  WHERE ACOD_ESTATISTICA = 'T' AND TRUNC(TIMESTAMP) = TRUNC(SYSDATE);

EXECUTE DBMS_OUTPUT.PUT_LINE('Removendo entradas com mais de 122 dias de TESTATISTICAS_RAC');
DELETE FROM TESTATISTICAS_RAC WHERE TIMESTAMP < (SYSDATE - 122);
COMMIT;
QUIT;
