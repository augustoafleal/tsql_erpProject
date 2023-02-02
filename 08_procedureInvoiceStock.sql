/* PROCEDURE DE INTEGRAÇÃO DE NOTA FISCAL COM ESTOQUE
1. Reutiliza a PROC_INTEGR_NF_ESTOQUE
2. Utiliza as tabelas de origem NOTA_FISCAL e NOTA_FISCAL_ITENS
3. Atualiza o status da NOTA FISCAL como INTEGRADA_SUP = S
*/
USE tsql_erpProject
GO

CREATE  PROCEDURE PROC_INTEGR_NF_ESTOQUE
	(@COD_EMPRESA INT,
	@NUM_NF INT,
	@DATA_MOVTO DATE)
AS
BEGIN
	SET NOCOUNT ON

	-- Declaração de variáveis
	DECLARE @TIP_MOV VARCHAR(1), --E ENTRADA, S-SAIDA
        @COD_MAT  VARCHAR(50), 
        @LOTE     VARCHAR(15), 
        @QTD  DECIMAL(10, 2),
		@ERRO_INTERNO INT,
        @TIP_NF CHAR(1),
		@COD_MAT_AUX INT,
		@QTD_LOTE DECIMAL(10,2),
		@QTD_ATEND DECIMAL(10,2),
		@SALDO DECIMAL(10,2),
		@SALDO_AUX DECIMAL(10,2),
		@TESTE CHAR(1),
		@Msg VARCHAR(40)

	-- Atribuição de valores
	SET @QTD_ATEND = 0
	SET @SALDO = 0

	BEGIN TRANSACTION

	-- Estrutura de IF e ELSE
	IF (SELECT COUNT(*)
	FROM NOTA_FISCAL
	WHERE COD_EMPRESA = @COD_EMPRESA AND NUM_NF = @NUM_NF) = 0
	BEGIN
		SET @ERRO_INTERNO = 1;
	END

-- Verifica se a nota fiscal já existe e está integrado
	ELSE IF (SELECT TOP 1
		A.NUM_NF
	FROM NOTA_FISCAL A
	WHERE COD_EMPRESA = @COD_EMPRESA
		AND A.NUM_NF = @NUM_NF
		AND A.INTEGRADA_SUP = 'S') = @NUM_NF
	BEGIN
		SET @ERRO_INTERNO = 2;
	END

-- Valida se operação é de entrada para executar entrada em estoque
	ELSE IF (SELECT COUNT(*)
	FROM NOTA_FISCAL A
	WHERE COD_EMPRESA=@COD_EMPRESA
		AND A.NUM_NF = @NUM_NF
		AND A.TIP_NF = 'E'
		AND A.INTEGRADA_SUP = 'N') = 1
	BEGIN
		PRINT  'Iniciando Operação de Entrada'

		-- Inicia begin try
		BEGIN TRY
		DECLARE INTEGRA_ESTOQUE CURSOR FOR
			SELECT A.TIP_NF,
			B.COD_MAT,
			CONCAT(DATEPART(DAYOFYEAR,GETDATE()),'-',A.NUM_NF) LOTE,
			-- Montagem do nome do lote concatenando dia do ano com número da nota
			B.QTD
		FROM NOTA_FISCAL A
			INNER JOIN NOTA_FISCAL_ITENS B
			ON  A.COD_EMPRESA = B.COD_EMPRESA
				AND A.NUM_NF = B.NUM_NF
		WHERE A.COD_EMPRESA = @COD_EMPRESA
			AND A.NUM_NF = @NUM_NF
			AND A.INTEGRADA_SUP = 'N'

			OPEN INTEGRA_ESTOQUE
			FETCH NEXT FROM INTEGRA_ESTOQUE
			INTO @TIP_MOV, @COD_MAT, @LOTE, @QTD

	WHILE @@FETCH_STATUS = 0 OR @@ERROR != 0
		BEGIN

			-- Executa procedure de estoque com parâmetros obtidos a partir do cursor
			EXEC PROC_GERA_ESTOQUE @COD_EMPRESA,@TIP_MOV, @COD_MAT,@LOTE, @QTD,@DATA_MOVTO

			FETCH NEXT FROM INTEGRA_ESTOQUE
			INTO @TIP_MOV,@COD_MAT,@LOTE,@QTD
		END
	 -- Fecha e desaloca cursor
CLOSE INTEGRA_ESTOQUE
DEALLOCATE INTEGRA_ESTOQUE
END TRY 
    BEGIN CATCH
        SET @ERRO_INTERNO =3;
        print ''
        print 'Ocorreu um erro ao integrar estoque.'
        print 'Mensagem: ' + ERROR_MESSAGE()
        print 'Procedure: ' + ERROR_PROCEDURE()
		
		-- Fecha o cursor caso ele esteja aberto
		IF (SELECT CURSOR_STATUS('global', 'INTEGRA_ESTOQUE')) = 1 
		BEGIN
			CLOSE INTEGRA_ESTOQUE
			DEALLOCATE INTEGRA_ESTOQUE
		END

END CATCH

	-- Finaliza IF que confere se a nota de entrada já foi integrada
	END 

-- Verifica se a operação é de saída para executar a saída do estoque 

	ELSE IF (SELECT COUNT(*)
	FROM NOTA_FISCAL A
	WHERE COD_EMPRESA = @COD_EMPRESA
		AND A.NUM_NF = @NUM_NF
		AND A.TIP_NF = 'S'
		AND A.INTEGRADA_SUP = 'N') = 1
	BEGIN
		PRINT  'Iniciando operação de saída'
		BEGIN TRY
	-- Declara cursor
	DECLARE LE_NFE_VENDA CURSOR FOR
 
   SELECT A.NUM_NF, A.TIP_NF, B.COD_MAT, B.QTD
		FROM NOTA_FISCAL A
			INNER JOIN NOTA_FISCAL_ITENS B
			ON A.COD_EMPRESA = B.COD_EMPRESA
				AND A.NUM_NF = B.NUM_NF
		WHERE A.COD_EMPRESA = @COD_EMPRESA
			AND A.INTEGRADA_SUP = 'N'
			AND A.NUM_NF = @NUM_NF
			AND A.TIP_NF = 'S'
		ORDER BY B.COD_MAT

	-- Faz a abertura do cursor
OPEN LE_NFE_VENDA
FETCH NEXT FROM LE_NFE_VENDA

	-- Insere valores nas varáveis
		INTO @NUM_NF, @TIP_NF, @COD_MAT, @QTD

	-- Inicia laço while
		WHILE @@FETCH_STATUS = 0 
		BEGIN

			-- Se a quantidade em estoque for menor que a quantidade movimentada
			-- OU se for nula, lança erro 4
			IF (SELECT ISNULL(QTD_SALDO,0) QTD_SALDO
				FROM ESTOQUE
				WHERE COD_EMPRESA = @COD_EMPRESA AND COD_MAT = @COD_MAT) < @QTD
				OR
				(SELECT ISNULL(QTD_SALDO,0) QTD_SALDO
				FROM ESTOQUE
				WHERE COD_EMPRESA = @COD_EMPRESA AND COD_MAT = @COD_MAT) IS NULL
		 BEGIN
				SET @ERRO_INTERNO = 4
				GOTO ERRO4
			END

		 ELSE 

		 BEGIN

				-- Apresenta valores para fins de informação
				SELECT @NUM_NF NOTA, @TIP_NF TIP_NF, @COD_MAT COD_MAT, @QTD QTD

				-- Declara cursor para ler estoque com materiais da nota para baixa em estoque
				DECLARE INTEGRA_NFE_VENDA CURSOR FOR

	SELECT C.COD_MAT, C.QTD_LOTE, C.LOTE
				FROM ESTOQUE_LOTE C
				WHERE COD_EMPRESA = @COD_EMPRESA
					AND C.COD_MAT  = @COD_MAT
					AND C.QTD_LOTE > 0
				ORDER BY C.COD_MAT, C.LOTE

				-- Abre o cursor
				OPEN INTEGRA_NFE_VENDA
				FETCH NEXT FROM INTEGRA_NFE_VENDA

-- Insere valor em variáveis
		INTO @COD_MAT,@QTD_LOTE,@LOTE

				-- Atribui valores a variáveis
				SET @SALDO=@QTD;
				SET @SALDO_AUX=@SALDO

				WHILE @@FETCH_STATUS = 0 
			BEGIN

					-- Verifica troca do material
					IF @COD_MAT_AUX != @COD_MAT 
			  BEGIN
						SET @QTD_ATEND=0
						SET @SALDO = @QTD;
					END

					-- Verifica saldo	 
					IF @SALDO <= 0
			  BEGIN
						SET @QTD_ATEND = 0
					END

					-- Verifica quantidade do pedido, saldo do lote e saldo do pedido
					IF  @SALDO_AUX >= @QTD_LOTE
			  BEGIN
						SET  @QTD_ATEND = @QTD_ATEND + @QTD_LOTE
						SET  @SALDO = @SALDO - @QTD
						SET  @SALDO_AUX = @SALDO_AUX - @QTD_LOTE
					END

			  ELSE IF  @SALDO_AUX < @QTD_LOTE
			  BEGIN
						SET  @SALDO = @SALDO - (@QTD - @QTD_LOTE)
						SET  @QTD_ATEND = @QTD_ATEND + @SALDO_AUX
						SET  @SALDO_AUX = @SALDO_AUX - @QTD_ATEND
						PRINT 'PRINTANDO SALDO -> ' + CAST(@SALDO AS VARCHAR)
					END

					-- Primeiro IF -> insere apenas retorno com SALDO >=0 E QTD_ATEND > 0  

					IF @SALDO_AUX >= 0 AND @QTD_ATEND > 0
	      BEGIN
						SELECT @NUM_NF NUM_NF, @TIP_NF TIP_NF, @COD_MAT COD_MAT, @QTD QTD,
							@QTD_LOTE QTD_LOTE, @LOTE LOTE,
							@QTD_ATEND QTD_ATEND, @SALDO_AUX SD_AUX, @TESTE TESTE
						-- Executa procedure de movimentação de estoque 
						EXEC PROC_GERA_ESTOQUE @COD_EMPRESA,@TIP_NF, @COD_MAT,@LOTE, @QTD_ATEND,@DATA_MOVTO

						-- Atribui valor
						SET @COD_MAT_AUX = @COD_MAT;
					END

					-- Lê a próxima linha do cursor
					FETCH NEXT FROM INTEGRA_NFE_VENDA
	    INTO @COD_MAT,@QTD_LOTE,@LOTE
				END

				-- Fecha e desaloca o cursor
				CLOSE INTEGRA_NFE_VENDA
				DEALLOCATE INTEGRA_NFE_VENDA

			-- Fim do else
			END
			-- Lê a próxima linha do cursor
			FETCH NEXT FROM LE_NFE_VENDA
		INTO @NUM_NF,@TIP_NF,@COD_MAT,@QTD


		END
  
  -- Fecha e desaloca o cursor
  CLOSE LE_NFE_VENDA
  DEALLOCATE LE_NFE_VENDA
  END TRY 

    BEGIN CATCH
        SET @ERRO_INTERNO = 3;
        print ''
        print 'Erro ocorreu!'
        print 'Mensagem: ' + ERROR_MESSAGE()
        print 'Procedure: ' + ERROR_PROCEDURE()

		IF (SELECT CURSOR_STATUS('global', 'LE_NFE_VENDA')) = 1 
		BEGIN
			CLOSE LE_NFE_VENDA
			DEALLOCATE LE_NFE_VENDA
		END
			IF (SELECT CURSOR_STATUS('global', 'INTEGRA_NFE_VENDA')) = 1 
		BEGIN
			CLOSE INTEGRA_NFE_VENDA
			DEALLOCATE INTEGRA_NFE_VENDA
		END

  END CATCH
	END
	--END IF ELSE DE CONFERE NOTA DE SAIDA NAO INTEGRADA

	-- GOTO
	ERRO4:
	-- Fecha e desaloca os cursores
	IF (SELECT CURSOR_STATUS('global', 'LE_NFE_VENDA')) = 1 
		BEGIN
		CLOSE LE_NFE_VENDA
		DEALLOCATE LE_NFE_VENDA
	END
	IF (SELECT CURSOR_STATUS('global', 'INTEGRA_NFE_VENDA')) = 1 
		BEGIN
		CLOSE INTEGRA_NFE_VENDA
		DEALLOCATE INTEGRA_NFE_VENDA
	END
	--ULTIMAS VERIFICACOES PARA COMMIT OU ROLLBACK
	IF @@ERROR != 0 
		BEGIN
		ROLLBACK
		PRINT @@error
		PRINT 'Operação cancelada'
	END
	ELSE IF @ERRO_INTERNO=1
		BEGIN
		ROLLBACK
		PRINT 'Documento inexistente'
	END
	ELSE IF @ERRO_INTERNO=2
		BEGIN
		ROLLBACK
		PRINT 'Documento já integrado'
	END
	ELSE IF @ERRO_INTERNO=3
		BEGIN
		ROLLBACK
		PRINT 'Erro na procedure de estoque'
	END
	ELSE IF @ERRO_INTERNO=4
		BEGIN
		ROLLBACK
		PRINT 'Saldo insuficiente'
	END
	ELSE
		BEGIN
		UPDATE NOTA_FISCAL SET INTEGRADA_SUP='S' 
			 WHERE COD_EMPRESA=@COD_EMPRESA
			AND NUM_NF=@NUM_NF;
		COMMIT
		PRINT 'Integração concluída com sucecsso'
	END

-- Finaliza a procedure
END

-- Limpeza de tabelas de estoque para testes
DELETE FROM ESTOQUE
DELETE FROM ESTOQUE_MOV
DELETE FROM ESTOQUE_LOTE

-- Verificação de tabelas de estoque após limpeza
SELECT *
FROM ESTOQUE
SELECT *
FROM ESTOQUE_MOV
SELECT *
FROM ESTOQUE_LOTE

--TESTANDO PROCEDURE 
--PARAMETROS @COD_EMPRESA,@NUM_NF,@DATA_MOVTO
SELECT *
FROM NOTA_FISCAL

-- Notas de entrada
EXECUTE PROC_INTEGR_NF_ESTOQUE 1,1,'01-01-2018'
EXECUTE PROC_INTEGR_NF_ESTOQUE 1,2,'01-01-2018'
EXECUTE PROC_INTEGR_NF_ESTOQUE 1,3,'01-01-2018'
EXECUTE PROC_INTEGR_NF_ESTOQUE 1,4,'01-01-2018'

-- Notas de saída
EXECUTE PROC_INTEGR_NF_ESTOQUE 1,5,'01-01-2018' 