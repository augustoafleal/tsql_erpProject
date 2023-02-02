/* PROCEDURE PARA GERAR ESTOQUE */
USE tsql_erpProject
GO

CREATE PROCEDURE PROC_GERA_ESTOQUE
	(@COD_EMPRESA INT,
	@TIPO_MOV VARCHAR(1),
	-- E (ENTRADA) S (SAÍDA)
	@COD_MAT  INT,
	@LOTE     VARCHAR(15),
	@QTD_MOV  DECIMAL(10, 2),
	@DATA_MOVTO DATE)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @ERRO_INTERNO INT;
	-- Início da transação
	BEGIN TRANSACTION

	-- Início do begin try 
	BEGIN TRY
	
	-- Verifica se material existe
	SELECT COUNT(*)
	from MATERIAL
	WHERE COD_EMPRESA = @COD_EMPRESA AND COD_MAT=@COD_MAT
	
	IF 	@@ROWCOUNT = 0
		BEGIN
		RAISERROR ('Material inexistente', -- Message text.  
                    10, -- Severity.  
                    1 -- State.  
                   );
		SET @ERRO_INTERNO=2
	END 
	ELSE
		BEGIN
		-- Estrutura de saída

		IF (@tipo_mov != 'S' AND @tipo_mov != 'E' )
				BEGIN
			SET @ERRO_INTERNO=3
		END 

		-- Condicional para operação de saída
		ELSE IF ( @tipo_mov = 'S' ) 
			BEGIN
			/*
				Realiza checagens encadeadas para validar se:
				a) SALDO < QTD MOV OR
				b) SALDO LOTE < QTD MOV
				c) REGISTRO NAO EXISTE NA TABELA ESTOQUE OU NA TABELA ESTOQUE LOTE
				Preenchendo alguma das condições, atribui ERROR = 1  
				*/
			IF ( 
					(SELECT TOP 1
					QTD_SALDO
				FROM ESTOQUE
				WHERE  COD_EMPRESA=@COD_EMPRESA
					AND @COD_MAT = COD_MAT) < @QTD_MOV
				OR
				(SELECT TOP 1
					QTD_LOTE
				FROM ESTOQUE_LOTE
				WHERE  COD_EMPRESA=@COD_EMPRESA
					AND @COD_MAT = COD_MAT
					AND LOTE = @LOTE) < @QTD_MOV
				OR
				(SELECT Count(*)
				FROM ESTOQUE
				WHERE  COD_EMPRESA = @COD_EMPRESA AND @COD_MAT = COD_MAT ) = 0
				OR
				(SELECT Count(*)
				FROM ESTOQUE_MOV
				WHERE  COD_EMPRESA = @COD_EMPRESA AND
					@COD_MAT = COD_MAT
					AND LOTE = @LOTE) = 0 ) 
						BEGIN
				SET @ERRO_INTERNO=1
			END 
					ELSE 
				   BEGIN
				-- Faz a atualização da ESTOQUE
				UPDATE ESTOQUE 
					SET    QTD_SALDO = QTD_SALDO - @QTD_MOV 
					WHERE  COD_EMPRESA = @COD_EMPRESA AND
					@COD_MAT = COD_MAT
				;
				-- Faz a atualização da ESTOQUE_LOTE
				UPDATE ESTOQUE_LOTE 
					SET    QTD_LOTE = QTD_LOTE - @QTD_MOV 
					WHERE  COD_EMPRESA=@COD_EMPRESA AND
					@COD_MAT = COD_MAT
					AND LOTE = @LOTE
				-- Insert da movimentação na ESTOQUE_MOV
				INSERT ESTOQUE_MOV
				VALUES
					(@COD_EMPRESA,
						@TIPO_MOV,
						@COD_MAT,
						@LOTE,
						@QTD_MOV,
						@DATA_MOVTO,
						Getdate(),
						SYSTEM_USER)

				PRINT 'Baixa realizada'
			END
		END

		-- Condicional para operação de entrada 
		IF ( @TIPO_MOV = 'E' ) 
      BEGIN
			-- Se o material existir na tabela ESTOQUE, atualiza o saldo
			IF (SELECT Count(*)
			FROM ESTOQUE
			WHERE  COD_EMPRESA=@COD_EMPRESA AND COD_MAT = @COD_MAT) > 0 
            BEGIN
				UPDATE ESTOQUE 
                SET    QTD_SALDO = QTD_SALDO + @QTD_MOV
                WHERE  COD_EMPRESA=@COD_EMPRESA AND COD_MAT = @COD_MAT

				PRINT 'Update realizado com sucesso na tabela ESTOQUE.'
			END 
          ELSE 
		    -- Se não existir o material na tabela, realiza o insert
            BEGIN
				INSERT INTO ESTOQUE
				VALUES
					(@COD_EMPRESA,
						@COD_MAT,
						@QTD_MOV)

				PRINT 'Insert realizado com sucesso na tabela ESTOQUE'
			END

			-- Se o material existir na tabela ESTOQUE_LOTE, atualiza o saldo
			IF (SELECT Count(*)
			FROM ESTOQUE_LOTE
			WHERE  COD_EMPRESA=@COD_EMPRESA
				AND COD_MAT = @COD_MAT
				AND LOTE = @LOTE) > 0 
            BEGIN
				UPDATE ESTOQUE_LOTE 
                SET    QTD_LOTE = QTD_LOTE + @QTD_MOV
                WHERE  COD_EMPRESA = @COD_EMPRESA
					AND COD_MAT = @COD_MAT
					AND LOTE = @LOTE

				PRINT 'Update realizado com sucesso na tabela ESTOQUE_LOTE.'
			END 
          ELSE 
		    -- Se não existir o material na tabela, realiza o insert
            BEGIN
				INSERT INTO ESTOQUE_LOTE
				VALUES
					(@COD_EMPRESA,
						@COD_MAT,
						@LOTE,
						@QTD_MOV)

				PRINT 'Insert realizado com sucesso na tabela ESTOQUE_LOTE'
			END
			-- Insere a movimentação na ESTOQUE_MOV 
			INSERT ESTOQUE_MOV
			VALUES
				(@COD_EMPRESA,
					@TIPO_MOV,
					@COD_MAT,
					@LOTE,
					@QTD_MOV,
					@DATA_MOVTO,
					Getdate(),
					SYSTEM_USER);
			PRINT 'Insert inserido com sucesso na tabela ESTOQUE_MOV.'
		END
	END
 --VALIDACOES FINAIS
	IF @@ERROR != 0 
		BEGIN
		ROLLBACK
		PRINT @@error
		PRINT 'Operação cancelada'
	END
	ELSE IF @ERRO_INTERNO = 1
		BEGIN
		ROLLBACK
		RAISERROR ('Estoque negativo', -- Message text.  
                      10, -- Severity.  
                      1 -- State.  
                      );
		PRINT 'Operação cancelada com Rollback'
	END
	ELSE IF @ERRO_INTERNO=2
		BEGIN
		ROLLBACK
		RAISERROR ('Material não existe', -- Message text.  
                      10, -- Severity.  
                      1 -- State.  
                      );
		PRINT 'Operação cancelada com Rollback'
	END
	ELSE IF @ERRO_INTERNO=3
		BEGIN
		ROLLBACK
		RAISERROR ('Operação não permitida', -- Message text.  
                      10, -- Severity.  
                      1 -- State.  
                      );
		PRINT 'Operação cancelada com rollback'
	END
	ELSE
		BEGIN
		COMMIT
		PRINT 'Operação concluída com sucesso'
	END 
	-- Fim do try
	END TRY
	-- Início do catch
	BEGIN CATCH
		SELECT
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_SEVERITY() AS ErrorSeverity ,
		ERROR_STATE() AS ErrorState,
		ERROR_PROCEDURE() AS ErrorProcedure ,
		ERROR_LINE() AS ErrorLine,
		ERROR_MESSAGE() AS ErrorMessage;  

		SET XACT_ABORT ON;
		IF @@TRANCOUNT > 0  
			ROLLBACK TRANSACTION;  
	 -- Final do catch
	END CATCH
-- Fim da procedure
END

/*
 Testes da procedure observando os parâmetros na seguinte ordem:
 PARAMTRO EMPRESA MOVIMENTO MATERIAL LOTE QTD DATE
 */

-- Teste com operação inexistente
EXEC PROC_GERA_ESTOQUE  1,'X',2,'ABF',50,'2017-01-31'

-- Teste com saída sem estoque
EXEC PROC_GERA_ESTOQUE  1,'S',2,'ABF',50,'2017-01-31'

-- Inserções corretas
EXEC PROC_GERA_ESTOQUE  1,'E',2,'ABF',50,'2017-01-31'

EXEC PROC_GERA_ESTOQUE  1,'E',2,'ABC',30,'2017-01-31'

EXEC PROC_GERA_ESTOQUE  1,'S',2,'ABF',49,'2017-01-31'

EXEC PROC_GERA_ESTOQUE  1,'E',1,'ABF',50,'2017-01-31'

-- Checagens
SELECT *
FROM ESTOQUE
SELECT *
FROM ESTOQUE_LOTE
SELECT *
FROM ESTOQUE_MOV