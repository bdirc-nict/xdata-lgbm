--
-- メッシュコードが正しい値を持っているかを判定する
--

CREATE OR REPLACE FUNCTION analysis.evwh_is_valid_meshcode(
  meshcode text
)
RETURNS boolean AS $$
DECLARE
  len integer;
  val integer;
BEGIN

  IF meshcode IS NULL THEN
    RETURN FALSE;
  END IF;

  len := length(meshcode);

  IF len NOT IN (4, 6, 8, 9, 10) THEN
    RETURN FALSE;
  END IF;

  IF meshcode !~ '\A\d+\Z' THEN
    RETURN FALSE;
  END IF;

  val := substr(meshcode, 1, 2)::integer;
  IF NOT val BETWEEN 30 AND 68 THEN
    RETURN FALSE;
  END IF;

  val := substr(meshcode, 3, 2)::integer;
  IF NOT val BETWEEN 22 AND 53 THEN
    RETURN FALSE;
  END IF;

  IF len = 4 THEN
    RETURN TRUE;
  END IF;

  val := substr(meshcode, 5, 1)::integer;
  IF NOT val BETWEEN 0 AND 7 THEN
    RETURN FALSE;
  END IF;

  val := substr(meshcode, 6, 1)::integer;
  IF NOT val BETWEEN 0 AND 7 THEN
    RETURN FALSE;
  END IF;

  IF len IN (6, 8) THEN
    RETURN TRUE;
  END IF;

  val := substr(meshcode, 9, 1)::integer;
  IF NOT val BETWEEN 1 AND 4 THEN
    RETURN FALSE;
  END IF;

  IF len = 9 THEN
    RETURN TRUE;
  END IF;

  val := substr(meshcode, 10, 1)::integer;
  IF NOT val BETWEEN 1 AND 4 THEN
    RETURN FALSE;
  END IF;

  RETURN TRUE;

END;
$$ LANGUAGE plpgsql VOLATILE;
