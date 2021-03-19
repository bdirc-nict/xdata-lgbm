--
-- テーブルが存在しているかを取得する
--
-- PostgreSQL 8.2 には CREATE TABLE IF EXISTS が存在しないので代用する
--

CREATE OR REPLACE FUNCTION analysis.evwh_has_table (
  schema_name text,
  table_name text
)
RETURNS boolean AS $$
DECLARE
  retval boolean;
BEGIN
  SELECT CASE count(1) WHEN 1 THEN TRUE ELSE FALSE END
  FROM
    pg_catalog.pg_class c,
    pg_catalog.pg_namespace n
  WHERE
    n.oid = c.relnamespace
    AND c.relkind = 'r'
    AND n.nspname = schema_name
    AND c.relname = table_name
  INTO
    retval;
  RETURN retval;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION analysis.evwh_has_table (
  table_name text
)
RETURNS boolean AS $$
DECLARE
  elements text[];
  n_elements integer;
  retval boolean;
BEGIN

  elements := string_to_array(table_name, '.');
  n_elements := array_upper(elements, 1);

  IF n_elements = 1 THEN
    -- current_schemas を関数実行時に評価させるため EXECUTE を用いる
    EXECUTE 'SELECT bool_or(analysis.evwh_has_table(s, ' || quote_literal(elements[1]) || ')) FROM unnest(current_schemas(false)) s' INTO retval;
    RETURN retval;
  ELSIF n_elements = 2 THEN
    RETURN analysis.evwh_has_table(elements[1], elements[2]);
  ELSE
    RETURN FALSE;
  END IF;

END;
$$ LANGUAGE plpgsql VOLATILE;


-- 後方互換性のための定義

CREATE OR REPLACE FUNCTION analysis.has_table (
  schema_name text,
  table_name text
)
RETURNS boolean AS $$
DECLARE
  retval boolean;
BEGIN
  SELECT analysis.evwh_has_table(schema_name, table_name) INTO retval;
  RETURN retval;
END;
$$ LANGUAGE plpgsql VOLATILE;
