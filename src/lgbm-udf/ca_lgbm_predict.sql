--
-- LightGBM: prediction with trained model
--

CREATE OR REPLACE FUNCTION analysis.ca_lgbm_predict (
  output_table text,
  output_mode text,
  model_table_name text,
  transaction_table_name text,
  param_json text
) RETURNS text
AS $$
DECLARE
  _output_table text;
  _program_path text = '/path/to/lgbm_predict.sh';
  _current_database text;
BEGIN

  -- Create output table if not exists
  _output_table := analysis.evwh_check_table(output_table, output_mode);
  IF (SELECT NOT analysis.evwh_has_table(_output_table)) THEN
    EXECUTE '
      CREATE TABLE ' || analysis.evwh_quote_ident(_output_table) || ' (
        start_datetime timestamp with time zone,
        end_datetime timestamp with time zone,
        location geometry,
        exec_time timestamp with time zone,
        area_id integer,
        ox_value double precision,
        ox_level integer,
        probability double precision,
        ox_max double precision,
        ox_min double precision
      )
      DISTRIBUTED RANDOMLY
    ';
    EXECUTE '
      ALTER TABLE ' || _output_table || ' OWNER TO ' || session_user || '
    ';
  END IF;

  -- Get current database name
  _current_database := current_database();

  -- Execute external program and write results into the output table
  EXECUTE '
    COPY ' || _output_table || ' (
      start_datetime,
      end_datetime,
      location,
      exec_time,
      area_id,
      ox_value,
      ox_level,
      probability,
      ox_max,
      ox_min
    )

    FROM PROGRAM '''
      || _program_path
      || ' ' || model_table_name
      || ' ' || transaction_table_name
      || ' "' || replace(param_json, '"', '\"') || '"'
      || ' ' || _current_database
      || ''' CSV;';

  -- Return output table name
  return _output_table;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
