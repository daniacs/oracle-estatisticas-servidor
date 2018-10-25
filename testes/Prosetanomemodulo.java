/*
 * Teste de utilizacao de recursos no Oracle e registro nas tabelas
 * V$SESSION e V$SESSTAT
 *
 * Procedure PROSETANOMEMODULO insere os dados da
 * V$SESSTAT na tabela TESTATISTICAS_RAC
 *
 *      *******************************************
 *      * Fazer este teste APENAS EM HOMOLOGAÇÃO! *
 *      *******************************************
 *
 *
 * APPTESTE0: Nenhuma utilização de CPU
 * APPTESTE1: Muita utilização de CPU em apenas uma SQL (stored procedure)
 * APPTESTE2: Muita utilização de CPU em várias SQLs
 * APPTESTE3: Nenhuma utilização de CPU
 *
 * Criação das procedures no Oracle:

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

*/

import java.io.*;
import java.util.*;
import java.sql.*;

class Prosetanomemodulo {

  public static void main(String args[]) throws Exception {
    Class.forName("oracle.jdbc.OracleDriver");
    String url = "jdbc:oracle:thin:@homoloracle.almg.uucp:1521/P10";
    Connection connection = null;
    String username = "<USUARIO>";
    String password = "<SENHA>";
    Properties jdbcProperties = new Properties();
    jdbcProperties.put("user", username);
    jdbcProperties.put("password", password);
    // Padrao na v$session (PROGRAM e MODULE): "JDBC Thin Client"
    //jdbcProperties.put("v$session.program", "APPTESTE0");
    float seconds = 2;
    int operations = 50000000;
    long ti, tf;
    double delta;

    ti = System.nanoTime();

    try {
      connection = DriverManager.getConnection(url, jdbcProperties);
    } catch (SQLException e) {
      System.out.println("Conexão falhou");
      e.printStackTrace();
      return;
    }

    if (connection != null) {

      tf = System.nanoTime();
      delta = (tf - ti)/1e9;
      System.out.println("Tempo de conexao: " + delta);
      String query;
      Statement stmt;
      ResultSet rs;

      /* Pegar o SID */
      query = "SELECT SYS_CONTEXT('USERENV', 'SID') AS SID FROM DUAL";
      stmt = connection.createStatement();
      rs = stmt.executeQuery(query);
      rs.next();
      String sid = rs.getString("SID");
      System.out.println("SID: "+sid);
      query = "SELECT * FROM DUAL";

      //http://www.guj.com.br/t/como-acessar-stored-procedures-oracle-em-java/108518/4
      CallableStatement cStmt = null;

      System.out.println("JDBC Thin Client - sleep "+seconds+"s");
      ti = System.nanoTime();
      cStmt = connection.prepareCall("{CALL DBMS_LOCK.SLEEP(?)}");
      cStmt.setFloat(1, seconds);
      cStmt.execute();
      tf = System.nanoTime();
      delta = (tf - ti)/1e9;
      System.out.println("Tempo JDBC Thin Client: DBMS_LOCK.SLEEP("+seconds+"): "+delta);

      /* "APPTESTE0": so sleep, sem uso de CPU */
      System.out.println("APPTESTE0");
      cStmt = connection.prepareCall("{CALL DBMS_APPLICATION_INFO.SET_MODULE(?,NULL)}");
      cStmt.setString(1, "APPTESTE0");
      cStmt.execute();
      ti = System.nanoTime();
      cStmt = connection.prepareCall("{CALL DBMS_LOCK.SLEEP(?)}");
      cStmt.setFloat(1, seconds);
      cStmt.execute();
      tf = System.nanoTime();
      delta = (tf - ti)/1e9;
      System.out.println("Tempo APPTESTE0: DBMS_LOCK.SLEEP("+seconds+"): "+delta);

      /* "APPTESTE1": uso intenso de CPU */
      System.out.println("APPTESTE1 - CPUTEST1("+operations+")");
      cStmt = connection.prepareCall("{CALL PROSETANOMEMODULO(?, ?)}");
      cStmt.setString("next_mod", "APPTESTE1");
      cStmt.setString("pSID", sid);
      cStmt.execute();
      ti = System.nanoTime();
      cStmt = connection.prepareCall("{CALL CPUTEST1(?)}");
      cStmt.setInt(1, operations);
      cStmt.execute();
      tf = System.nanoTime();
      delta = (tf - ti)/1e9;
      System.out.println("Tempo APPTESTE1: CPUTEST1("+operations+"): "+ delta);


      /* APPTESTE2: mais uso de CPU (metade de APPTESTE1) */
      System.out.println("APPTESTE2 - CPUTEST2("+operations+")");
      cStmt = connection.prepareCall("{CALL PROSETANOMEMODULO(?, ?)}");
      cStmt.setString(1, "APPTESTE2");
      cStmt.setString(2, sid);
      cStmt.execute();
      ti = System.nanoTime();
      cStmt = connection.prepareCall("{CALL CPUTEST2(?)}");
      cStmt.setInt(1, operations);
      cStmt.execute();
      tf = System.nanoTime();
      delta = (tf - ti)/1e9;
      System.out.println("Tempo APPTESTE2: CPUTEST2("+operations+"): "+ delta);

      /* APPTESTE3: sem uso de CPU */
      System.out.println("APPTESTE3 - sleep "+seconds+"s");
      cStmt = connection.prepareCall("{CALL PROSETANOMEMODULO(?, ?)}");
      cStmt.setString(1, "APPTESTE3");
      cStmt.setString(2, sid);
      cStmt.execute();
      ti = System.nanoTime();
      cStmt = connection.prepareCall("{CALL DBMS_LOCK.SLEEP(?)}");
      cStmt.setFloat(1, seconds);
      cStmt.execute();
      tf = System.nanoTime();
      delta = (tf - ti)/1e9;
      System.out.println("Tempo APPTESTE3: DBMS_LOCK.SLEEP("+seconds+"): "+ delta);

      connection.close();
    }
    else {
      System.out.println("Deu ruim");
    }
  }
}
