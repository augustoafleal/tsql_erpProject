﻿/* PROCEDURE QUE REALIZA O APONTAMENTO DA PRODUÇÃO
Gera movimento de entrada de estoque do produto apontado
Gera movimento de saída estoque dos produtos consumo  */
USE tsql_erpProject
GO

CREATE PROCEDURE PROC_APONTAMENTO
	(@COD_EMPRESA INT,
	@ID_ORDEM INT,
	@COD_MAT_PROD INT,
	@QTD_APON DECIMAL(10,2),
	@LOTE_PROD VARCHAR(20))
AS
BEGIN
	DECLARE @APONTAMENTO TABLE
(
		ID_APON INT
)
	DECLARE 
       
		@QTD_PLAN DECIMAL(10,2),
		@QTD_PROD DECIMAL(10,2),
		@SALDO DECIMAL(10,2),
		@SALDO_AUX DECIMAL(10,2),
		@SITUACAO VARCHAR(1),
		@ERRO_INTERNO INT,
		@DATA_MOVTO DATE,
		@ID_APON INT,
		@COD_MAT_NECES INT,
		@QTD_ATEND DECIMAL(10,2),
		@QTD_LOTE DECIMAL(10,2),
		@TESTE INT,
		@COD_MAT_AUX INT,
		@QTD_NECES_CONS DECIMAL(10,2),
		@LOTE VARCHAR(20),
		@QTD_NECES DECIMAL(10,2)

	SET @DATA_MOVTO = GETDATE()

	BEGIN TRANSACTION

	/* PRIMEIRA ETAPA: atualiza ordem e movimenta estoque */

	-- IF que verifica se existe ordem para seleção
	IF  (SELECT COUNT(*)
	FROM ORDEM_PROD A
	WHERE COD_EMPRESA = @COD_EMPRESA
		AND A.COD_MAT_PROD = @COD_MAT_PROD
		AND A.ID_ORDEM = @ID_ORDEM
		AND A.SITUACAO='P') = 0 -- P (apenas ordens planejadas)
	BEGIN
		SET @ERRO_INTERNO=1
		PRINT 'ERRO1'
	END

-- Verifica se a QTD apontada é > que saldo para impedir apontamento 
ELSE IF (SELECT A.QTD_PLAN-A.QTD_PROD
	FROM ORDEM_PROD A
	WHERE COD_EMPRESA=@COD_EMPRESA AND A.ID_ORDEM=@ID_ORDEM)<@QTD_APON
		BEGIN
		SET @ERRO_INTERNO=2
		PRINT 'ERRO2'
	END

-- Verifica se materiais necessário tem saldo 
ELSE IF (SELECT COUNT(*)
	FROM ORDEM_PROD A
		INNER JOIN FICHA_TECNICA B
		ON  A.COD_EMPRESA=B.COD_EMPRESA
			AND A.COD_MAT_PROD=B.COD_MAT_PROD
		INNER JOIN ESTOQUE C
		ON A.COD_EMPRESA = C.COD_EMPRESA
			AND B.COD_MAT_NECES = C.COD_MAT
	WHERE A.COD_EMPRESA = @COD_EMPRESA
		AND A.ID_ORDEM = @ID_ORDEM
		AND (B.QTD_NECES * @QTD_APON) > C.QTD_SALDO) > 0
	BEGIN
		SET @ERRO_INTERNO=3
		PRINT 'ERRO3'
	END
	ELSE
	BEGIN

		BEGIN TRY

	-- Declara cursor de apontamento
	DECLARE APONT CURSOR FOR

	-- Seleciona valores
	SELECT A.ID_ORDEM, A.COD_MAT_PROD, A.QTD_PLAN, A.QTD_PROD
		FROM ORDEM_PROD A
		WHERE A.COD_EMPRESA = @COD_EMPRESA
			AND A.COD_MAT_PROD = @COD_MAT_PROD
			AND ID_ORDEM = @ID_ORDEM
			AND A.SITUACAO='P' 

-- Abre cursor
OPEN APONT

-- Lê registro
 FETCH NEXT FROM APONT

 -- Insere valores em variáveis
 INTO @ID_ORDEM,@COD_MAT_PROD,@QTD_PLAN,@QTD_PROD

 WHILE @@FETCH_STATUS = 0
	BEGIN
			-- Apresentação de informações
			SELECT @ID_ORDEM ID_ORDEM, @COD_MAT_PROD COD_MAT_PROD, @QTD_PLAN QTD_PLAN, @QTD_PROD QTD_PROD,
				@QTD_PLAN - @QTD_PROD AS SALDO
			SELECT 'QTD APONTADA ', @QTD_APON;
			SELECT 'SALDO ORDEM ', @QTD_PLAN-(@QTD_PROD + @QTD_APON)

			-- Atribui valores
			SET @SALDO = @QTD_PLAN - @QTD_PROD
			SET @SALDO_AUX = @SALDO

			-- Insert na tabela apontamentos para rastreabilidade
			INSERT INTO APONTAMENTOS
			OUTPUT INSERTED.ID_APON INTO @APONTAMENTO
			VALUES
				(@COD_EMPRESA, @ID_ORDEM, @COD_MAT_PROD, @QTD_APON, GETDATE(), SYSTEM_USER, @LOTE_PROD)

			-- Atribui ID_APON
			SELECT @ID_APON=ID_APON
			FROM @APONTAMENTO

			-- Executa procedure de geração de estoque
			EXEC PROC_GERA_ESTOQUE @COD_EMPRESA, 'E' ,@COD_MAT_PROD, @LOTE_PROD, @QTD_APON, @DATA_MOVTO

			-- Atualiza saldo da ordem
			UPDATE ORDEM_PROD SET QTD_PROD = @QTD_PROD + @QTD_APON
		WHERE COD_EMPRESA = @COD_EMPRESA
				AND ID_ORDEM = @ID_ORDEM
				AND COD_MAT_PROD = @COD_MAT_PROD
			SELECT 'Ordem atualizada!'

			SET @SALDO = @QTD_PLAN - (@QTD_PROD + @QTD_APON);
			SET @SALDO_AUX = @SALDO

			FETCH NEXT FROM APONT
    INTO @ID_ORDEM,@COD_MAT_PROD,@QTD_PLAN,@QTD_PROD

		END
	-- Fecha e desaloca cursor
    CLOSE APONT
	DEALLOCATE APONT
	END TRY 
    BEGIN CATCH
        SET @ERRO_INTERNO =5;
        print ''
        print 'Ocorreu um erro.'
        print 'Mensagem: ' + ERROR_MESSAGE()
        print 'Procedure: ' + ERROR_PROCEDURE()
END CATCH

		/* Início do segundo bloco para consumir necessidades e movimentar estoque */

		BEGIN TRY

	-- Declara cursor NECESSIDADES
	DECLARE NECESSIDADES CURSOR FOR

	-- Seleciona valores
	SELECT A.ID_ORDEM, A.SITUACAO, A.COD_MAT_PROD,
			A.QTD_PLAN, B.COD_MAT_NECES, B.QTD_NECES,
			@QTD_APON AS QTD_APON,
			@QTD_APON*B.QTD_NECES AS QTD_NECES_CONS
		FROM ORDEM_PROD A
			INNER JOIN FICHA_TECNICA B
			ON A.COD_EMPRESA=B.COD_EMPRESA
				AND A.COD_MAT_PROD=B.COD_MAT_PROD
		WHERE A.SITUACAO='P'
			AND A.COD_EMPRESA=@COD_EMPRESA
			AND A.ID_ORDEM=@ID_ORDEM
			AND A.COD_MAT_PROD=@COD_MAT_PROD
	-- Abre cursor
	OPEN NECESSIDADES
	
	-- Faz a leitura dos valores
	FETCH NEXT FROM NECESSIDADES

	-- Atribui valores
	INTO @ID_ORDEM,@SITUACAO,@COD_MAT_PROD,
	     @QTD_PLAN,@COD_MAT_NECES,@QTD_NECES,
	     @QTD_APON,@QTD_NECES_CONS
    
	-- Inicia laço while
    WHILE @@FETCH_STATUS = 0
	BEGIN

			-- Apresenta valores
			SELECT @ID_ORDEM ID_ORDEM, @SITUACAO SITUACAO , @COD_MAT_PROD COD_MAT_PROD,
				@QTD_PLAN QTD_PLAN, @COD_MAT_NECES COD_MAT_NECES, @QTD_NECES QTD_NECES,
				@QTD_APON QTD_APON, @QTD_NECES_CONS QTD_NECES_CONS

			-- Declara cursor para alimentar consumo e movimentar estoque 
			DECLARE ESTOQUE_CONSUMO CURSOR FOR
	SELECT C.COD_MAT, C.QTD_LOTE, C.LOTE, @QTD_NECES_CONS
			FROM ESTOQUE_LOTE C
			WHERE C.COD_EMPRESA=@COD_EMPRESA
				AND C.COD_MAT = @COD_MAT_NECES
				AND C.QTD_LOTE>0
			ORDER BY C.COD_MAT,C.LOTE
			-- Abre cursor
			OPEN ESTOQUE_CONSUMO
			-- Lê registros do cursor 
			FETCH NEXT FROM ESTOQUE_CONSUMO

	-- Atribui valores
	INTO @COD_MAT_NECES,@QTD_LOTE,@LOTE,@QTD_NECES_CONS
			--ATRIBUINDO VALORES A VARIAVEIS
			SET  @SALDO=@QTD_NECES_CONS;
			SET  @SALDO_AUX=@SALDO

			-- Inicia laço while
			WHILE @@FETCH_STATUS = 0
		BEGIN

				-- Verifica troca de material
				IF @COD_MAT_AUX != @COD_MAT_NECES 
			  BEGIN
					SET @QTD_ATEND = 0
				END

				-- Verifica saldo <= 0	 
				IF @SALDO<=0
			  BEGIN
					SET @QTD_ATEND = 0
				END

				-- Verifica se SALDO_AUX >= A QTD_LOTE
				IF  @SALDO_AUX >= @QTD_LOTE
			  BEGIN
					-- Atribui valores
					SET  @QTD_ATEND = @QTD_LOTE
					SET  @SALDO = @SALDO - @QTD_NECES_CONS
					SET  @SALDO_AUX = @SALDO_AUX - @QTD_LOTE
				END

			-- Verifica se SALDO_AUX < QTD_LOTE
			  ELSE IF  @SALDO_AUX < @QTD_LOTE
			  BEGIN
					-- Atribui valores
					SET  @SALDO = @QTD_NECES_CONS
					SET  @QTD_ATEND = @SALDO_AUX
					SET  @SALDO_AUX = @SALDO_AUX - @QTD_ATEND
				END

				--IF para inserção de retorno com SALDO >= 0 AND QTD_ATEND > 0  
				IF @SALDO_AUX>=0 AND @QTD_ATEND>0
	      BEGIN
					SELECT @COD_MAT_NECES AS COD_MAT_NECES, @QTD_LOTE AS QTD_LOTE, @LOTE AS LOTE,
						@QTD_NECES_CONS AS QTD_NECES_CONS, @SALDO AS SALDO,
						@SALDO_AUX AS SALDO_AUX, @QTD_ATEND AS BAIXA

					-- INSERT na tabela de CONSUMO para dar rastreabilidade 
					INSERT INTO CONSUMO
					VALUES
						(@COD_EMPRESA, @ID_APON, @COD_MAT_NECES, @QTD_ATEND, @LOTE)

					-- Executa procedure de geraçao de estoque com movimento de saída
					EXEC PROC_GERA_ESTOQUE @COD_EMPRESA,'S',@COD_MAT_NECES,@LOTE,@QTD_ATEND,@DATA_MOVTO

					--ATRIBUINDO VALOR VARIAVEL 
					SET @COD_MAT_AUX = @COD_MAT_NECES;
				END

				FETCH NEXT FROM ESTOQUE_CONSUMO
		INTO @COD_MAT_NECES, @QTD_LOTE, @LOTE, @QTD_NECES_CONS
			END

			-- Fecha e desaloca cursor interno
			CLOSE ESTOQUE_CONSUMO
			DEALLOCATE ESTOQUE_CONSUMO

			FETCH NEXT FROM NECESSIDADES
		INTO @ID_ORDEM,@SITUACAO,@COD_MAT_PROD,
			 @QTD_PLAN,@COD_MAT_NECES,@QTD_NECES,
			 @QTD_APON,@QTD_NECES_CONS

		END 
	-- Fecha e desaloca cursor externo
	CLOSE NECESSIDADES
	DEALLOCATE NECESSIDADES

	END TRY 
    BEGIN CATCH
        SET @ERRO_INTERNO =5;
        print ''
        print 'Erro ocorreu!'
        print 'Mensagem: ' + ERROR_MESSAGE()
        print 'Procedure: ' + ERROR_PROCEDURE()

		IF (SELECT CURSOR_STATUS('global', 'APONT')) = 1 
		BEGIN
			CLOSE APONT
			DEALLOCATE APONT
		END
		IF (SELECT CURSOR_STATUS('global', 'ESTOQUE_CONSUMO')) = 1 
		BEGIN
			CLOSE ESTOQUE_CONSUMO
			DEALLOCATE ESTOQUE_CONSUMO
		END
		IF (SELECT CURSOR_STATUS('global', 'NECESSIDADES')) = 1 
		BEGIN
			CLOSE NECESSIDADES
			DEALLOCATE NECESSIDADES
		END	
		
		SET XACT_ABORT ON;
		IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION; 

END CATCH

	-- Finaliza primeiro IF
	END

	-- Atualiza a situação  da ordem de produção
	IF (SELECT A.QTD_PLAN-A.QTD_PROD SALDO
	FROM ORDEM_PROD A
	WHERE  COD_EMPRESA=@COD_EMPRESA AND A.ID_ORDEM=@ID_ORDEM AND A.SITUACAO='P')=0
	BEGIN
		UPDATE ORDEM_PROD SET SITUACAO='F' 
		WHERE COD_EMPRESA=@COD_EMPRESA
			AND ID_ORDEM=@ID_ORDEM
			AND SITUACAO='P'
		SELECT 'Ordem finalizada.'
	END


	-- Últimas validações
	IF @@ERROR <> 0 
		BEGIN
		ROLLBACK
		PRINT @@error
		PRINT 'Operação cancelada.'
	END
	 ELSE IF @ERRO_INTERNO=1
	 BEGIN
		PRINT 'Ordem não existe, inexistência de saldo ou os parâmetros incorretos.'
		ROLLBACK
	END
	 ELSE IF @ERRO_INTERNO=2
	 BEGIN
		PRINT 'Não há saldo suficiente.'
		ROLLBACK
	END
	 ELSE IF @ERRO_INTERNO=3
	 BEGIN
		PRINT 'Não há materiais suficientes.'
		ROLLBACK
	END
	  ELSE IF @ERRO_INTERNO=5
	 BEGIN
		PRINT 'Erro na procedure de estoque.'
		ROLLBACK
	END

	 ELSE
		BEGIN
		COMMIT
		PRINT 'Apontamento concluído.'
	END

-- Finaliza procedure
END

-- Testes de procedure
--PARAMETROS @COD_EMPRESA @ID_ORDEM,@COD_MAT_PROD,@QTD_APON,@LOTE_PROD

-- Forçando erros para testes
EXEC PROC_APONTAMENTO 2,1,1,10,'TESTE1'
EXEC PROC_APONTAMENTO 1,1,2,10,'TESTE1'
EXEC PROC_APONTAMENTO 1,1,1,40,'TESTE1'

EXEC PROC_APONTAMENTO 1,1,1,10,'TESTE1'
EXEC PROC_APONTAMENTO 1,1,1,25,'TESTE2'


SELECT *
from ORDEM_PROD
select *
from ESTOQUE
select *
from ESTOQUE_LOTE
SELECT *
FROM ESTOQUE_MOV
SELECT *
FROM APONTAMENTOS
SELECT *
FROM CONSUMO