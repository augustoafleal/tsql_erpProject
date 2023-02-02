/* PROCEDURE PARA INTEGRAR AS NOTAS FISCAIS COM O PROCESSO FINANCEIRO 
Tabelas de origem: NOTA_FISCAL
Se saída será contas a pagar
Se entrada será contas a receber */

USE tsql_erpProject
GO

-- Criação de procedure
CREATE PROCEDURE PROC_INTEGR_FIN
    (@COD_EMPRESA INT)
AS
SET NOCOUNT ON

DECLARE @TIP_NF CHAR(1),
        @NUM_NF INT,
		@ID_CLIFOR DECIMAL(10,2),
		@COD_PAGTO INT,
		@DATA_EMISSAO DATE,
		@VENCIMENTO DATE,
		@TOTAL_NF DECIMAL(10,2),
		@VALOR_PARC DECIMAL(10,2),
		@PARC INT,
		@CONT_PARC INT,
		@ERRO_INTERNO INT

BEGIN
    BEGIN TRANSACTION
    BEGIN TRY
-- Abre primeiro IF para verificar se existe NF para integrar
	IF (SELECT COUNT(*)
    FROM NOTA_FISCAL
    WHERE COD_EMPRESA=@COD_EMPRESA AND INTEGRADA_FIN='N')=0
	BEGIN
        SET @ERRO_INTERNO=1;
    END
	ELSE
	BEGIN

        -- Declara cursor 
        DECLARE CONTPARC CURSOR FOR

 --Lê tabela de quantidade de parcelas por NF 
	 SELECT A.NUM_NF,
            COUNT(*) CONT_PARC
        FROM NOTA_FISCAL A
            INNER JOIN COND_PAGTO_DET B
            ON A.COD_PAGTO = B.COD_PAGTO
        WHERE A.COD_EMPRESA = @COD_EMPRESA
            AND A.INTEGRADA_FIN = 'N'
        GROUP BY A.NUM_NF

        -- Abre cursor
        OPEN CONTPARC

        -- Lê o primeiro registro
        FETCH NEXT FROM CONTPARC
   -- Insere valor em variáveis
   INTO @NUM_NF,@CONT_PARC

        -- Percorr linhas do cursor 
        WHILE @@FETCH_STATUS = 0
	BEGIN

            -- Declara cursor para integrar tabelas
            DECLARE INTEGRA_FIN CURSOR FOR
   -- Seleciona registros
   SELECT A.TIP_NF,
                A.NUM_NF,
                A.ID_CLIFOR,
                A.COD_PAGTO,
                A.DATA_EMISSAO,
                CAST(DATEADD(dd, B.DIAS, A.DATA_EMISSAO) AS DATE) as VENCIMENTO,
                A.TOTAL_NF,
                CAST(A.TOTAL_NF/100 * B.PCT AS DECIMAL(10,2)) as VALOR_PARC,
                B.PARC
            FROM NOTA_FISCAL A
                INNER JOIN COND_PAGTO_DET B
                ON A.COD_PAGTO = B.COD_PAGTO
            WHERE COD_EMPRESA = @COD_EMPRESA
                AND A.INTEGRADA_FIN = 'N'
                AND NUM_NF = @NUM_NF

            -- Abre cursor
            OPEN INTEGRA_FIN
            -- Lê a próxima linha
            FETCH NEXT FROM INTEGRA_FIN
   -- Insere valores em variáveis
   INTO @TIP_NF,@NUM_NF,@ID_CLIFOR,@COD_PAGTO,@DATA_EMISSAO,
		@VENCIMENTO,@TOTAL_NF,@VALOR_PARC,@PARC

            -- Percorrendo linhas do cursor 
            WHILE @@FETCH_STATUS = 0
	BEGIN
                -- IF para integrar notas de saída CONTAS_RECEBER
                IF @TIP_NF='S'
	 BEGIN
                    INSERT INTO CONTAS_RECEBER
                    VALUES
                        (@COD_EMPRESA, @ID_CLIFOR, @NUM_NF, @PARC, @VENCIMENTO, NULL, @VALOR_PARC);
                    SELECT 'DOCTO  VENDAS', @NUM_NF , 'INTEGRADO COM SUCESSO ', 'PARCELA ', @PARC, 'VALOR ', @VALOR_PARC
                END

	--IF para integrar notas de compras de entrada CONTAS_PAGAR
	ELSE IF @TIP_NF='E'
	BEGIN
                    INSERT INTO CONTAS_PAGAR
                    VALUES
                        (@COD_EMPRESA, @ID_CLIFOR, @NUM_NF, @PARC, @VENCIMENTO, NULL, @VALOR_PARC);
                    SELECT 'DOCTO  COMPRAS', @NUM_NF , 'INTEGRADO COM SUCESSO ', 'PARCELA ', @PARC, 'VALOR ', @VALOR_PARC
                END

                -- If para atualizar status da nota na tabela NOTA_FISCAL quando estiver na última parcela
                IF @CONT_PARC = @PARC
	BEGIN
                    -- Atualiza status da NOTA FISCAL PARA INTEGRADA_FIN = S
                    SELECT 'ATUALIZA '+CAST(@NUM_NF AS VARCHAR(100))
                    UPDATE NOTA_FISCAL SET INTEGRADA_FIN='S' WHERE COD_EMPRESA=@COD_EMPRESA AND NUM_NF=@NUM_NF;
                END

                -- Lê a próxima linha do cursor
                FETCH NEXT FROM INTEGRA_FIN
    INTO @TIP_NF,@NUM_NF,@ID_CLIFOR,@COD_PAGTO,@DATA_EMISSAO,
		@VENCIMENTO,@TOTAL_NF,@VALOR_PARC,@PARC;

            -- Finaliza laço while interno
            END
            -- Fecha e desaloca cursor mais interno
            CLOSE INTEGRA_FIN
            DEALLOCATE INTEGRA_FIN

            -- Lê a próxima linha do cursor externo
            FETCH NEXT FROM CONTPARC
   INTO @NUM_NF,@CONT_PARC

        -- Finaliza while externo
        END

        -- Fecha e desaloca cursor externo
        CLOSE CONTPARC
        DEALLOCATE CONTPARC

    -- FInaliza ELSE 
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

		IF (SELECT CURSOR_STATUS('global', 'INTEGRA_FIN')) = 1 
		BEGIN
        CLOSE INTEGRA_FIN
        DEALLOCATE INTEGRA_FIN
    END
		IF (SELECT CURSOR_STATUS('global', 'CONTPARC')) = 1 
		BEGIN
        CLOSE CONTPARC
        DEALLOCATE CONTPARC
    END	
		
		SET XACT_ABORT ON;
		IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION; 
END CATCH

    --VERIFICACOES FINAIS
    IF @@ERROR != 0 
		BEGIN
        ROLLBACK TRANSACTION
        PRINT @@error
        PRINT 'Operação cancelada.'
    END
	ELSE IF @ERRO_INTERNO=1
	BEGIN
        ROLLBACK TRANSACTION
        PRINT 'Não há documentos para processar.'
    END
	ELSE
		BEGIN
        COMMIT TRANSACTION
        PRINT 'Integração concluída'
    END

-- Finaliza procedure
END

-- Testa procedure
EXECUTE PROC_INTEGR_FIN 1