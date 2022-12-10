/* ########################################################################### ##
-- Author       Yunsik Choung
-- Created      12/10/2022
-- Purpose      Statistical Analysis Procedure Creation. 
--              2. Mean Comparison Analysis with Student t-test Between two groups in dependant variable to numeric variable on target table
-- Copyright © 2022, YunsikChoung, All Rights Reserved
-- Type			 Stored Procedure
-- Name			 ttest
------------------------------------------------------------------------------
-- Input:
	1. TARGET_TABLE VARCHAR(150): INDEPENDENT_VARIABLE and GROUP_VARIABLE variables Entity Table Name.
	2. INDEPENDET_VARIABLE VARCHAR(150): Attribute Name for calculating MEAN
	3. GROUP_VARIABLE VARCHAR(150): Attribute Nmae for calculating MEAN Comparison, This variable must have ONLY two distinct records
	
-- Output:
	1. GROUP: GROUP VARIABLE's each records
	2. N: Number of observation for each group
	3. GAP: Mean difference between first row - second row
	4. df: Degree of freedom, Group 1's number + Group 2's number - 2
	5. t-Statistics: t-Statistics for testing significant level.
-------------------------------------------------------------------------------
-- Modification History
--
-- 12/10/2022  Yunsik Choung  
--      First Commit. 
## ############################################################################ */
DELIMITER $$

DROP PROCEDURE IF EXISTS ttest$$

CREATE PROCEDURE ttest(IN TARGET_TABLE VARCHAR(150), IN INDEPENDENT_VARIABLE VARCHAR(150), IN GROUP_VARIABLE VARCHAR(150))
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		SELECT @full_error;
	END;
	BEGIN
		DECLARE SQL_TXT TEXT;
		DECLARE ROW_CHECK TEXT;
		SET @ROW_NUM = 0; 
		SET SQL_TXT = CONCAT('WITH COUNT_GROUP AS (SELECT DISTINCT ', GROUP_VARIABLE, ' AS G, ROW_NUMBER() OVER() AS ROW_NUM FROM ', TARGET_TABLE, ' GROUP BY ', GROUP_VARIABLE, ')');
		SET ROW_CHECK = 'SELECT MAX(ROW_NUM) INTO @ROW_NUM FROM COUNT_GROUP;';
		SET @s = CONCAT(SQL_TXT, ROW_CHECK);
		PREPARE STMT FROM @s; 
		EXECUTE STMT;
		
		IF @ROW_NUM = 2 THEN
			SET SQL_TXT = CONCAT(SQL_TXT, ', BASE AS (SELECT SUM(CASE ', GROUP_VARIABLE, ' WHEN (SELECT G FROM COUNT_GROUP WHERE ROW_NUM = 1) THEN 1 END)  AS G1_N ');
			SET SQL_TXT = CONCAT(SQL_TXT, ',SUM(CASE ', GROUP_VARIABLE, ' WHEN (SELECT G FROM COUNT_GROUP WHERE ROW_NUM = 2) THEN 1 END) AS G2_N ');
			SET SQL_TXT = CONCAT(SQL_TXT, ',VARIANCE(CASE ', GROUP_VARIABLE, ' WHEN (SELECT G FROM COUNT_GROUP WHERE ROW_NUM = 1) THEN ', INDEPENDENT_VARIABLE, ' END) AS G1_VAR');
			SET SQL_TXT = CONCAT(SQL_TXT, ',VARIANCE(CASE ', GROUP_VARIABLE, ' WHEN (SELECT G FROM COUNT_GROUP WHERE ROW_NUM = 2) THEN ', INDEPENDENT_VARIABLE, ' END) AS G2_VAR');
			SET SQL_TXT = CONCAT(SQL_TXT, ',AVG(CASE ', GROUP_VARIABLE, ' WHEN (SELECT G FROM COUNT_GROUP WHERE ROW_NUM = 1) THEN ', INDEPENDENT_VARIABLE, ' END) AS G1_AVG');
			SET SQL_TXT = CONCAT(SQL_TXT, ',AVG(CASE ', GROUP_VARIABLE, ' WHEN (SELECT G FROM COUNT_GROUP WHERE ROW_NUM = 2) THEN ', INDEPENDENT_VARIABLE, ' END) AS G2_AVG');
			SET SQL_TXT = CONCAT(SQL_TXT, ' FROM ', TARGET_TABLE, ')');
			
			SET SQL_TXT = CONCAT(SQL_TXT, 'SELECT (SELECT G FROM COUNT_GROUP WHERE ROW_NUM = 1) AS `GROUP`,G1_N AS N, ROUND(G1_AVG, 3) AS MEAN ,ROUND(G1_AVG - G2_AVG, 3) AS GAP ,G1_N + G2_N - 2 AS df ');
			SET SQL_TXT = CONCAT(SQL_TXT, ',ROUND((G1_AVG - G2_AVG)/(SQRT(((G1_N * G1_VAR^2 + G2_N * G2_VAR)/ (G1_N + G2_N - 2)) * ((G1_N + G2_N)/(G1_N * G2_N)))), 3) AS `t-statistics`');
			SET SQL_TXT = CONCAT(SQL_TXT, ' FROM BASE UNION SELECT (SELECT G FROM COUNT_GROUP WHERE ROW_NUM = 2) ,G2_N ,ROUND(G2_AVG, 3) ,\'\' ,\'\' ,\'\'  FROM BASE;');
			SET @s = SQL_TXT;
			PREPARE STMT FROM @s; 
			EXECUTE STMT;
		ELSE 
			SELECT CONCAT('Your group variable has ', @ROW_NUM, ' distinct records. You must select attribute that has only two distinct records.'); 
		END IF;
	END;
END$$
DELIMITER ;