﻿-- Criação de DB
CREATE DATABASE TSQL_ERPPROJECT
GO

USE TSQL_ERPPROJECT
GO

-- 1. Criação de tabelas sem dependência

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
    -- A (ABERTA), P (PLANEJADA) E F (FECHADA)
    CONSTRAINT PK_OP1 PRIMARY KEY (COD_EMPRESA, ID_ORDEM),
    CONSTRAINT FK_OP1 FOREIGN KEY (COD_EMPRESA, COD_MAT_PROD) REFERENCES MATERIAL (COD_EMPRESA, COD_MAT)
);

-- APONTAMENTOS DE PRODUÇÃO
CREATE TABLE APONTAMENTOS
(
    COD_EMPRESA INT NOT NULL,
    ID_APON INT IDENTITY(1, 1) NOT NULL,
    ID_ORDEM INT NOT NULL,
    COD_MAT_PROD INT,
    QTD_APON DECIMAL (10, 2),
    DATA_APON DATETIME NOT NULL,
    CONSTRAINT PK_APON1 PRIMARY KEY (COD_EMPRESA, ID_APON),
    CONSTRAINT FK_APON1 FOREIGN KEY (COD_EMPRESA, COD_MAT_PROD) REFERENCES MATERIAL(COD_EMPRESA, COD_MAT),
    CONSTRAINT FK_APON2 FOREIGN KEY (COD_EMPRESA, ID_ORDEM) REFERENCES ORDEM_PROD(COD_EMPRESA, ID_ORDEM)
);

-- FICHA TÉCNICA
CREATE TABLE FICHA_TECNICA
(
    COD_EMPRESA INT NOT NULL,
    ID_REF INT IDENTITY NOT NULL PRIMARY KEY,
    COD_MAT_PROD INT NOT NULL,
    COD_MAT_NECES INT NOT NULL,
    QTD_NECES DECIMAL (10, 2) NOT NULL,
    CONSTRAINT FK_FIC1 FOREIGN KEY (COD_EMPRESA, COD_MAT_PROD) REFERENCES MATERIAL (COD_EMPRESA, COD_MAT),
    CONSTRAINT FK_FIC2 FOREIGN KEY (COD_EMPRESA, COD_MAT_NECES) REFERENCES MATERIAL(COD_EMPRESA, COD_MAT)
);

-- CONSUMO
CREATE TABLE CONSUMO
(
    COD_EMPRESA INT NOT NULL,
    ID_APON INT NOT NULL,
    COD_MAT_NECES INT NOT NULL,
    QTD_CONSUMIDA DECIMAL (10, 2) NOT NULL,
    LOTE VARCHAR(20) NOT NULL,
    CONSTRAINT FK_CONS1 FOREIGN KEY (COD_EMPRESA, COD_MAT_NECES) REFERENCES MATERIAL(COD_EMPRESA, COD_MAT),
    CONSTRAINT FK_CONS2 FOREIGN KEY (COD_EMPRESA, ID_APON) REFERENCES APONTAMENTOS (COD_EMPRESA, ID_APON)
);

-- ESTOQUE
CREATE TABLE ESTOQUE
(
    COD_EMPRESA INT NOT NULL,
    COD_MAT INT NOT NULL,
    QTD_SALDO DECIMAL (10, 2) NOT NULL,
    CONSTRAINT PK_EST1 PRIMARY KEY (COD_EMPRESA, COD_MAT),
    CONSTRAINT FK_EST1 FOREIGN KEY (COD_EMPRESA, COD_MAT) REFERENCES MATERIAL(COD_EMPRESA, COD_MAT)
);

-- ESTOQUE LOTE
CREATE TABLE ESTOQUE_LOTE
(
    COD_EMPRESA INT NOT NULL,
    COD_MAT INT NOT NULL,
    LOTE VARCHAR(20) NOT NULL,
    QTD_LOTE DECIMAL (10, 2) NOT NULL,
    CONSTRAINT PK_ESTL1 PRIMARY KEY (COD_EMPRESA, COD_MAT, LOTE),
    CONSTRAINT FK_ESTL1 FOREIGN KEY (COD_EMPRESA, COD_MAT) REFERENCES MATERIAL (COD_EMPRESA, COD_MAT)
);

-- ESTOQUE_MOV
CREATE TABLE ESTOQUE_MOV
(
    COD_EMPRESA INT NOT NULL,
    ID_MOV INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
    TIP_MOV VARCHAR(1),
    -- S (SAIDA) E (ENTRADA)
    COD_MAT INT NOT NULL,
    LOTE VARCHAR(20) NOT NULL,
    QTD DECIMAL (10, 2) NOT NULL,
    DATA_MOV DATE NOT NULL,
    DATA_HORA DATETIME NOT NULL,
    CONSTRAINT FK_ESTM1 FOREIGN KEY (COD_EMPRESA, COD_MAT) REFERENCES MATERIAL (COD_EMPRESA, COD_MAT)
);

-- PED_COMPRAS
CREATE TABLE PED_COMPRAS
(
    COD_EMPRESA INT NOT NULL,
    NUM_PEDIDO INT NOT NULL,
    ID_FOR INT NOT NULL,
    COD_PAGTO INT NOT NULL,
    DATA_PEDIDO DATE NOT NULL,
    DATA_ENTREGA DATE NOT NULL,
    SITUACAO NCHAR(1) NOT NULL,
    TOTAL_PED DECIMAL (10, 2),
    CONSTRAINT PK_PEDC1 PRIMARY KEY  (COD_EMPRESA, NUM_PEDIDO),
    CONSTRAINT FK_PEDC1 FOREIGN KEY (COD_EMPRESA, ID_FOR) REFERENCES FORNECEDORES(COD_EMPRESA, ID_FOR)
);

-- PEDIDO COMPRAS
CREATE TABLE PED_COMPRAS_ITENS
(
    COD_EMPRESA INT NOT NULL,
    NUM_PEDIDO INT NOT NULL,
    SEQ_MAT INT NOT NULL,
    COD_MAT INT NOT NULL,
    QTD INT NOT NULL,
    VAL_UNIT DECIMAL (10, 2) NOT NULL,
    CONSTRAINT PK_PEDCIT1 PRIMARY KEY (COD_EMPRESA, NUM_PEDIDO, SEQ_MAT),
    CONSTRAINT FK_PEDIT1 FOREIGN KEY (COD_EMPRESA, NUM_PEDIDO) REFERENCES PED_COMPRAS(COD_EMPRESA, NUM_PEDIDO),
    CONSTRAINT FK_PEDIT2 FOREIGN KEY (COD_EMPRESA, COD_MAT) REFERENCES MATERIAL(COD_EMPRESA, COD_MAT)
);