﻿/* PROCEDURE PARA GERAR ORDENS DE PRODUÇÃO COM BASE NO PEDIDO DE VENDAS */
USE tsql_erpProject
GO

CREATE PROCEDURE PROC_PLAN_ORDEM
	(@COD_EMPRESA INT,
	@MES VARCHAR(2),
	@ANO VARCHAR(4))
AS
BEGIN
	/* Instrução que informa em tela a quantidade de linhas afetadas
	pela transação */
	SET NOCOUNT ON
	DECLARE @ERRO_INTERNO INT;

	BEGIN TRANSACTION

	-- Verifica se existem pedidos abertos para a empresa no mês e ano selecionado
	SELECT A.COD_EMPRESA,
		A.NUM_PEDIDO
	FROM PED_VENDAS A
	WHERE A.COD_EMPRESA = @COD_EMPRESA
		AND A.SITUACAO = 'A'
		AND MONTH(A.DATA_ENTREGA) = @MES
		AND YEAR(A.DATA_ENTREGA) = @ANO

	-- Caso não tenha pedido, lança erro
	IF @@ROWCOUNT = 0
		BEGIN
		SET @ERRO_INTERNO = 1;
	END
	-- Caso tenha pedido executa o procedimento abaixo
	ELSE 
		BEGIN
		INSERT INTO ORDEM_PROD
		OUTPUT
		'ORDEM PLANEJADA'
		MSG,
		INSERTED.COD_EMPRESA,
		INSERTED.ID_ORDEM,
		INSERTED.COD_MAT_PROD
		SELECT A.COD_EMPRESA,
			B.COD_MAT,
			SUM(B.QTD) AS QTD_PLAN,
			0 AS QTD_PROD,
			@ANO + '-' + @MES + '-01' AS DATA_INI,
			EOMONTH(@ANO + '-' + @MES + '-01') AS DATA_FIM,
			'A'
		FROM PED_VENDAS A
			INNER JOIN PED_VENDAS_ITENS B ON A.NUM_PEDIDO = B.NUM_PEDIDO
				AND A.COD_EMPRESA = B.COD_EMPRESA
		WHERE A.COD_EMPRESA  = @COD_EMPRESA
			AND MONTH(A.DATA_ENTREGA) = @MES
			AND YEAR(A.DATA_ENTREGA) = @ANO
		GROUP BY A.COD_EMPRESA, 
			B.COD_MAT

		PRINT 'INSERT ORDEM PROD REALIZADO';

		-- Atualizar status do pedido
		UPDATE PED_VENDAS 
			SET SITUACAO = 'P'
			OUTPUT 'PEDIDO PLANEJADO' MSG, INSERTED.NUM_PEDIDO, DELETED.SITUACAO AS DE, INSERTED.SITUACAO AS PARA
			WHERE COD_EMPRESA = @COD_EMPRESA
			AND SITUACAO = 'A'
			AND MONTH(DATA_ENTREGA) = @MES
			AND YEAR(DATA_ENTREGA) = @ANO;

		PRINT 'SITUAÇÃO DE PEDIDOS ATUALIZADA';
	END

	-- Validações finais
	IF @ERRO_INTERNO = 1
			BEGIN
		ROLLBACK
		RAISERROR('NÃO EXISTEM MATERIAIS PARA PLANEJAMENTO',
				10, -- Severity
				1 -- State
				);
		PRINT 'OPERAÇÃO CANCELADA COM ROLLBACK';
	END
		ELSE IF @@ERROR != 0
			BEGIN
		ROLLBACK
		PRINT 'OPERACAO CANCELADA'
		PRINT @@ERROR
	END
		ELSE
			BEGIN
		COMMIT
		PRINT 'OPERAÇÃO CONCLUÍDA COM SUCESSO'
	END
END

-- Execução da procedure
EXEC PROC_PLAN_ORDEM 1, 2, 2018;

SELECT *
FROM PED_VENDAS
SELECT *
FROM PED_VENDAS_ITENS
SELECT *
FROM ORDEM_PROD