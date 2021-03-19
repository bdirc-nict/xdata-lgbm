--
-- LightGBM: model training
--

CREATE OR REPLACE FUNCTION analysis.ca_lgbm_train (
  output_table text,
  output_mode text,
  transaction_table_name text,
  param_json text
) RETURNS text
AS $$
DECLARE
  _output_table text;
  _program_path text = '/path/to/lgbm_train.sh';
  _current_database text;
BEGIN

  -- Check output mode
  IF output_mode = 'append' THEN
    RAISE EXCEPTION 'append mode is not supported in the crnn model creation';
  END IF;
  _output_table := analysis.evwh_check_table(output_table, output_mode);

  -- Create output table
  EXECUTE '
    CREATE TABLE ' || _output_table || ' (
      method text,
      train_data text,
      param_json text,
      model_kind text,
      location_code text,
      target text,
      rank_time integer,
      prediction_rank integer,
      change_time integer,
      model_path text
    )
    DISTRIBUTED RANDOMLY
  ';
  EXECUTE '
    ALTER TABLE ' || _output_table || ' OWNER TO ' || session_user || '
  ';

  -- Get current database name
  _current_database := current_database();

  -- Execute external program and write results into the output table
  EXECUTE '
    COPY ' || _output_table || ' (
      method,
      train_data,
      param_json,
      model_kind,
      location_code,
      target,
      rank_time,
      prediction_rank,
      change_time,
      model_path
    )
    FROM PROGRAM '''
      || _program_path
      || ' ' || transaction_table_name
      || ' "' || replace(param_json, '"', '\"') || '"'
      || ' ' || _current_database
      || ''' CSV DELIMITER E''\t'' QUOTE E''\b'' HEADER'; -- Use '\b' as dummy quote character

  -- Return output table name
  return _output_table;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
