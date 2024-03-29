﻿/* TRIGGER PARA BLOQEIO DE USUÁRIO QUANDO DEMITIDO */
USE tsql_erpProject
GO

CREATE TRIGGER TG_BLOQUEIA_USUARIO ON FUNCIONARIO
AFTER UPDATE
AS
BEGIN
	DECLARE @COD_EMPRESA INT,
			@MATRICULA INT,
			@DATE_DEMISS DATE

	SELECT
		@COD_EMPRESA = I.COD_EMPRESA,
		@MATRICULA = I.MATRICULA,
		@DATE_DEMISS = I.DATE_DEMISS
	FROM INSERTED I;

	IF UPDATE(DATE_DEMISS) AND @DATE_DEMISS != '1900-01-01'
		BEGIN
		UPDATE USUARIOS 
			SET SITUACAO = 'B' 
			WHERE COD_EMPRESA = @COD_EMPRESA
			AND MATRICULA = @MATRICULA
		PRINT 'Matrícula bloqueada -> ' + CAST(@MATRICULA AS VARCHAR(20));
	END
END

-- Realização de teste
UPDATE FUNCIONARIO
SET DATE_DEMISS = GETDATE()
WHERE COD_EMPRESA = 1
	AND MATRICULA = '4'

-- Validação
SELECT *
FROM USUARIOS
ORDER BY
 COD_EMPRESA,
 MATRICULA

 SELECT *
FROM FUNCIONARIO
ORDER BY
 COD_EMPRESA,
 MATRICULA