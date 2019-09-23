Ferramenta de monitoração das estatisticas de desempenho do Oracle / Oracle RAC
===============================================================================

![img1](https://gitlab.almg.uucp/gti/gtec/oracle-estatisticas-servidor/raw/master/docs/estatisticas-workflow.png)


Instalação
===========
1. Fazer o download ou clone do repositório
2. Descompactar
3. Editar / verificar **TODOS** os parametros no arquivo env.sh
3.1. O usuário da variável **DBA** deve conectar no banco como **sysdba**
4. Executar o ./instala.sh
5. Os logs de instalação estarão no arquivo instala.log

Passos da instalacao
=====================
0. Verifica a estrutura dos diretórios para instalação
1. Cria a tablespace onde ficarão armazenadas as tabelas de desempenho
2. Cria o usuário / schema que irá conter os objetos de banco
3. Cria as [tabelas](https://gitlab.almg.uucp/gti/gtec/oracle-estatisticas-servidor/raw/master/docs/estatisticas-oracle-tabelas.png) (listadas no arquivo objetos/lista-objetos.txt)
4. Cria os scripts que coletam e analisam as estatísticas
5. Gera o arquivo com os parâmetros de login para execução dos scripts
6. Cria as procedures e triggers que alimentam ou analisam a tabela de estatistica
7. Gera a crontab para execucao dos scripts
8. Limpa o diretório dos arquivos copiados pela instalação

Documentação
============

* [Detalhes da implementação / desenvolvimento](https://gitlab.almg.uucp/gti/gtec/oracle-estatisticas-servidor/raw/master/docs/DBA%20Oracle%20Estatisticas.pdf)
* [Wiki](https://wiki.almg.gov.br/mediawiki/GTI/index.php5/Monitoramento_do_Oracle)


Desinstalação
=============
1. Editar / verificar **TODOS** os parametros no arquivo env.sh
4. Executar o ./desinstala.sh
5. Os logs de instalação estarão no arquivo desinstala.log
