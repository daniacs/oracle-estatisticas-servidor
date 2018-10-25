-- TTIPO_ESTATISTICA_RAC: Tabela com os dados das estatisticas. 
-- O campo STATISTIC_OLD identifica contadores da versao 10 do Oracle.
-- O campo ANOM_ESTATISTICA e o campo NAME da vista GV$STATNAME.

CREATE PUBLIC SYNONYM TTIPO_ESTATISTICA_RAC FOR @SCHEMA@.TTIPO_ESTATISTICA_RAC;

CREATE TABLE TTIPO_ESTATISTICA_RAC (
  STATISTIC#        NUMBER(22) NOT NULL,
  STATISTIC_OLD NUMBER(22) NOT NULL,
  ACOD_ESTATISTICA  VARCHAR(64),
  ANOM_ESTATISTICA  VARCHAR2(64) NOT NULL,
  ADES_ESTATISTICA  VARCHAR2(1024),
  CONSTRAINT KTIPO_ESTATISTICA_RAC PRIMARY KEY("STATISTIC#")
) TABLESPACE @TS_NAME@;

INSERT INTO  TTIPO_ESTATISTICA_RAC VALUES (14, 12, 'LEITURAS', 'session logical reads', 'Soma dos valores (db_block_gets + consistent_gets). Inclui leituras logicas do banco tanto do buffer cache quanto de memoria privada/protegida');
INSERT INTO  TTIPO_ESTATISTICA_RAC VALUES (19, 17, 'CPU', 'CPU used by this session', 'Tempo total de CPU utilizado por uma sessao entre o inicio e o final de uma chamada de usuario (user call) em unidades de 10 milissegundos. Se a chamada terminar em menos de 10 ms, o valor de 0 (zero) e computado.');
INSERT INTO  TTIPO_ESTATISTICA_RAC VALUES (100, 84, 'ALTERACOES', 'db block changes', 'Número total de alteracões que foram parte de uma operacao de DELETE ou UPDATE. Essas alteracões geram registros de redo log, tornando-se permanentes caso seja feito um COMMIT da transacao. Aproxima-se do trabalho total do banco, indicando a taxa na qual os buffers vao sendo "sujos" (buffers/transacao/segundo)');
COMMIT;
QUIT;
