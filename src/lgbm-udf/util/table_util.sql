--
-- 与えられた文字列がテーブル名として適切かどうかを判定する
--

CREATE OR REPLACE FUNCTION analysis.evwh_is_valid_table_name (
  table_name text,
  allow_schema bool)
RETURNS boolean AS $$
DECLARE
  pattern text;
  retval boolean;
BEGIN
  pattern := '[0-9a-zA-Z_]{1,63}';
  IF allow_schema THEN
    pattern := '([0-9a-zA-Z_]{1,63}\.)?' || pattern;
  END IF;
  pattern := '^[ ]*(' || pattern || ')[ ]*$';
  IF array_lower(regexp_matches(table_name, pattern), 1) > 0 THEN
    retval := TRUE;
  ELSE
    retval := FALSE;
  END IF;
  RETURN retval;
END
$$ LANGUAGE plpgsql;


--
-- 与えられた文字列がカラム名として適切かどうかを判定する
--

CREATE OR REPLACE FUNCTION analysis.evwh_is_valid_column_name (
  column_name text)
RETURNS boolean AS $$
DECLARE
  pattern text;
  retval boolean;
BEGIN
  pattern := '[0-9a-zA-Z_]{1,63}';
  pattern := '^[ ]*(' || pattern || ')[ ]*$';
  IF array_lower(regexp_matches(column_name, pattern), 1) > 0 THEN
    retval := TRUE;
  ELSE
    retval := FALSE;
  END IF;
  RETURN retval;
END
$$ LANGUAGE plpgsql;


--
-- 与えられたテーブル名からスキーマ名の部分を取り除く
--

CREATE OR REPLACE FUNCTION analysis.evwh_trim_schema_name (
  table_name text)
RETURNS text AS $$
DECLARE
  retval text;
BEGIN
  retval = table_name;
  WHILE retval ~ '\.' LOOP
    retval := regexp_replace(retval, '^.*\.', '');
  END LOOP;
  RETURN retval;
END
$$ LANGUAGE plpgsql;


--
-- 与えられた文字列がカラム名として適切かどうかを判定する．関数呼び出しがあっても許容する
--

-- CREATE OR REPLACE FUNCTION analysis.evwh_is_valid_column_name_with_function (
--  column_name text)
-- RETURNS boolean AS $$
-- DECLARE
--  pattern text;
--  result text[];
--  retval boolean;
-- BEGIN
-- 括弧の内側から置換していく
--  pattern := '[0-9a-zA-Z_]{1,63}[ ]*\((.+)\)';
--  pattern := '^[ ]*' || pattern || '[ ]*$';
--  IF array_lower(regexp_matches(column_name, pattern), 1) > 0 THEN
--    retval := TRUE;
--  ELSE
--  pattern := '[0-9a-zA-Z_]{1,63}';
--  pattern := '^([ ]*' || pattern || '[ ]*)$';
--  END IF;
--  RETURN retval;
-- END
-- $$ LANGUAGE plpgsql;

--
-- @func analysis.evwh_get_schema_name
-- @description: Get the schema name of the given table
-- @param _name: Table name, with or without schema
-- @return: The schema name of the table if exists, or '' if not exists
--
CREATE OR REPLACE FUNCTION analysis.evwh_get_schema_name (
  _name text
) RETURNS text AS $$
DECLARE
  _arr text[];
  _len integer;
  _schema text;
  _i integer;
  _b boolean;
  _schema_list text[];
BEGIN
  _arr := regexp_split_to_array(_name, '\.');
  _len := array_length(_arr, 1);

  IF _len = 2 THEN
    RETURN _arr[1];
  END IF;

  IF _len > 2 THEN
    RAISE EXCEPTION '"%" is not a valid table name', _name;
  END IF;

  SELECT current_schemas(FALSE) INTO _schema_list;
  FOR _i IN 1 .. array_upper(_schema_list, 1)
  LOOP
    _schema := _schema_list[_i];  
    SELECT EXISTS(
      SELECT 1 FROM
        information_schema.tables
      WHERE
        table_schema = _schema
      AND
        table_name = _arr[1]
    ) INTO _b;

    IF _b THEN
      RETURN _schema;
    END IF;

  END LOOP;

  RETURN _schema_list[1];

END
$$ LANGUAGE plpgsql VOLATILE;

GRANT EXECUTE ON FUNCTION analysis.evwh_get_schema_name(
  text
) TO PUBLIC;

--
-- @func analysis.evwh_check_table
-- @description: Check if the table can open with specified mode
-- @param _name: Table name
-- @param _mode: Open mode
--       'overwrite': If the table exists, drop it. (default value)
--       'append': Ignore whegher the table exists or not.
--       'error': Raise an error if the table exists.
-- @return: The table name (for future compatibility...)
--
CREATE OR REPLACE FUNCTION analysis.evwh_check_table(
  _name text,
  _mode text DEFAULT 'overwrite'
) RETURNS text AS $$
DECLARE
  _is_exists boolean;
  _schema text;
  _table text;
BEGIN

  -- Check table name
  IF analysis.evwh_is_valid_table_name(_name, TRUE) = FALSE THEN
    RAISE EXCEPTION '"%" is not a valid table name', _name;
  END IF;

  -- Check if the table exists
  _schema := analysis.evwh_get_schema_name(_name);
  _table  := analysis.evwh_trim_schema_name(_name);

  SELECT EXISTS(
    SELECT 1 FROM
      information_schema.tables
    WHERE
      table_schema = _schema
    AND
      table_name = _table
  ) INTO _is_exists;

  IF NOT _is_exists THEN
    RETURN _schema || '.' || _table;
  END IF;

  IF _mode = 'overwrite' THEN
    EXECUTE 'DROP TABLE ' || _schema || '.' || _table;
  ELSEIF _mode = 'error' THEN
    RAISE EXCEPTION 'Table "%" exists', _name;
  END IF;

  RETURN _schema || '.' || _table;

END
$$ LANGUAGE 'plpgsql' VOLATILE;

GRANT EXECUTE ON FUNCTION analysis.evwh_check_table(
  text, text
) TO PUBLIC;
