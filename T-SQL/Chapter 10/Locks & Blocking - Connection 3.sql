USE TSQLV6; -- (Connection 3)

SELECT request_session_id AS sid,
	resource_type AS restype,
	resource_database_id AS dbid,
	DB_NAME(resource_database_id) AS dbname,
	resource_description AS res,
	resource_associated_entity_id AS resid,
	request_mode AS mode,
	request_status AS status
FROM sys.dm_tran_locks;



SELECT session_id, text
FROM sys.dm_exec_connections
	CROSS APPLY sys.dm_exec_sql_text(most_recent_sql_handle) AS ST
WHERE session_id IN (52, 64);



KILL 52;