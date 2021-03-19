--
-- geometry 型を持つテーブルに対して，与えられた mesh との intersection をとったテーブルを生成する
--

CREATE OR REPLACE FUNCTION analysis.evwh_geomtbl2meshtbl (
  source_table_name text,
  source_id_column text,
  source_geom_column text,
  mesh_type text,
  result_table_name text,
  is_temporal bool
)
RETURNS text AS $$
DECLARE
  query text;
  mesh_table text;
  trimed_tbl text;
  retval text;
BEGIN
  IF NOT ( analysis.evwh_is_valid_table_name(source_table_name, TRUE) ) THEN
    RETURN NULL;
  END IF;
  IF NOT ( analysis.evwh_is_valid_table_name(result_table_name, NOT is_temporal) ) THEN
    RETURN NULL;
  END IF;
  IF NOT ( analysis.evwh_is_valid_column_name(source_id_column) ) THEN
    RETURN NULL;
  END IF;
  IF NOT ( analysis.evwh_is_valid_column_name(source_geom_column) ) THEN
    RETURN NULL;
  END IF;
  mesh_table = analysis.evwh_get_meshtbl_name(mesh_type);
  IF mesh_table IS NULL THEN
    RETURN NULL;
  END IF;

  EXECUTE 'DROP TABLE IF EXISTS ' || result_table_name;

  query := 'CREATE ';
  IF is_temporal THEN
    query := query || 'TEMPORARY ';
  END IF;
  query := query || 'TABLE ' || result_table_name || ' AS ';
  query := query || 'SELECT s.' || source_id_column || ' id, m.code code ';
  query := query || 'FROM ' || source_table_name || ' s, ' || mesh_table || ' m ';
  query := query || 'WHERE ST_Intersects(s.' || source_geom_column || ', m.geom) ';
  query := query || 'DISTRIBUTED BY ( code ) ';
  EXECUTE query;

  trimed_tbl := substr( analysis.evwh_trim_schema_name(result_table_name), 1, 57);
  EXECUTE 'CREATE INDEX idx_' || trimed_tbl || '_1 ON ' || result_table_name || ' ( id )';
  EXECUTE 'CREATE INDEX idx_' || trimed_tbl || '_2 ON ' || result_table_name || ' ( code )';

  RETURN result_table_name;

END
$$ LANGUAGE plpgsql;
