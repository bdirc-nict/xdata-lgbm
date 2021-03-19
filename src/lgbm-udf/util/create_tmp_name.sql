--
-- 一時テーブル用にランダムな文字列を生成する
-- 

CREATE OR REPLACE FUNCTION analysis.evwh_create_tmp_name (
)
RETURNS text AS $$
  SELECT 'tmp_' || replace(uuid_in(md5(random()::text || now()::text)::cstring)::text, '-', '')
$$ LANGUAGE SQL VOLATILE;
