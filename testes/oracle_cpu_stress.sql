SET SERVEROUTPUT ON
SET TIMING ON

-- Teste sem utilização de CPU, leitura ou escrita. Apenas tempo ocioso.
CREATE OR REPLACE PROCEDURE IDLETEST(SECONDS FLOAT DEFAULT 1) IS
BEGIN
  DBMS_LOCK.SLEEP(SECONDS);
END;
/

-- Teste de stress: muito uso de CPU, nenhuma leitura ou escrita
-- Sem execução de SQL (em teoria, não atualiza a V$SQL/V$SESSTAT)
-- Padrão: 100.000.000 (~ 20s)
CREATE OR REPLACE PROCEDURE CPUTEST1(NLOOPS INT DEFAULT 100000000) IS
  a number := 1;
begin 
  for i in 1..nloops loop
    a := ( a + i )/11;
  end loop;
end;
/


-- Teste de stress: muito uso de CPU, nenhuma leitura ou escrita
-- Com execução de SQL (atualiza a V$SQL/V$SESSTAT)
CREATE OR REPLACE PROCEDURE CPUTEST2(NLOOPS INT DEFAULT 100000000) IS
  a number := 1;
begin 
  for i in 1..nloops loop
    IF MOD(I, 1000) = 0 THEN
      SELECT ( a + i )/11 INTO a FROM DUAL;
    END IF;
  end loop;
end;
/

-- Teste de stress: pouca CPU, pouca leitura, muita escrita
-- Cria uma tabela randomica, escreve nela e deleta
-- NLOOPS:  Número de tabelas criadas
-- NTAMTAB: Número de linhas de cada tabela
-- NTAMSTR: Tamanho do texto "long" da tabela
CREATE OR REPLACE PROCEDURE WRITETEST(NLOOPS INT DEFAULT 20, NTAMTAB INT DEFAULT 10000, NTAMSTR INT DEFAULT 1000) IS
  fixname varchar2(9) := 'ZZZ_RAND_'; -- nome da tabela pref
  suffix varchar2(10);                -- nome da tabela suf
  tabname varchar2(19);               -- nome da tabela
  sqltable long;                      -- sql executada
  tabfields long := ' (a number, b number, c varchar2(32), d long)';
  longtext long;
begin
  dbms_output.put_line('Serão criadas '||nloops||' tabelas com '||ntamtab||' linhas');
  dbms_output.put_line('');
  dbms_output.put_line('');
  dbms_lock.sleep(1);
  for i in 1..nloops loop
    suffix := dbms_random.string('U', 10);
    tabname := fixname||suffix;
    sqltable := 'CREATE TABLE '||tabname||tabfields;
    dbms_output.put_line(sqltable);
    execute immediate(sqltable);
    
    dbms_output.put_line('Inserindo '||ntamtab||' linhas em '||tabname);
    for j in 1..ntamtab loop
      longtext := tabname||dbms_random.string('U', ntamstr);
      sqltable := 'INSERT INTO '||tabname||' VALUES ('||i||','||j||', '''||tabname||''','''||longtext||''')';
      --dbms_output.put_line('Interno '||j||': '||sqltable);
      execute immediate(sqltable);
    end loop;
    --execute immediate('COMMIT');
    
    sqltable := 'DROP TABLE '||tabname;
    dbms_output.put_line(sqltable);
    execute immediate(sqltable);
  end loop;
end;
/
-- Se sobrar alguma, remover
--select table_name from dba_tables where table_name like 'ZZZ_RAND%';


-- Teste de stress: pouca CPU, muita leitura, nenhuma escrita
-- Tabela grande, com indice em timestamp
CREATE OR REPLACE PROCEDURE READTEST(NLOOPS INT DEFAULT 10) IS 
  v0 number;
begin
  for i in 1..nloops loop
    SELECT COUNT(1) INTO v0 FROM TESTATISTICAS_RAC;
    dbms_output.put_line('Iteração: '||i||'; Contagem: '||v0);
  end loop;
end;
/

quit;
