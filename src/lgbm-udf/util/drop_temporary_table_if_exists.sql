--
-- 指定された名前の一時テーブルを削除する
--
-- 一時テーブルが存在した場合に TRUE を返す。それ以外の場合に FALSE を返す。
--

CREATE OR REPLACE FUNCTION analysis.evwh_drop_temporary_table_if_exists (
    tmp_table_name text
)
RETURNS boolean AS $$
DECLARE
  tmp_schema_name text;
BEGIN

  SELECT nspname FROM pg_namespace WHERE oid = pg_my_temp_schema() INTO tmp_schema_name;
  IF (SELECT analysis.evwh_has_table(tmp_schema_name, tmp_table_name)) THEN
    EXECUTE '
      DROP TABLE IF EXISTS ' || tmp_schema_name || '.' || quote_ident(tmp_table_name) || '
    ';
    RETURN TRUE;
  END IF;
  RETURN FALSE;

END;
$$ LANGUAGE PLPGSQL VOLATILE;
