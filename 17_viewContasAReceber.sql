﻿/* VIEW CONTAS A RECEBER */

USE tsql_erpProject
GO

CREATE VIEW V_CONTAS_RECEBER
AS
	SELECT A.COD_EMPRESA,
		A.ID_DOC,
		A.ID_CLIENTE,
		B.RAZAO_CLIENTE,
		A.PARC,
		A.DATA_VENC,
		A.DATA_PAGTO,
		A.VALOR,
		CASE WHEN A.DATA_PAGTO IS NULL THEN 'ABERTO' 
		ELSE 'PAGO' END SITUACAO,
		CASE WHEN A.DATA_VENC > GETDATE() THEN 'NORMAL' 
			 WHEN A.DATA_PAGTO>A.DATA_VENC   THEN 'PAGTO EM COM ATRASO'
			ELSE 'VENCIDO' 
		END MSG,
		CASE WHEN A.DATA_VENC=A.DATA_PAGTO THEN 0
			 WHEN A.DATA_PAGTO>A.DATA_VENC THEN CAST(CAST(A.DATA_PAGTO AS DATETIME)-CAST(A.DATA_VENC AS DATETIME) AS INT )
			 ELSE CAST(GETDATE()-CAST(A.DATA_VENC AS DATETIME) AS INT ) 
		END AS DIAS_ATRASO
	FROM CONTAS_RECEBER A
		INNER JOIN CLIENTES B
		ON A.COD_EMPRESA=B.COD_EMPRESA
			AND A.ID_CLIENTE=B.ID_CLIENTE

-- Teste view
SELECT *
FROM V_CONTAS_RECEBER