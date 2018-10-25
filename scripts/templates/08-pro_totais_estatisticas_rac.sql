--  Calculo do indice 'T' (ICCO) por programa, por data (dia)
--
--   T = 3*total_cpu + 1*total_leituras
--       ------------------------------
--            (1+3)*10.000.000

CREATE PUBLIC SYNONYM PRO_TOTAIS_ESTATISTICAS_RAC FOR @SCHEMA@.PRO_TOTAIS_ESTATISTICAS_RAC;

CREATE OR REPLACE PROCEDURE PRO_TOTAIS_ESTATISTICAS_RAC
AS
 total_cpu          NUMBER;
 total_leituras     NUMBER;
 total_alteracoes   NUMBER;
 sysdata            DATE;

BEGIN
  sysdata := TRUNC(SYSDATE);

  -- Utilizacao de CPU de todos os programas no dia
  SELECT NVL (SUM(DECODE(VALUE, -1,1, VALUE)), 1)
    INTO total_cpu FROM TDW_ESTATISTICAS_RAC
    WHERE ACOD_ESTATISTICA = 'C'
    AND TRUNC(TIMESTAMP) = TRUNC(sysdata);
  IF total_cpu = 0 THEN
    total_cpu := 1;
  END IF;

  -- Numero total de leituras de todos os programas no dia
  SELECT NVL (SUM(DECODE(VALUE, -1,1, VALUE)), 1)
    INTO total_leituras FROM TDW_ESTATISTICAS_RAC
    WHERE ACOD_ESTATISTICA = 'L'
    AND TRUNC(TIMESTAMP) = TRUNC(sysdata);
  IF total_leituras = 0 THEN
    total_leituras := 1;
  END IF;

  -- Numero total de alteracoes de todos os programas no dia
  SELECT NVL (SUM(DECODE(VALUE, -1,1, VALUE)), 1)
    INTO total_alteracoes FROM TDW_ESTATISTICAS_RAC
    WHERE ACOD_ESTATISTICA = 'A'
    AND TRUNC(TIMESTAMP) = TRUNC(sysdata);
  IF total_alteracoes = 0 THEN
    total_alteracoes := 1;
  END IF;

  -- Calculo e insercao do ICCO na TDW_ESTATISTICAS_RAC
  INSERT
    INTO TDW_ESTATISTICAS_RAC (PROGRAM, TIMESTAMP, ACOD_ESTATISTICA, ANUM_ESTATISTICA, VALUE)
    (SELECT DISTINCT PROGRAM, sysdata, 'T', 0, (
      ((SELECT DECODE (VALUE, -1, 0, VALUE)
        FROM TDW_ESTATISTICAS_RAC DEOCPU
        WHERE DEOCPU.TIMESTAMP = DEO.TIMESTAMP
          AND DEOCPU.PROGRAM = DEO.PROGRAM
          AND DEOCPU.ACOD_ESTATISTICA = 'C')/total_cpu*3)
      + ((SELECT DECODE (VALUE, -1, 0, VALUE)
        FROM TDW_ESTATISTICAS_RAC DEOLEIT
        WHERE DEOLEIT.TIMESTAMP = DEO.TIMESTAMP
          AND DEOLEIT.PROGRAM = DEO.PROGRAM
          AND DEOLEIT.ACOD_ESTATISTICA = 'L')/total_leituras)
    )/4.0*10000000.0
    FROM  TDW_ESTATISTICAS_RAC DEO
    WHERE TRUNC(TIMESTAMP) = TRUNC(sysdata));

  -- Calculo do indice Leituras/CPU/1000
  INSERT INTO TDW_ESTATISTICAS_RAC (PROGRAM, TIMESTAMP, ACOD_ESTATISTICA, ANUM_ESTATISTICA, VALUE)
    (SELECT DISTINCT PROGRAM, sysdata, 'E', 0, (
      (SELECT DECODE (VALUE, -1, 0, VALUE)
        FROM TDW_ESTATISTICAS_RAC DEOLEIT
        WHERE DEOLEIT.TIMESTAMP = DEO.TIMESTAMP
          AND DEOLEIT.PROGRAM = DEO.PROGRAM
          AND DEOLEIT.ACOD_ESTATISTICA = 'L')
      /(SELECT DECODE (VALUE, -1, 1, 0, 1, VALUE)
        FROM TDW_ESTATISTICAS_RAC DEOCPU
        WHERE DEOCPU.TIMESTAMP = DEO.TIMESTAMP
          AND DEOCPU.PROGRAM = DEO.PROGRAM
          AND DEOCPU.ACOD_ESTATISTICA = 'C')
    )/1000 AS LEIT_POR_CPU
    FROM  TDW_ESTATISTICAS_RAC DEO
    WHERE TRUNC(TIMESTAMP) = TRUNC(sysdata));

 COMMIT;
END PRO_TOTAIS_ESTATISTICAS_RAC;
/
SHOW ERRORS;
QUIT;
