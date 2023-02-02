﻿/* PROCEDURE PARA GERAR NOTA FISCAL 
- Origem: a depender da movimentação pode ser as tabelas PED_VENDAS e PED_VENDAS_ITENS
ou as tabelas PED_COMPRAS e PED_COMPRAS_ITENS
- Destino: NOTA_FISCAL e NOTA_FISCAL_ITENS
*/
USE tsql_erpProject
GO

-- Ajuste em NOTA_FISCAL_ITENS
ALTER TABLE NOTA_FISCAL_ITENS ALTER COLUMN QTD DECIMAL(10,2)

CREATE  PROCEDURE PROC_GERA_NF
	(@COD_EMPRESA INT,
	@TIP_MOV AS CHAR(1),-- E (ENTRADA) S (SAíDA)
	@DOCTO INT,
	--PEDIDO DE VENDA SAIDA- PEDIDO COMPPRAS -ENTRADA
	@CFOP VARCHAR(5),
	@DATA_EMIS DATE,
	@DATA_ENTREGA DATE)
AS
BEGIN
	-- Valor do output
	DECLARE @NOTA_TB TABLE
(
		NF INT
)
	-- Declaração de variáveis
	DECLARE @DOCT INT,
        @NUM_NF INT,
		@ID INT,
		@COD_PAGTO INT,
		@NUM_PEDIDO INT,
		@SEQ_MAT INT,
		@COD_MAT INT,
		@QTD DECIMAL(10,2),
		@VAL_UNIT DECIMAL (10,2),
		@SUB_TOT_NFE DECIMAL(10,2),
		@TOTAL_NFE DECIMAL(10,2),
		@ERRO_INTERNO INT

	SET @SUB_TOT_NFE = 0
	SET @TOTAL_NFE = 0

	-- Início da transaction
	BEGIN TRANSACTION

	-- Início do BEGIN TRY
	BEGIN TRY

		IF (@DATA_EMIS > GETDATE() OR @DATA_ENTREGA > GETDATE())
		BEGIN
		PRINT 'Não é permitido realizar lançamentos futuros.'
		SET @ERRO_INTERNO = 1
	END
		ELSE IF @TIP_MOV != 'S' AND @TIP_MOV != 'E'
		BEGIN
		PRINT 'Operação não permitida cancelada.'
		SET @ERRO_INTERNO=1
	END
		ELSE IF @TIP_MOV=  'S' AND (SELECT COUNT(*)
		FROM PED_VENDAS A
		WHERE COD_EMPRESA=@COD_EMPRESA AND A.NUM_PEDIDO=@DOCTO
			AND A.SITUACAO != 'F') = 0
		BEGIN
		PRINT 'Não existem pedidos de venda disponíveis para saída'
		SET @ERRO_INTERNO = 1
	END 
		ELSE IF @TIP_MOV = 'E' AND (SELECT COUNT(*)
		FROM PED_COMPRAS A
		WHERE COD_EMPRESA=@COD_EMPRESA AND A.NUM_PEDIDO = @DOCTO
			AND A.SITUACAO != 'F') = 0
		BEGIN
		PRINT 'Não existem pedidos de compra disponíveis para saída'
		SET @ERRO_INTERNO = 1
	END 

-- Início nota fiscal de SAÍDA
		ELSE IF @TIP_MOV = 'S' 
		BEGIN
		-- Abertura de cursor de saída
		DECLARE NOTA_FISCAL CURSOR FOR 

		SELECT A.COD_EMPRESA, A.NUM_PEDIDO, A.ID_CLIENTE, A.COD_PAGTO
		FROM PED_VENDAS A
		WHERE A.COD_EMPRESA=@COD_EMPRESA
			AND A.NUM_PEDIDO = @DOCTO
			AND A.SITUACAO != 'F'

		-- Abre cursor
		OPEN NOTA_FISCAL
		FETCH NEXT FROM NOTA_FISCAL
		INTO @COD_EMPRESA,@NUM_PEDIDO,@ID,@COD_PAGTO

		-- Inicia laço while
		WHILE @@FETCH_STATUS = 0
		BEGIN

			-- Captura o número do pedido
			PRINT 'UPDATE DE PARAMETROS'
			UPDATE PARAMETROS SET VALOR = VALOR + 1
		OUTPUT INSERTED.VALOR INTO @NOTA_TB
		WHERE COD_EMPRESA = @COD_EMPRESA
				AND PARAM='NOTA_FISCAL';

			-- Atribui o número da variável à NF 
			SELECT @NUM_NF=NF
			FROM @NOTA_TB

			-- Insere o cabeçalho da NF 
			INSERT INTO NOTA_FISCAL
			OUTPUT
			INSERTED.NUM_NF
			VALUES
				(@COD_EMPRESA, @NUM_NF, @TIP_MOV, @CFOP, @ID, @COD_PAGTO, @DATA_EMIS, @DATA_ENTREGA, 0, 'N', 'N')
			PRINT @@ERROR

			-- Projeta o cabeçalho
			SELECT @COD_EMPRESA COD_EMPRESA, @NUM_NF NUM_NF, @TIP_MOV TIP_MOV, @CFOP CFOP, @ID ID, @COD_PAGTO COD_PAGTO,
				@DATA_EMIS DAT_EMIS, @DATA_ENTREGA DATA_ENTREG

			-- Início do cursor de detalhes de itens
			DECLARE NF_ITENS CURSOR FOR 
	SELECT A.COD_EMPRESA, A.SEQ_MAT, A.COD_MAT, A.QTD, A.VAL_UNIT
			FROM PED_VENDAS_ITENS A
			WHERE COD_EMPRESA=@COD_EMPRESA
				AND A.NUM_PEDIDO=@DOCTO
			ORDER BY A.SEQ_MAT

			-- Abre o cursor
			OPEN NF_ITENS
			FETCH NEXT FROM NF_ITENS
		INTO @COD_EMPRESA,@SEQ_MAT,@COD_MAT,@QTD,@VAL_UNIT
			WHILE @@FETCH_STATUS = 0
			BEGIN
				INSERT INTO NOTA_FISCAL_ITENS
				VALUES
					(@COD_EMPRESA, @NUM_NF, @SEQ_MAT, @COD_MAT, @QTD, @VAL_UNIT, @DOCTO);
				PRINT @@ERROR
				-- Projeta valores inseridos
				SELECT @COD_EMPRESA COD_EMPRESA, @NUM_NF NUM_NF, @SEQ_MAT SEQ , @COD_MAT COD_MAT, @QTD QTD ,
					@VAL_UNIT VAL_UNIT, @DOCTO PED_ORIG

				-- Atribui valores totais
				SET @SUB_TOT_NFE = @QTD*@VAL_UNIT;
				SET @TOTAL_NFE = @TOTAL_NFE+@SUB_TOT_NFE;

				FETCH NEXT FROM NF_ITENS
		INTO @COD_EMPRESA,@SEQ_MAT,@COD_MAT,@QTD,@VAL_UNIT
			END

			-- Finaliza e desaloca cursor interno
			CLOSE NF_ITENS;
			DEALLOCATE NF_ITENS;


			-- Atualiza o total da NF
			UPDATE NOTA_FISCAL SET TOTAL_NF=@TOTAL_NFE WHERE COD_EMPRESA=@COD_EMPRESA AND NUM_NF = @NUM_NF;

			-- Atualiza o status da NF para fechado no PED_VENDAS
			UPDATE PED_VENDAS  SET SITUACAO = 'F' WHERE COD_EMPRESA=@COD_EMPRESA AND NUM_PEDIDO=@DOCTO;

			FETCH NEXT FROM NOTA_FISCAL
		INTO @COD_EMPRESA,@NUM_PEDIDO,@ID,@COD_PAGTO
		END

		-- Finaliza e desaloca cursor externo
		CLOSE NOTA_FISCAL;
		DEALLOCATE NOTA_FISCAL;
	-- Finaliza o if de saída
	END

  -- Início nota fiscal de ENTRADA
  ELSE IF @TIP_MOV = 'E' 
		BEGIN

		DECLARE NOTA_FISCAL CURSOR FOR 

		SELECT @COD_EMPRESA, A.NUM_PEDIDO, A.ID_FOR, A.COD_PAGTO
		FROM PED_COMPRAS A
		WHERE COD_EMPRESA=@COD_EMPRESA
			AND A.NUM_PEDIDO = @DOCTO
			AND A.SITUACAO != 'F'

		-- Abre o cursor
		OPEN NOTA_FISCAL
		FETCH NEXT FROM NOTA_FISCAL
		INTO @COD_EMPRESA,@NUM_PEDIDO,@ID,@COD_PAGTO
		WHILE @@FETCH_STATUS = 0
			BEGIN

			-- Captura o número do pedido
			PRINT 'UPDATE DE PARAMETROS'
			UPDATE PARAMETROS SET VALOR=VALOR+1
		OUTPUT INSERTED.VALOR INTO @NOTA_TB
		WHERE COD_EMPRESA = @COD_EMPRESA
				AND PARAM='NOTA_FISCAL';

			-- Atribui número da NF 
			SELECT @NUM_NF=NF
			FROM @NOTA_TB

			-- Insere os registro no cabeçalho 
			INSERT INTO NOTA_FISCAL
			VALUES
				(@COD_EMPRESA, @NUM_NF, @TIP_MOV, @CFOP, @ID, @COD_PAGTO, @DATA_EMIS, @DATA_ENTREGA, 0, 'N', 'N')
			PRINT @@ERROR

			-- Projeta valores do cabeçalho
			SELECT @COD_EMPRESA COD_EMPRESA, @NUM_NF NUM_NF, @TIP_MOV TIP_MOV, @CFOP CFOP, @ID ID, @COD_PAGTO COD_PAGTO,
				@DATA_EMIS DAT_EMIS, @DATA_ENTREGA DATA_ENTREG

			-- Inicia cursor de detalhes
			DECLARE NF_ITENS CURSOR FOR 

	SELECT @COD_EMPRESA COD_EMPRESA, A.SEQ_MAT, A.COD_MAT, A.QTD, A.VAL_UNIT
			FROM PED_COMPRAS_ITENS A
			WHERE COD_EMPRESA=@COD_EMPRESA
				AND A.NUM_PEDIDO=@DOCTO
			ORDER BY A.SEQ_MAT

			-- Abre o cursor
			OPEN NF_ITENS
			FETCH NEXT FROM NF_ITENS
		INTO @COD_EMPRESA,@SEQ_MAT,@COD_MAT,@QTD,@VAL_UNIT

			-- Inicia o laço while
			WHILE @@FETCH_STATUS = 0
			BEGIN
				INSERT INTO NOTA_FISCAL_ITENS
				VALUES
					(@COD_EMPRESA, @NUM_NF, @SEQ_MAT, @COD_MAT, @QTD, @VAL_UNIT, @DOCTO);
				PRINT @@ERROR
				--APRESENTANDO VALORES DO ITENS INSERIDOS
				SELECT @COD_EMPRESA COD_EMPRESA , @NUM_NF NUM_NF, @SEQ_MAT SEQ , @COD_MAT COD_MAT, @QTD QTD , @VAL_UNIT VAL_UNIT, @DOCTO PED_ORIG
				SET @SUB_TOT_NFE=@QTD*@VAL_UNIT;
				SET @TOTAL_NFE=@TOTAL_NFE+@SUB_TOT_NFE;
				--SELECT @TOTAL_NFE
				FETCH NEXT FROM NF_ITENS
		INTO @COD_EMPRESA,@SEQ_MAT,@COD_MAT,@QTD,@VAL_UNIT

			END

			-- Finaliza e desaloca cursor interno
			CLOSE NF_ITENS;
			DEALLOCATE NF_ITENS;

			-- Atualiza o total da NF
			UPDATE NOTA_FISCAL SET TOTAL_NF=@TOTAL_NFE WHERE COD_EMPRESA=@COD_EMPRESA AND NUM_NF=@NUM_NF;

			-- Atualiza o status da PED_COMPRAS para fechado
			UPDATE PED_COMPRAS  SET SITUACAO='F' WHERE COD_EMPRESA=@COD_EMPRESA AND NUM_PEDIDO=@DOCTO;

			FETCH NEXT FROM NOTA_FISCAL
		INTO @COD_EMPRESA,@NUM_PEDIDO,@ID,@COD_PAGTO
		END

		-- Finaliza e desaloca cursor externo.
		CLOSE NOTA_FISCAL;
		DEALLOCATE NOTA_FISCAL;

	-- Fim do if da NF de ENTRADA
	END

 -- Realiza últimas validações
	IF @@ERROR <>0
	 BEGIN
		ROLLBACK TRANSACTION
		PRINT 'Operação cancelada.'
	END
	ELSE IF @ERRO_INTERNO=1
		BEGIN
		ROLLBACK TRANSACTION
		PRINT 'Operação cancelada.'
	END
	ELSE
		BEGIN
		COMMIT TRANSACTION
		PRINT 'Operação finalizada com sucesso'
	END
END TRY
BEGIN CATCH
SELECT
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_SEVERITY() AS ErrorSeverity ,
		ERROR_STATE() AS ErrorState,
		ERROR_PROCEDURE() AS ErrorProcedure ,
		ERROR_LINE() AS ErrorLine,
		ERROR_MESSAGE() AS ErrorMessage;  

		-- Finaliza os cursores se estiverem abertos quando da ocorrência do erro
		IF (SELECT CURSOR_STATUS('global', 'NOTA_FISCAL')) = 1 
		BEGIN
		CLOSE NOTA_FISCAL
		DEALLOCATE NOTA_FISCAL
	END
		IF (SELECT CURSOR_STATUS('global', 'NF_ITENS')) = 1 
		BEGIN
		CLOSE NF_ITENS
		DEALLOCATE NF_ITENS
	END	
		
		SET XACT_ABORT ON;
		IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  
	 
	END CATCH

-- Finaliza a procedure
END


/* Realização de testes
Ordem de parâmetros @COD_EMPRESA, @TIP_MOV, @DOCTO, @CFOP, @DATA_EMIS, @DATA_ENTREGA
*/
-- Forçando erro para validação
EXEC PROC_GERA_NF 1,'X',1,'1.101','2018-01-30','2018-01-30'

-- Execuções corretas
EXEC PROC_GERA_NF 1,'E',1,'1.101','2018-01-30','2018-01-30'
EXEC PROC_GERA_NF 1,'E',2,'1.101','2018-01-30','2018-01-30'
EXEC PROC_GERA_NF 1,'E',3,'1.101','2018-01-30','2018-01-30'
EXEC PROC_GERA_NF 1,'E',4,'1.101','2018-01-30','2018-01-30'

EXEC PROC_GERA_NF 1,'S',1,'5.101','2018-01-30','2018-01-30'
EXEC PROC_GERA_NF 1,'S',2,'5.101','2018-02-28','2018-02-28'
EXEC PROC_GERA_NF 1,'S',3,'5.101','2018-03-30','2018-03-30'
EXEC PROC_GERA_NF 1,'S',4,'5.101','2018-04-30','2018-04-30'

-- Validações
SELECT *
FROM NOTA_FISCAL_ITENS
SELECT *
FROM NOTA_FISCAL