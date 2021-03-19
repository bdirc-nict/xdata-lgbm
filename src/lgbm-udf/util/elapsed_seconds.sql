--
-- 指定された基準からの経過秒数を取得する
--

CREATE OR REPLACE FUNCTION analysis.evwh_elapsed_seconds (
  datetime timestamp with time zone,
  unit text = NULL
)
RETURNS integer AS $$
DECLARE
  retval integer;
  l_unit text := lower(unit);
BEGIN

  IF l_unit IN (
    'minute',
    'hour',
    'day',
    'week',
    'month',
    'quarter',
    'year',
    'decade',
    'century',
    'millennium'
  ) THEN
    SELECT extract(epoch from (datetime - date_trunc(l_unit, datetime))) INTO retval;
  ELSE
    IF l_unit IS NOT NULL THEN
      -- RAISE EXCEPTION 'Unknown unit (%)', unit;
      RETURN NULL;
    END IF;
    SELECT extract(epoch from datetime) INTO retval;
  END IF;

  RETURN retval;

END;
$$ LANGUAGE plpgsql;

