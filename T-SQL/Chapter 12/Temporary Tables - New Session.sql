-----------------------------------------

-- Temporary Tables - New Session

-----------------------------------------

--------------------------------
-- Local Temporary Tables
--------------------------------

USE TSQLV6;

SELECT orderyear, qty FROM #MyOrderTotalByYear;



---------------------------------
-- Global Temporary Tables
---------------------------------

SELECT val FROM ##Globals
WHERE id = N'I';



