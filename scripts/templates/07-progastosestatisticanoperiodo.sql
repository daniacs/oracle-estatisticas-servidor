-- Cria um cursor para a TESTATISTICAS_RAC 
-- ORDER BY (INST_ID, SID, SCHEMANAME, TIMESTAMP, VALUE)
-- para uma determinada estatística, em um período definido
-- Percorre o resultado e agrupa os valores para: 
-- INST_ID, SID, SCHEMANAME
-- obtendo o valor da estatística mais atual e insere 
-- a diferença na tabela TESTATISTICAS_RAC_TMP.

-- Entrada: 
--  1) Data de início (CHAR inicio)
--  2) Data de fim (CHAR final)
--  3) Tipo de estatística (número que deve estar em TTIPO_ESTATISTICAS_RAC)

-- TODO: sera substituida por script perl que trata melhor os casos
-- de sessao. Este script possui falhas (do tipo considerar um unico registro
-- como sendo todo o gasto da sessao, caso em que nao eh verdade quando o 
-- logoff da sessao eh feito apos o intervalo de coleta).

CREATE PUBLIC SYNONYM PROGASTOSESTATISTICANOPERIODO FOR @SCHEMA@.PROGASTOSESTATISTICANOPERIODO;

CREATE OR REPLACE PROCEDURE PROGASTOSESTATISTICANOPERIODO (
  inicio CHAR,
  final CHAR,
  tipo_estatistica NUMBER
) AS
l1_instid             NUMBER;
l2_instid             NUMBER;
l1_sid                NUMBER;
l2_sid                NUMBER;
l1_schemaname         VARCHAR2(30);
l2_schemaname         VARCHAR2(30);
l1_machine            VARCHAR2(64);
l2_machine            VARCHAR2(64);
l1_program            VARCHAR2(48);
l2_program            VARCHAR2(48);
l1_value              NUMBER;
l2_value              NUMBER;
l1_timestamp          DATE;
l2_timestamp          DATE;
valor_acumulado       NUMBER;
valor_inicial         NUMBER;
contador              NUMBER;

CURSOR dados IS
  SELECT INST_ID, SID, SCHEMANAME, TIMESTAMP, VALUE, MACHINE, PROGRAM
  FROM TESTATISTICAS_RAC
  WHERE STATISTIC# = tipo_estatistica
  AND TIMESTAMP >= TO_DATE(inicio, 'DD/MM/YYYY HH24:MI')
  AND TIMESTAMP <  TO_DATE(final, 'DD/MM/YYYY HH24:MI')
  ORDER BY INST_ID, SID, SCHEMANAME, TIMESTAMP, VALUE;

BEGIN
  -- SELECT COUNT(1) INTO num_linhas
  -- FROM TESTATISTICAS_ORACLE
  -- WHERE STATISTIC# = tipo_estatistica
  -- AND TIMESTAMP >= TO_DATE(inicio, 'DD/MM/YYYY HH24:MI')
  -- AND TIMESTAMP <  TO_DATE(final, 'DD/MM/YYYY HH24:MI');

  -- DBMS_OUTPUT.PUT_LINE('Numero de linhas: '||num_linhas);

  OPEN dados;
  FETCH dados INTO l1_instid, l1_sid, l1_schemaname, l1_timestamp,
  l1_value, l1_machine, l1_program;
  IF dados%NOTFOUND THEN
    DBMS_OUTPUT.PUT_LINE('**** TESTATISTICAS_RAC vazia!? ****');
    GOTO passo2;
  END IF;
  contador := 1;
  valor_acumulado := 0;
  valor_inicial:= l1_value;
  LOOP
    --DBMS_OUTPUT.PUT_LINE(l1_instid||';'||l1_sid||';'||l1_schemaname||';'||to_char(l1_timestamp, 'DD/MM/YYYY HH24:MI')||';'||l1_value||';'||l1_machine||';'||l1_program);
    FETCH dados INTO l2_instid, l2_sid, l2_schemaname, l2_timestamp,
    l2_value, l2_machine, l2_program;
    IF dados%NOTFOUND THEN
      GOTO passo2;
    END IF;

    -- O Oracle RAC reaproveita o SID para outros programas!!!!
    -- Principalmente quando se usa o PROSETANOMEMODULO ou o DBMS_APPLICATION.SET_MODULE!
    -- Necessario comparar l1_program e l2_program!
    IF (l2_instid = l1_instid) AND (l2_sid = l1_sid) AND (l2_schemaname = l1_schemaname) AND (l2_program = l1_program) AND (l2_value >= l1_value) THEN
      -- Ainda estamos na mesma sessao
      valor_acumulado:= l2_value - valor_inicial;
      contador := contador + 1;

    ELSE -- Nova secao
      --  Entao gravamos o acumulado da sessao anterior
      IF valor_acumulado > 0 THEN
        -- DBMS_OUTPUT.PUT_LINE(l1_instid||';'||l1_sid||';'||l1_schemaname||';'||l1_timestamp||';'||tipo_estatistica||';'||valor_acumulado||';'||l1_machine||';'||l1_program);
        INSERT INTO TESTATISTICAS_RAC_TMP VALUES
        (l1_instid, l1_sid, l1_schemaname, l1_timestamp, tipo_estatistica,
        valor_acumulado, l1_machine, l1_program);

      ELSE --  Se valor_acumulado = 0, pode ser apenas uma entrada ou varias iguais
        IF contador > 1 THEN -- Varias entradas iguais, valor acumulado de fato eh zero!
          INSERT INTO TESTATISTICAS_RAC_TMP VALUES
          (l1_instid, l1_sid, l1_schemaname, l1_timestamp, tipo_estatistica,
           valor_acumulado, l1_machine, l1_program);
        ELSE
          --  So havia um registro, supoe que tudo foi gasto neste intervalo
          --   Como a [g]v$sesstat comeca com os dados a partir de 0, pode registrar o que tem
          -- DBMS_OUTPUT.PUT_LINE(l1_instid||';'||l1_sid||';'||l1_schemaname||';'||l1_timestamp||';'||tipo_estatistica||';'||l1_value||';'||l1_machine||';'||l1_program);
          INSERT INTO TESTATISTICAS_RAC_TMP VALUES
          (l1_instid, l1_sid, l1_schemaname, l1_timestamp, tipo_estatistica,
          l1_value, l1_machine, l1_program);
        END IF;
      END IF;
      contador := 1;
      valor_acumulado:= 0;
      valor_inicial:= l2_value;

    END IF;
    l1_instid:= l2_instid;
    l1_sid:= l2_sid;
    l1_schemaname:= l2_schemaname;
    l1_timestamp:= l2_timestamp;
    l1_machine:= l2_machine;
    l1_program:= l2_program;
    l1_value:= l2_value;

  END LOOP;

<<passo2>>
CLOSE dados;
RETURN;
END;
/
SHOW ERRORS;
QUIT;
