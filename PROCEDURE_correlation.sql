
/* ########################################################################### ##
-- Author       Yunsik Choung
-- Created      12/9/2022
-- Purpose      Statistical Analysis Procedure Creation. 
--              1. Correlation Between two numberic variables on target table
-- Copyright © 2022, YunsikChoung, All Rights Reserved
-- Type			 Stored Procedure
-- Name			 correlation
------------------------------------------------------------------------------
-- Input:
	1. X_VARIABLE VARCHAR(150): Attribute Name for calculating Correlation AS X
	2. Y_VARIABLE VARCHAR(150): Attribute Nmae for calculating Correlation AS Y
	3. TARGET_TABLE VARCHAR(150): X and Y variables Entity Table Name.
-- Output:
	1. X: Attribute Name
	2. Y: Attribute Name
	3. Coefficient: Correlation Coefficient
	4. df: Degree of freedom
	5. t-Statistics: t-Statistics for testing significant level.
-------------------------------------------------------------------------------
-- Modification History
--
-- 12/09/2022  Yunsik Choung  
--      First Commit. 
## ############################################################################ */
DELIMITER $$

DROP PROCEDURE IF EXISTS correlation$$

CREATE PROCEDURE correlation(IN X_VARIABLE VARCHAR(150), IN Y_VARIABLE VARCHAR(150), IN TARGET_TABLE VARCHAR(150))
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		SELECT @full_error;
	END;
	
	BEGIN
		DECLARE SQL_TEXT TEXT;
		SET SQL_TEXT = 'WITH  TARGET AS (SELECT	`';
		SET SQL_TEXT = CONCAT(SQL_TEXT, X_VARIABLE, '` AS `X` ');
		SET SQL_TEXT = CONCAT(SQL_TEXT, ',`', Y_VARIABLE, '` AS `Y` ');
		SET SQL_TEXT = CONCAT(SQL_TEXT, 'FROM ', TARGET_TABLE);
		SET SQL_TEXT = CONCAT(SQL_TEXT, '), BASE AS (');
		SET SQL_TEXT = CONCAT(SQL_TEXT, 'SELECT	ROUND((');
		SET SQL_TEXT = CONCAT(SQL_TEXT, '(SUM(X * Y)');
		SET SQL_TEXT = CONCAT(SQL_TEXT, '/ (SELECT COUNT(*) - 1 FROM ', TARGET_TABLE);
		SET SQL_TEXT = CONCAT(SQL_TEXT, ')');
		SET SQL_TEXT = CONCAT(SQL_TEXT, '- ((SELECT SUM(X)');
		SET SQL_TEXT = CONCAT(SQL_TEXT, '/ (COUNT(*)) FROM ', TARGET_TABLE);
		SET SQL_TEXT = CONCAT(SQL_TEXT, ') * (SELECT SUM(Y) / (COUNT(*) - 1) FROM ', TARGET_TABLE);
		SET SQL_TEXT = CONCAT(SQL_TEXT, '))))/ SQRT((VAR_SAMP(X) * VAR_SAMP(Y))), 3) AS `r` ,COUNT(*) AS `N` FROM TARGET)');
		SET SQL_TEXT = CONCAT(SQL_TEXT, 'SELECT \'', X_VARIABLE, '\' AS `X` ');
		SET SQL_TEXT = CONCAT(SQL_TEXT, ',\'', Y_VARIABLE, '\' AS `Y` ,ROUND(r, 3) AS `Coefficient` ,N - 2 AS `df`');
		SET SQL_TEXT = CONCAT(SQL_TEXT, ',ROUND((r * SQRT(N - 2)) / (SQRT(1 - POWER(r, 2))), 3) AS `t-Statistics` FROM BASE');
		SET @s = SQL_TEXT;
	END;
	
	
	PREPARE STMT FROM @s; 
	EXECUTE STMT;
END$$
DELIMITER ;