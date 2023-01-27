﻿USE tsql_erpProject
GO

-- EMPRESA
INSERT INTO EMPRESA
VALUES
	('XYZ BIKES', 'MATRIZ'),
	('XYZ BIKES', 'FILIAL');

SELECT *
FROM EMPRESA

-- PARÂMETROS
INSERT INTO PARAMETROS
VALUES
	(1, 'PED_COMPRAS', 0),
	(1, 'MATRICULA', 0),
	(1, 'PED_VENDAS', 0),
	(1, 'NOTA_FISCAL', 0),
	(2, 'PED_COMPRAS', 0),
	(2, 'MATRICULA', 0),
	(2, 'PED_VENDAS', 0),
	(2, 'NOTA_FISCAL', 0)

SELECT *
FROM PARAMETROS;

--CARGA TABLE UF
INSERT INTO  UF
SELECT DISTINCT B.UF, A.estado
FROM CURSO.DBO.UF a
	INNER JOIN CURSO.DBO.senso b
	ON a.COD_UF=b.cod_uf

SELECT *
FROM UF

-- TABELA CIDADES
INSERT INTO CIDADES
SELECT cod_uf+cod_mun, UF, NOME_MUN
FROM CURSO.DBO.senso

SELECT *
FROM CIDADES

-- CLIENTES
INSERT INTO CLIENTES
VALUES
	(1, 'CARLOS JACOB HOUSTON', 'CARLOS', 'RUA 1', '375', 'SANTA HELENA', '4203709', '13290000', '123456987', 'F', GETDATE(), 1),
	(1, 'PEDRO LARSON OHIO', 'PEDRO', 'RUA 2', '235', 'SANTA CLARA', '4119608', '13290987', '123456989', 'F', GETDATE(), 2),
	(2, 'BIKES ON LTDA', 'BIKES ON', 'RUA 14', '279', 'MONTANHA', '5300108', '13293245', '343456987', 'J', GETDATE(), 3),
	(2, 'MY BIKE MY LIFE SA', 'BIKE LIFE', 'RUA 23', '675', 'ALPES', '3509502', '13379245', '11290340', 'J', GETDATE(), 3)

SELECT *
FROM CLIENTES

-- FORNECEDORES	
INSERT INTO  FORNECEDORES
VALUES
	(1, 'SO BIKES LTDA', 'SO BIKES', 'RUA 10', '375', 'SANTA HILDA', '4203709', '13290000', '123456987', 'J', GETDATE(), 1),
	(1, 'ESPECIAL BIKES LTDA', 'ESPECIAL BIKES', 'RUA 2', '235', 'SANTA GENEBRA', '4119608', '13290987', '123456989', 'J', GETDATE(), 2),
	(2, 'MONTA BIKES ME', 'MONTA BIKES', 'RUA 67', '345', 'ALADO', '5300108', '13293245', '343456987', 'J', GETDATE(), 3),
	(2, 'TRAIL BIKES ME', 'TRAIL BIKES', 'RUA 70', '345', 'ESFERA', '5300108', '13293245', '343456987', 'J', GETDATE(), 3)

SELECT *
FROM FORNECEDORES

-- TIPO DE MATERIAL
INSERT INTO TIPO_MAT
VALUES
	(1, 1, 'MATERIA PRIMA'),
	(1, 2, 'PRODUDO ACABADO'),
	(1, 3, 'EMBALAGEM'),
	(1, 4, 'CONSUMO');
INSERT INTO TIPO_MAT
VALUES
	(2, 1, 'MATERIA PRIMA'),
	(2, 2, 'PRODUDO ACABADO'),
	(2, 3, 'EMBALAGEM'),
	(2, 4, 'CONSUMO');

SELECT *
FROM TIPO_MAT

--CARGA MATERIAL
--COD TIPO MAT
/* 
1 - MATERIA PRIMA
2 - PRODUDO ACABADO
3 -	EMBALAGEM
4 - CONSUMO
*/
--SELECT * FROM MATERIAL
--DELETE FROM MATERIAL
--DBCC Checkident( MATERIAL, reseed, 0)
INSERT INTO MATERIAL
VALUES
	(1, 1, 'BICICLETA ARO 29 PRETA MOD INFINITY', '2500', '2', ''),
	(1, 2, 'BICICLETA ARO 29 BRANCA MOD INFINITY', '2500', '2', ''),
	(1, 3, 'QUADRO ARO 29', '500', '1', '1'),
	(1, 4, 'KIT TRANSMISSAO', '500', '1', '1'),--FREIO+MARCHA-PEDEVELA-TROCADORES+K-7
	(1, 5, 'ARO 29', '70', '1', '1'),
	(1, 6, 'PNEU 29', '100', '1', '2'),
	(1, 7, 'CAMARA 29', '25', '1', '2'),
	(1, 8, 'SUSPENSAO DIANTEIRA', '250', '1', '2'),
	(1, 9, 'BANCO', '80', '1', '3'),
	(1, 10, 'CANOTE', '35', '1', '3'),
	(1, 11, 'TINTA BRANCA', '10', '4', '2'),
	(1, 12, 'TINTA PRETA', '10', '4', '2'),
	(1, 13, 'MESA', '500', '1', '1'),
	(1, 14, 'GUIDON', '50', '1', '2'),
	(1, 15, 'LUVAS', '30', '1', '2'),
	(1, 16, 'CAIXA EMBALAGEM', '10', '3', '2')

SELECT *
FROM MATERIAL

-- FICHA TECNICA BIKE PRETA	
INSERT INTO FICHA_TECNICA
VALUES
	(1, '1', '3', 1),
	(1, '1', '4', 1),
	(1, '1', '5', 2),
	(1, '1', '6', 2),
	(1, '1', '7', 2),
	(1, '1', '8', 1),
	(1, '1', '9', 1),
	(1, '1', '10', 1),
	(1, '1', '12', 0.250),
	(1, '1', '13', 1),
	(1, '1', '14', 1),
	(1, '1', '15', 2),
	(1, '1', '16', 1);

--FICHA TECNICA BIKE BRANCA
INSERT INTO FICHA_TECNICA
VALUES
	(1, '2', '3', 1),
	(1, '2', '4', 1),
	(1, '2', '5', 2),
	(1, '2', '6', 2),
	(1, '2', '7', 2),
	(1, '2', '8', 1),
	(1, '2', '9', 1),
	(1, '2', '10', 1),
	(1, '2', '11', 0.250),
	(1, '2', '13', 1),
	(1, '2', '14', 1),
	(1, '2', '15', 2),
	(1, '2', '16', 1)

SELECT *
FROM FICHA_TECNICA

-- CENTRO DE CUSTOS
INSERT INTO CENTRO_CUSTO
VALUES
	(1, '9001', 'PRESIDENCIA')
INSERT INTO CENTRO_CUSTO
VALUES
	(1, '9002', 'ADMINISTRATIVO')
INSERT INTO CENTRO_CUSTO
VALUES
	(1, '9003', 'PRODUCAO')
INSERT INTO CENTRO_CUSTO
VALUES
	(1, '9004', 'SUPRIMENTOS')
INSERT INTO CENTRO_CUSTO
VALUES
	(1, '9005', 'RH')
INSERT INTO CENTRO_CUSTO
VALUES
	(1, '9006', 'FINANCEIRO')
INSERT INTO CENTRO_CUSTO
VALUES
	(1, '9007', 'COMERCIAL')
INSERT INTO CENTRO_CUSTO
VALUES
	(1, '9008', 'FISCAL')
INSERT INTO CENTRO_CUSTO
VALUES
	(1, '9009', 'TI')

INSERT INTO CENTRO_CUSTO
VALUES
	(2, '9001', 'PRESIDENCIA')
INSERT INTO CENTRO_CUSTO
VALUES
	(2, '9002', 'ADMINISTRATIVO')
INSERT INTO CENTRO_CUSTO
VALUES
	(2, '9003', 'PRODUCAO')
INSERT INTO CENTRO_CUSTO
VALUES
	(2, '9004', 'SUPRIMENTOS')
INSERT INTO CENTRO_CUSTO
VALUES
	(2, '9005', 'RH')
INSERT INTO CENTRO_CUSTO
VALUES
	(2, '9006', 'FINANCEIRO')
INSERT INTO CENTRO_CUSTO
VALUES
	(2, '9007', 'COMERCIAL')
INSERT INTO CENTRO_CUSTO
VALUES
	(2, '9008', 'FISCAL')
INSERT INTO CENTRO_CUSTO
VALUES
	(2, '9009', 'TI')

SELECT *
FROM CENTRO_CUSTO

-- CARGOS FUNCOES
INSERT INTO CARGOS
VALUES
	(1, 'PRESIDENTE'),
	(1, 'GER COMERCIAL'),
	(1, 'VENDEDOR'),
	(1, 'GER ADM'),
	(1, 'ASSISTENTE DE RH'),
	(1, 'OPERADOR PRODUCAO'),
	(1, 'ESTOQUISTA'),
	(1, 'ANALISTA DE SISTEMA'),
	(1, 'FATURISTA'),
	(1, 'ASSISTENTE FINANCEIRO')

-- DESABILITAR O IDENTITY PARA INSERIR INFORMAÇÕES NUMERANDO MANUALMENTE
SET IDENTITY_INSERT CARGOS ON  
GO
INSERT INTO CARGOS
	(COD_EMPRESA,COD_CARGO,NOME_CARGO)
SELECT 2, COD_CARGO, NOME_CARGO
FROM CARGOS
GO
SET IDENTITY_INSERT CARGOS OFF
GO

SELECT *
FROM CARGOS

-- TRIGGER PARA CALCULAR MATRÍCULA DE FUNCIONÁRIO 
CREATE TRIGGER TG_NUM_MATR ON FUNCIONARIO
 INSTEAD OF INSERT AS
BEGIN

	DECLARE @PARAM VARCHAR(50),
			@MATRICULA INT,
			@COD_EMPRESA INT
	--ATRIBUI PARAMETRO PESQUISA
	SET @PARAM='MATRICULA'
	--ATRIBUI VALORES VARIAVEL
	SELECT @MATRICULA = MATRICULA, @COD_EMPRESA = COD_EMPRESA
	FROM INSERTED
	-- CONDIÇÃO 
	IF @MATRICULA = 0
		  BEGIN
		--PEGANDO NUMERO PARA AUTO NUMERAR
		SELECT @MATRICULA = VALOR + 1
		FROM PARAMETROS
		WHERE PARAM = @PARAM
			AND COD_EMPRESA = @COD_EMPRESA

		-- REALIZA INSERT NA TABELA DESEJADA
		INSERT INTO FUNCIONARIO
		SELECT
			COD_EMPRESA, @MATRICULA, COD_CC, NOME, RG, CPF, ENDERECO, NUMERO, BAIRRO, COD_CIDADE,
			DATA_ADMISS, DATE_DEMISS, DATA_NASC, TELEFONE, COD_CARGO
		FROM INSERTED
		WHERE 1 = 1
		-- REALIZA UPDATE DA TABELA PARAMETROS
		UPDATE PARAMETROS SET VALOR=VALOR+1
				WHERE PARAM=@PARAM
			AND COD_EMPRESA=@COD_EMPRESA
	END
END 

-- FUNCIONARIO 
INSERT INTO FUNCIONARIO
VALUES
	(1, 0, '9001', 'JAMES LABRIE', '1234567', '123567990', 'RUA 1', '2', 'SANTA CLAUS', '3525904', '2017-01-03', '', '1980-12-25', '', '1')
INSERT INTO FUNCIONARIO
VALUES
	(1, 0, '9002', 'JONH LARAVEL', '1234568', '123567889', 'RUA 2', '3', 'SANTA CLAUS', '3525904', '2017-02-10', '', '1980-12-25', '', '4')
INSERT INTO FUNCIONARIO
VALUES
	(1, 0, '9003', 'PETER DOTNESK', '3434568', '123564578', 'RUA 3', '4', 'SANTA CLAUS', '3525904', '2017-02-09', '', '1980-12-25', '', '6')
INSERT INTO FUNCIONARIO
VALUES
	(1, 0, '9004', 'LARA POTTER', '4434509', '123576867', 'RUA 4', '5', 'SANTA CLAUS', '3525904', '2017-03-07', '', '1980-12-25', '', '7')
 INSERT INTO FUNCIONARIO
VALUES
	(1, 0, '9005', 'JESSICA SUTER', '4534576', '120367887', 'RUA 5', '6', 'SANTA CLAUS', '3525904', '2017-03-03', '', '1980-12-25', '', '5')
INSERT INTO FUNCIONARIO
VALUES
	(1, 0, '9006', 'PEDRO TESLA', '4334568', '123703885', 'RUA 6', '7', 'SANTA CLAUS', '3525904', '2017-04-15', '', '1980-12-25', '', '1')
INSERT INTO FUNCIONARIO
VALUES
	(1, 0, '9007', 'TIAGO FIELDER', '9834568', '147034889', 'RUA 7', '8', 'SANTA CLAUS', '3525904', '2017-04-20', '', '1980-12-25', '', '2')
INSERT INTO FUNCIONARIO
VALUES
	(1, 0, '9007', 'MALCON DEXTER', '9834568', '147067889', 'RUA 17', '28', 'SANTA CLAUS', '3525904', '2017-04-20', '', '1980-12-25', '', '3')
 INSERT INTO FUNCIONARIO
VALUES
	(1, 0, '9007', 'CHARLES NOIX', '9894668', '147067149', 'RUA 77', '18', 'SANTA CLAUS', '3525904', '2017-04-20', '', '1980-12-25', '', '3')
 INSERT INTO FUNCIONARIO
VALUES
	(1, 0, '9008', 'JOAO SPARK', '7734568', '643567888', 'RUA 8', '22', 'SANTA CLAUS', '3525904', '2017-05-07', '', '1980-12-25', '', '9')
INSERT INTO FUNCIONARIO
VALUES
	(1, 0, '9009', 'DAVID MANDRAKE', '6634568', '345567887', 'RUA 8', '56', 'SANTA CLAUS', '3525904', '2017-05-07', '', '1980-12-25', '', '8')
INSERT INTO FUNCIONARIO
VALUES
	(1, 0, '9002', 'SAMUEL DUPRET', '8984568', '159567887', 'RUA 23', '89', 'SANTA CLAUS', '3525904', '2017-05-07', '', '1980-12-25', '', '10')

SELECT *
FROM FUNCIONARIO
SELECT *
FROM PARAMETROS

-- USUARIOS
INSERT INTO USUARIOS
	(COD_EMPRESA,LOGIN,MATRICULA,SENHA,SITUACAO)
VALUES
	(1, 'JAMESL', '1', '', 'A'),
	(1, 'JONHL', '2', '', 'A'),
	(1, 'PETERD', '3', '', 'A'),
	(1, 'LARAP', '4', '', 'A'),
	(1, 'JESSICAS', '5', '', 'A'),
	(1, 'PEDROT', '6', '', 'A'),
	(1, 'TIAGOF', '7', '', 'A'),
	(1, 'MALCOND', '8', '', 'A'),
	(1, 'CHARLESN', '9', '', 'A'),
	(1, 'JOAOS', '10', '', 'A'),
	(1, 'DAVIDM', '11', '', 'A'),
	(1, 'SAMUELD', '12', '', 'A')

SELECT *
FROM USUARIOS

--- CRIPTOGRAFAR E GRAVAR SENHA COM MD5 SENDO A SENHA INICIAL IGUAL A MATRICULA
UPDATE USUARIOS 
SET SENHA = CONVERT(VARCHAR(32), HashBytes('MD5', CONVERT(varchar,matricula)), 2);

-- CONDIÇÃO DE PAGAMENTO
INSERT INTO COND_PAGTO
VALUES
	('A VISTA'),
	('3 X 30/60/90 DD'),
	('30 DD')

SELECT *
FROM COND_PAGTO

-- DETALHES DAS CONDIÇÕES DE PAGAMENTO 
INSERT INTO COND_PAGTO_DET
VALUES
	('1', '1', 0, 100)

INSERT INTO COND_PAGTO_DET
VALUES
	('2', '1', 30, 33.34),
	('2', '2', 60, 33.33),
	('2', '3', 90, 33.33)

INSERT INTO COND_PAGTO_DET
VALUES
	('3', '1', 30, 100);

SELECT *
FROM COND_PAGTO_DET

-- VENDEDORES
 INSERT INTO VENDEDORES
SELECT A.COD_EMPRESA, A.MATRICULA
FROM FUNCIONARIO A
	INNER JOIN CARGOS B
	ON A.COD_EMPRESA=B.COD_EMPRESA
		AND A.COD_CARGO=B.COD_CARGO
WHERE B.NOME_CARGO='VENDEDOR'
	AND NOT EXISTS (SELECT 1
	FROM VENDEDORES);

SELECT *
FROM VENDEDORES

-- GERENTES
INSERT INTO GERENTES
SELECT A.COD_EMPRESA, A.MATRICULA
FROM FUNCIONARIO A
	INNER JOIN CARGOS B
	ON A.COD_EMPRESA=B.COD_EMPRESA
		AND A.COD_CARGO=B.COD_CARGO
WHERE B.NOME_CARGO='GER COMERCIAL'
	AND NOT EXISTS (SELECT 1
	FROM GERENTES)

 SELECT *
FROM FUNCIONARIO

-- GERENTE X VENDEDOR
INSERT INTO CANAL_VENDAS_G_V
VALUES
	(1, 7, 8),
	(1, 7, 9)

SELECT *
FROM CANAL_VENDAS_G_V

-- VENDEDOR X CLIENTE
INSERT CANAL_VENDAS_V_C
VALUES
	(1, 8, 1),
	(1, 9, 2)

SELECT *
FROM CANAL_VENDAS_V_C

-- META DE VENDAS
 INSERT INTO META_VENDAS
VALUES
	(1, 9, '2018', '01', 83.33),
	(1, 9, '2018', '02', 83.33),
	(1, 9, '2018', '03', 83.33),
	(1, 9, '2018', '04', 83.33),
	(1, 9, '2018', '05', 83.33),
	(1, 9, '2018', '06', 83.33),
	(1, 9, '2018', '07', 83.33),
	(1, 9, '2018', '08', 83.33),
	(1, 9, '2018', '09', 83.33),
	(1, 9, '2018', '10', 83.33),
	(1, 9, '2018', '11', 83.33),
	(1, 9, '2018', '12', 83.33)

   INSERT INTO META_VENDAS
VALUES
	(1, 8, '2018', '01', 83.33),
	(1, 8, '2018', '02', 83.33),
	(1, 8, '2018', '03', 83.33),
	(1, 8, '2018', '04', 83.33),
	(1, 8, '2018', '05', 83.33),
	(1, 8, '2018', '06', 83.33),
	(1, 8, '2018', '07', 83.33),
	(1, 8, '2018', '08', 83.33),
	(1, 8, '2018', '09', 83.33),
	(1, 8, '2018', '10', 83.33),
	(1, 8, '2018', '11', 83.33),
	(1, 8, '2018', '12', 83.33)
 
SELECT *
FROM META_VENDAS

 -- CODIGO DE OPERACAOS FISCAIS
  INSERT INTO CFOP
VALUES
	('5.101', 'VENDAS DE MERC'),
	('1.101', 'COMPRAS DE MERC')

-- TRIGGER PARA NUMERAR PEDIDOS DE VENDA
CREATE TRIGGER TG_NUM_PED_V ON PED_VENDAS
 INSTEAD OF INSERT AS
BEGIN

	DECLARE @PARAM VARCHAR(50),
			@NUM_PEDIDO INT,
			@COD_EMPRESA INT

	SET     @PARAM='PED_VENDAS'

	SELECT @NUM_PEDIDO = NUM_PEDIDO, @COD_EMPRESA = COD_EMPRESA
	FROM INSERTED

	IF @NUM_PEDIDO IS NULL
		  BEGIN
		SELECT @NUM_PEDIDO = VALOR + 1
		FROM PARAMETROS
		WHERE PARAM = @PARAM
			AND COD_EMPRESA = @COD_EMPRESA
		-- REALIZA INSERT
		INSERT INTO PED_VENDAS
		SELECT
			COD_EMPRESA, @NUM_PEDIDO, ID_CLIENTE, COD_PAGTO, DATA_PEDIDO, DATA_ENTREGA, SITUACAO, 0
		FROM INSERTED
		WHERE 1 = 1
		-- REALIZA O UPDDATE DOS PARÂMETROS
		UPDATE PARAMETROS SET VALOR = VALOR + 1
				WHERE PARAM = @PARAM
			AND COD_EMPRESA = @COD_EMPRESA
	END
END 

-- PED_VENDAS (CABEÇALHO)
INSERT INTO PED_VENDAS
	(COD_EMPRESA,ID_CLIENTE,COD_PAGTO,DATA_PEDIDO,DATA_ENTREGA,SITUACAO)
VALUES
	(1, 1, 1, '2018-01-13', '2018-01-29', 'A')
INSERT INTO PED_VENDAS
	(COD_EMPRESA,ID_CLIENTE,COD_PAGTO,DATA_PEDIDO,DATA_ENTREGA,SITUACAO)
VALUES
	(1, 2, 3, '2018-02-13', '2018-02-28', 'A')
INSERT INTO PED_VENDAS
	(COD_EMPRESA,ID_CLIENTE,COD_PAGTO,DATA_PEDIDO,DATA_ENTREGA,SITUACAO)
VALUES
	(1, 1, 2, '2018-03-13', '2018-03-29', 'A')
 INSERT INTO PED_VENDAS
	(COD_EMPRESA,ID_CLIENTE,COD_PAGTO,DATA_PEDIDO,DATA_ENTREGA,SITUACAO)
VALUES
	(1, 2, 2, '2018-04-13', '2018-04-29', 'A')
INSERT INTO PED_VENDAS
	(COD_EMPRESA,ID_CLIENTE,COD_PAGTO,DATA_PEDIDO,DATA_ENTREGA,SITUACAO)
VALUES
	(1, 2, 3, '2018-05-13', '2018-05-29', 'A')
 INSERT INTO PED_VENDAS
	(COD_EMPRESA,ID_CLIENTE,COD_PAGTO,DATA_PEDIDO,DATA_ENTREGA,SITUACAO)
VALUES
	(1, 1, 3, '2018-06-13', '2018-06-29', 'A')
 INSERT INTO PED_VENDAS
	(COD_EMPRESA,ID_CLIENTE,COD_PAGTO,DATA_PEDIDO,DATA_ENTREGA,SITUACAO)
VALUES
	(1, 2, 1, '2018-07-13', '2018-07-29', 'A')
 INSERT INTO PED_VENDAS
	(COD_EMPRESA,ID_CLIENTE,COD_PAGTO,DATA_PEDIDO,DATA_ENTREGA,SITUACAO)
VALUES
	(1, 1, 3, '2018-08-13', '2018-08-29', 'A')
 INSERT INTO PED_VENDAS
	(COD_EMPRESA,ID_CLIENTE,COD_PAGTO,DATA_PEDIDO,DATA_ENTREGA,SITUACAO)
VALUES
	(1, 2, 2, '2018-09-13', '2018-09-29', 'A')
 INSERT INTO PED_VENDAS
	(COD_EMPRESA,ID_CLIENTE,COD_PAGTO,DATA_PEDIDO,DATA_ENTREGA,SITUACAO)
VALUES
	(1, 2, 1, '2018-10-13', '2018-10-29', 'A')
 INSERT INTO PED_VENDAS
	(COD_EMPRESA,ID_CLIENTE,COD_PAGTO,DATA_PEDIDO,DATA_ENTREGA,SITUACAO)
VALUES
	(1, 1, 2, '2018-11-13', '2018-11-29', 'A')
 INSERT INTO PED_VENDAS
	(COD_EMPRESA,ID_CLIENTE,COD_PAGTO,DATA_PEDIDO,DATA_ENTREGA,SITUACAO)
VALUES
	(1, 2, 2, '2018-12-13', '2018-12-29', 'A')

SELECT *
FROM PED_VENDAS
SELECT *
FROM PARAMETROS


--CARGA DETALHES DE PEDIDOS
 INSERT INTO PED_VENDAS_ITENS
VALUES
	(1, 1, 1, 1, 35, 2500),
	(1, 1, 2, 2, 40, 2500),
	(1, 2, 1, 1, 50, 2500),
	(1, 2, 2, 2, 35, 2500),
	(1, 3, 1, 1, 50, 2500),
	(1, 3, 2, 2, 35, 2500),
	(1, 4, 1, 1, 50, 2500),
	(1, 4, 2, 2, 35, 2500),
	(1, 5, 1, 1, 50, 2500),
	(1, 5, 2, 2, 35, 2500),
	(1, 6, 1, 1, 50, 2500),
	(1, 6, 2, 2, 35, 2500),
	(1, 7, 1, 1, 50, 2500),
	(1, 7, 2, 2, 35, 2500),
	(1, 8, 1, 1, 70, 2500),
	(1, 8, 2, 2, 70, 2500),
	(1, 9, 1, 1, 50, 2500),
	(1, 9, 2, 2, 35, 2500),
	(1, 10, 1, 1, 50, 2500),
	(1, 10, 2, 2, 35, 2500),
	(1, 11, 1, 1, 100, 2500),
	(1, 11, 2, 2, 100, 2500),
	(1, 12, 1, 1, 50, 2500),
	(1, 12, 2, 2, 35, 2500)

SELECT *
FROM PED_VENDAS
SELECT *
FROM PED_VENDAS_ITENS

-- ATUALIZAÇÃO DA COLUNA TOTAL_PED DA TABELA PED_VENDAS A PARTIR DA TAB_VENDA_ITENS
   WITH PED_ITENS (COD_EMPRESA, NUM_PEDIDO, TOTAL) AS
   (
	   SELECT A.COD_EMPRESA, A.NUM_PEDIDO, SUM(A.QTD * A.VAL_UNIT) TOTAL
FROM PED_VENDAS_ITENS A
GROUP BY A.COD_EMPRESA, A.NUM_PEDIDO
   )

   UPDATE PED_VENDAS SET TOTAL_PED = B.TOTAL 
   FROM PED_VENDAS A
	INNER JOIN PED_ITENS B
	ON A.NUM_PEDIDO = B.NUM_PEDIDO
		AND A.COD_EMPRESA = B.COD_EMPRESA

SELECT *
FROM PED_VENDAS

-- SALÁRIOS
INSERT INTO SALARIO
VALUES
	(1, 1, 7650),
	(1, 2, 2650),
	(1, 3, 2550),
	(1, 4, 1550),
	(1, 5, 4550),
	(1, 6, 2850),
	(1, 7, 1850),
	(1, 8, 1560),
	(1, 9, 3899),
	(1, 10, 2345),
	(1, 11, 3100),
	(1, 12, 4500)

SELECT *
FROM SALARIO					  

--CARGA PARAMETROS INSS
 INSERT INTO PARAM_INSS
VALUES
	('2018-01-01', '2018-12-31', 0, 1659.38, 8),
	('2018-01-01', '2018-12-31', 1659.39, 2765.66, 9),
	('2018-01-01', '2018-12-31', 2765.67, 5531.31, 11),
	('2018-01-01', '2018-12-31', 5531.32, 999999, 0)

SELECT *
FROM SALARIO

-- PARÂMETROS DO IRPF
 INSERT INTO PARAM_IRRF
VALUES
	('2018-01-01', '2018-12-31', 0, 1903.98, 0, 0),
	('2018-01-01', '2018-12-31', 1903.99, 2826.65, 7.5, 142.80),
	('2018-01-01', '2018-12-31', 2826.66, 3751.05, 15, 354.80),
	('2018-01-01', '2018-12-31', 3751.06, 4664.68, 22.5, 636.13),
	('2018-01-01', '2018-12-31', 4664.68, 999999, 27.5, 869.36)

SELECT *
FROM PARAM_IRRF