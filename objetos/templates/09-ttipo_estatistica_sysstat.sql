-- Tabela auxiliar para guardar as descrições dos valores de GV$SYSSTAT
-- CLASS: TTIPO_ESTATISTICA_CLASSES <- GV$SYSSTAT
-- STAT_ID: GV$SYSSTAT

CREATE PUBLIC SYNONYM TTIPO_ESTATISTICA_SYSSTAT FOR @SCHEMA@.TTIPO_ESTATISTICA_SYSSTAT;
CREATE TABLE TTIPO_ESTATISTICA_SYSSTAT (
  STATISTIC#  NUMBER,
  NAME        VARCHAR2(64),
  CLASS       NUMBER,
  STAT_ID     NUMBER,
  DESCRIPTION VARCHAR(1024)
) TABLESPACE @TS_NAME@;

INSERT INTO TTIPO_ESTATISTICA_SYSSTAT VALUES (1, 'Requests to/from client', 1, 3982115148, 'Não documentado. Provavelmente é a quantidade de requisições que chegam dos clientes para o servidor e vice-versa.');
INSERT INTO TTIPO_ESTATISTICA_SYSSTAT VALUES (14, 'session logical reads', 1, 3143187968, '"db block gets" + "consistent gets". Inclui leituras lógicas de blocos de dados da buffer cache ou memória privada.');
INSERT INTO TTIPO_ESTATISTICA_SYSSTAT VALUES (19, 'CPU used by this session', 1, 24469293, 'Utilização geral de CPU em centissegundos (conta o tempo ocioso).');
INSERT INTO TTIPO_ESTATISTICA_SYSSTAT VALUES (20, 'DB time', 1, 3649082374, 'Gasto efetivo de CPU em centissegundos.');
INSERT INTO TTIPO_ESTATISTICA_SYSSTAT VALUES (24, 'user I/O wait time', 1, 3332107451, 'Tempo total N em 100s de espera de usuário por I/O (classe User I/O wait) ou n / 100 segundos.');
INSERT INTO TTIPO_ESTATISTICA_SYSSTAT VALUES (26, 'non-idle wait time', 1, 2498191658, 'Não documentado. Provavelmente é o tempo médio de espera não ociosa por recursos (ex: espera por I/O ou por um row lock).');
INSERT INTO TTIPO_ESTATISTICA_SYSSTAT VALUES (100, 'db block changes', 8, 916801489, 'Alterações via update ou delete. Essas alterações geram registros de redo log e tornam-se permanentes caso o commit seja feito.');
INSERT INTO TTIPO_ESTATISTICA_SYSSTAT VALUES (230, 'file io service time', 1, 3999659096, 'Não documentado. Provavelmente é o tempo gasto com I/O para operações com arquivos.');
INSERT INTO TTIPO_ESTATISTICA_SYSSTAT VALUES (231, 'file io wait time', 1, 1292757183, 'Não documentado. Deve incluir o tempo de espera na fila + tempo de serviço.');
INSERT INTO TTIPO_ESTATISTICA_SYSSTAT VALUES (630, 'bytes sent via SQL*Net to client', 1, 2967415760, 'Bytes enviados para os clientes. Indica volume de dados que trafega na rede do Oracle para os clientes (resultados de consultas).');
INSERT INTO TTIPO_ESTATISTICA_SYSSTAT VALUES (631, 'bytes received via SQL*Net from client', 1, 161936656, 'Bytes recebidos dos clientes. Indica tamanho + quantidade de consultas que o banco processa.');
INSERT INTO TTIPO_ESTATISTICA_SYSSTAT VALUES (633, 'bytes sent via SQL*Net to dblink', 1, 1622773540, 'Bytes enviados via DB Link.');
INSERT INTO TTIPO_ESTATISTICA_SYSSTAT VALUES (634, 'bytes received via SQL*Net from dblink', 1, 1983609624, 'Bytes recebidos via DB Link.');
COMMIT;
QUIT;
