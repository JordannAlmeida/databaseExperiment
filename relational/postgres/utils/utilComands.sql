-- check the most used tables in schema:
SELECT schemaname, relname, COALESCE(seq_scan, 0) + COALESCE(idx_scan, 0) AS nr_accesses
FROM pg_stat_all_tables
WHERE schemaname = 'public'  -- Replace with your schema name
ORDER BY nr_accesses DESC NULLS LAST;

-- check if autovacuum is enable in database (https://www.postgresql.org/docs/current/routine-vacuuming.html)
SHOW autovacuum;

-- check index fragmentation
SELECT 
  index_name,
  index_size,
  total_size,
  fragmentation_percentage
FROM (
  SELECT 
    indexrelid::regclass AS index_name,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    pg_size_pretty(sum((pgstattuple(indexrelid)).tuple_len)::bigint) AS total_size,
    ROUND((pg_relation_size(indexrelid)::numeric / NULLIF(pg_total_relation_size(indexrelid), 0) - 1) * 100, 2) AS fragmentation_percentage
  FROM pg_index
  JOIN pg_class ON pg_index.indexrelid = pg_class.oid
  JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
  WHERE 
    pg_index.indisunique = true -- Exclude unique indexes
    and pg_namespace.nspname = 'public' -- Replace 'your_schema_name' with the desired schema name
  GROUP BY indexrelid
) AS subquery
ORDER BY fragmentation_percentage DESC;


-- check expensive queries (you need to enable pg_stat_statements in postgresql config, see in docker compose)
create extension pg_stat_statements;

select round(( 100 * total_exec_time  / sum(total_exec_time) over ())::numeric, 2) percent,
             round(total_exec_time::numeric, 2) as "totalExecutionTime (ms)",
             calls,
             round(mean_exec_time::numeric, 2) as "meanExecutionTime (ms)",
             stddev_exec_time,
             substring(query, 1, 200) as query
from pg_stat_statements
order by total_exec_time DESC
LIMIT 10;

-- check users active:
SELECT * FROM pg_stat_activity WHERE state = 'active';
SELECT count(*) FROM pg_stat_activity WHERE state = 'active'; -- number of users active
SELECT count(*) FROM pg_stat_activity WHERE state = 'idle'; -- number of users idle (check if zombie connections)

--to kill connections in idle:
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle';

-- users with queries:
select
    psa.usename as "UserLogged",
    psa.application_name as "Application Name",
    psa.state as "stats Connection",
    round(( 100 * pss.total_exec_time  / sum(pss.total_exec_time) over ())::numeric, 2) percent,
    round(pss.total_exec_time::numeric, 2) as "totalExecutionTime (ms)",
    pss.calls,
    round(pss.mean_exec_time::numeric, 2) as "meanExecutionTime (ms)",
    pss.stddev_exec_time,
    substring(pss.query, 1, 200) as query
from pg_stat_statements pss
inner join pg_stat_activity psa
on psa.usesysid = pss.userid
where psa.state = 'active' OR psa.state = 'idle'
order by total_exec_time desc
limit 10;
