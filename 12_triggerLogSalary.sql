﻿/* TRIGGER PARA FAZER AUDITORIA DE SALÁRIO (LOG) */
USE tsql_erpProject
GO

CREATE TRIGGER TG_AUDIT_SAL
ON SALARIO
AFTER UPDATE
AS 
	BEGIN
	DECLARE @COD_EMPRESA INT,
				@MATRICULA_AUX INT

	IF UPDATE(SALARIO) 
		BEGIN
		DECLARE CURSOR_AUDITORIA CURSOR 
			FOR	SELECT COD_EMPRESA, MATRICULA
		FROM INSERTED

		OPEN CURSOR_AUDITORIA

		FETCH NEXT FROM CURSOR_AUDITORIA INTO @COD_EMPRESA, @MATRICULA_AUX

		WHILE @@FETCH_STATUS = 0
				BEGIN
			INSERT INTO AUDITORIA_SALARIO
			SELECT I.COD_EMPRESA,
				I.MATRICULA,
				D.SALARIO,
				I.SALARIO,
				CASE 
							WHEN LEN(SYSTEM_USER) > 20
								THEN LEFT(SYSTEM_USER, 20)
							ELSE SYSTEM_USER
							END AS USUARIO,
				GETDATE()
			FROM DELETED D INNER JOIN INSERTED I
				ON D.COD_EMPRESA = I.COD_EMPRESA
					AND D.MATRICULA = I.MATRICULA
			WHERE D.COD_EMPRESA = @COD_EMPRESA
				AND D.MATRICULA = @MATRICULA_AUX

			FETCH NEXT FROM CURSOR_AUDITORIA
					INTO @COD_EMPRESA, @MATRICULA_AUX

		END

		CLOSE CURSOR_AUDITORIA
		DEALLOCATE CURSOR_AUDITORIA

	END
END

-- Realização de testes
UPDATE SALARIO
SET SALARIO = SALARIO * 1.10
WHERE COD_EMPRESA = 1
	AND MATRICULA IN (3, 4)

SELECT *
FROM AUDITORIA_SALARIO