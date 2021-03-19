--
-- LightGBM: model evaluation
--

CREATE OR REPLACE FUNCTION analysis.ca_lgbm_evaluate (
  output_table text,
  output_mode text,
  transaction_table_name text,
  param_json text
) RETURNS text
AS $$
DECLARE
  _output_table text;
  _program_path text = '/path/to/lgbm_evaluate.sh';
  _current_database text;
BEGIN

  -- Create output table if not exists
  _output_table := analysis.evwh_check_table(output_table, output_mode);
  IF (SELECT NOT analysis.evwh_has_table(_output_table)) THEN
    EXECUTE '
      CREATE TABLE ' || analysis.evwh_quote_ident(_output_table) || ' (
        dummy text
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
      dummy
    )
    FROM PROGRAM '''
      || _program_path
      || ' ' || transaction_table_name
      || ' "' || replace(param_json, '"', '\"') || '"'
      || ' ' || _current_database
      || ''' CSV;';

  -- Return output table name
  return _output_table;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
