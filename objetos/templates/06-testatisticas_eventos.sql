-- TESTATISTICAS_EVENTOS: Descreve o campo EVENT da tabela TESTATISTICAS_RAC

CREATE PUBLIC SYNONYM TESTATISTICAS_EVENTOS FOR @SCHEMA@.TESTATISTICAS_EVENTOS;

CREATE TABLE TESTATISTICAS_EVENTOS (
  ANUM_EVENTO NUMBER NOT NULL,
  ADES_EVENTO  VARCHAR2(128),
  CONSTRAINT KESTATISTICAS_EVENTOS PRIMARY KEY (ANUM_EVENTO)
) TABLESPACE @TS_NAME@;

INSERT INTO  TESTATISTICAS_EVENTOS VALUES (0, 'Amostragem via Trigger de logon (TRG_LOGON)');
INSERT INTO  TESTATISTICAS_EVENTOS VALUES (1, 'Amostragem via Crontab');
INSERT INTO  TESTATISTICAS_EVENTOS VALUES (2, 'Amostragem via procedure de alteracao de modulo a ser substituido (PROSETANOMEMODULO)');
INSERT INTO  TESTATISTICAS_EVENTOS VALUES (3, 'Amostragem via procedure de alteracao de modulo que substitui outro modulo (PROSETANOMEMODULO)');
INSERT INTO  TESTATISTICAS_EVENTOS VALUES (4, 'Amostragem via Trigger de logoff (TRG_LOGOFF)');
INSERT INTO  TESTATISTICAS_EVENTOS VALUES (5, 'Amostragem legada ou nao categorizada');
COMMIT;
QUIT;
