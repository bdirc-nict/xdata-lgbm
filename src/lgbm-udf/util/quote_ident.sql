--
-- テーブル名を必要に応じて quote する
--
-- quote_ident 関数をスキーマが付いていても処理できるようにしたもの
-- 下記の URL を参考にした
--   https://postgres.cz/wiki/PostgreSQL_SQL_Tricks_II#Quote_ident_for_schema.name

CREATE OR REPLACE FUNCTION analysis.evwh_quote_ident (
  table_name text
)
RETURNS text AS $$
DECLARE
  splitted text[] = string_to_array(table_name, '.');
BEGIN
  RETURN array_to_string(array(SELECT quote_ident(splitted[i]) FROM generate_series(1, array_upper(splitted, 1)) i), '.');
END;
$$ LANGUAGE plpgsql IMMUTABLE;
