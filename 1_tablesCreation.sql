-- Cria��o de DB
CREATE DATABASE TSQL_ERPPROJECT
GO

USE TSQL_ERPPROJECT
GO

-- 1. Cria��o de tabelas sem depend�ncia

-- EMPRESA
CREATE TABLE EMPRESA
(
COD_EMPRESA INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
NOME_EMPRESA VARCHAR(50),
FANTASIA VARCHAR(20)
);

-- UNIDADE FEDERAL
CREATE TABLE UF
(
COD_UF VARCHAR(2) NOT NULL PRIMARY KEY,
NOME_UF VARCHAR(30) NOT NULL
);


-- CIDADES 
CREATE TABLE CIDADES
(
COD_CIDADE VARCHAR(7) NOT NULL PRIMARY KEY,
COD_UF VARCHAR(2) NOT NULL,
NOME_MUN VARCHAR(50) NOT NULL,
CONSTRAINT FK_CID1 FOREIGN KEY (COD_UF) REFERENCES UF(COD_UF) 
);


-- CLIENTES 
CREATE TABLE CLIENTES
(
COD_EMPRESA INT NOT NULL,
ID_CLIENTE INT IDENTITY(1,1) NOT NULL,
RAZAO_CLIENTE VARCHAR(100) NOT NULL,
FANTASIA VARCHAR(15) NOT NULL,
ENDERECO VARCHAR(50) NOT NULL,
NRO VARCHAR(10) NOT NULL,
BAIRRO VARCHAR(20) NOT NULL,
COD_CIDADE VARCHAR(7),
CEP VARCHAR(8),
CNPJ_CPF VARCHAR (15),
TIPO_CLIENTE NCHAR(1) CONSTRAINT CK_TC1 CHECK (TIPO_CLIENTE IN('F','J')),
DATA_CADASTRO DATETIME NOT NULL,
COD_PAGTO INT,
CONSTRAINT PK_CLI1 PRIMARY KEY (COD_EMPRESA, ID_CLIENTE),
CONSTRAINT FK_CLI1 FOREIGN KEY (COD_CIDADE) REFERENCES CIDADES(COD_CIDADE),
CONSTRAINT FK_CLI2 FOREIGN KEY (COD_EMPRESA) REFERENCES EMPRESA(COD_EMPRESA)
);

-- FORNCEDORES 
CREATE TABLE FORNECEDORES
(
COD_EMPRESA INT NOT NULL,
ID_FOR INT IDENTITY(1,1) NOT NULL,
RAZAO_FORNEC VARCHAR(100) NOT NULL,
FANTASIA VARCHAR(15) NOT NULL,
ENDERECO VARCHAR(50) NOT NULL,
NRO VARCHAR(10) NOT NULL,
BAIRRO VARCHAR(20) NOT NULL,
COD_CIDADE VARCHAR(7),
CEP VARCHAR(8),
CNPJ_CPF VARCHAR (15),
TIPO_FORNEC NCHAR(1) CONSTRAINT CK_TF1 CHECK (TIPO_FORNEC IN ('F','J')),
DATA_CADASTRO DATETIME NOT NULL,
COD_PAGTO INT,
CONSTRAINT PK_FOR1 PRIMARY KEY (COD_EMPRESA, ID_FOR),
CONSTRAINT FK_FOR1 FOREIGN KEY (COD_CIDADE) REFERENCES CIDADES(COD_CIDADE),
CONSTRAINT FK_FOR2 FOREIGN KEY (COD_EMPRESA) REFERENCES EMPRESA(COD_EMPRESA)
);

-- TIPO DE MATERIAL
CREATE TABLE TIPO_MAT
(
COD_EMPRESA INT NOT NULL,
COD_TIP_MAT INT NOT NULL,
DESC_TIP_MAT VARCHAR(20) NOT NULL,
CONSTRAINT PK_TIP_M1 PRIMARY KEY (COD_EMPRESA, COD_TIP_MAT),
CONSTRAINT FK_TIP_M1 FOREIGN KEY (COD_EMPRESA) REFERENCES EMPRESA(COD_EMPRESA)
);

-- MATERIAL
CREATE TABLE MATERIAL
(
COD_EMPRESA INT NOT NULL,
COD_MAT INT NOT NULL,
DESCRICAO VARCHAR(50) NOT NULL,
PRECO_UNIT DECIMAL(10, 2) NOT NULL,
COD_TIP_MAT INT NOT NULL,
ID_FOR INT,
CONSTRAINT PK_MAT1 PRIMARY KEY (COD_EMPRESA, COD_MAT),
CONSTRAINT FK_MAT1 FOREIGN KEY (COD_EMPRESA, COD_TIP_MAT) REFERENCES TIPO_MAT(COD_EMPRESA, COD_TIP_MAT)
);


-- INDEX PARA TABELA MATERIAL
CREATE INDEX IX_MAT ON MATERIAL(COD_EMPRESA, COD_TIP_MAT);

-- PRODUCAO
CREATE TABLE ORDEM_PROD
(
COD_EMPRESA INT NOT NULL,
ID_ORDEM INT IDENTITY(1,1) NOT NULL,
COD_MAT_PROD INT NOT NULL,
QTD_PLAN DECIMAL (10,2) NOT NULL,
QTD_PROD DECIMAL (10,2) NOT NULL,
DATA_INI DATE,
DATA_FIM DATE,
SITUACAO CHAR(1),
CONSTRAINT PK_OP1 PRIMARY KEY (COD_EMPRESA, ID_ORDEM),
CONSTRAINT FK_OP1 FOREIGN KEY (COD_EMPRESA, COD_MAT_PROD) REFERENCES MATERIAL (COD_EMPRESA, COD_MAT)
);