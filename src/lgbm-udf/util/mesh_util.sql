--
-- mesh type から mesh テーブルの名前を生成する
--

CREATE OR REPLACE FUNCTION analysis.evwh_get_meshtbl_name (
  mesh_type text
)
RETURNS text AS $$
DECLARE
  mesh_table text;
BEGIN
  IF mesh_type = '5' THEN
    mesh_table = 'analysis.jisx0410_mesh5';
  ELSE
    RETURN NULL;
  END IF;

  RETURN mesh_table;

END
$$ LANGUAGE plpgsql;
