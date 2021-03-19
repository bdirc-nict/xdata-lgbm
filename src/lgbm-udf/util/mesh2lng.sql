--
-- 地域メッシュコードから経度を計算する
--

CREATE OR REPLACE FUNCTION analysis.evwh_mesh2lng (
  meshcode text
)
RETURNS double precision AS $$
DECLARE
  x1 integer;
  x2 integer;
  x3 integer;
  x4 integer;
  x5 integer;
  lng double precision;
BEGIN

  IF NOT analysis.evwh_is_valid_meshcode(meshcode) THEN
    -- RAISE EXCEPTION 'Invalid meshcode';
    RETURN NULL;
  END IF;

x1 := substr(meshcode, 3, 2)::integer;
  lng := (x1 + 100) * 320;
  IF length(meshcode) < 6 THEN
    RETURN (lng + 160) / 320.0;
  END IF;

  x2 := substr(meshcode, 6, 1)::integer;
  lng := lng + x2 * 40;
  IF length(meshcode) < 8 THEN
    RETURN (lng + 20) / 320.0;
  END IF;

  x3 := substr(meshcode, 8, 1)::integer;
  lng := lng + x3 * 4;
  IF length(meshcode) < 9 THEN
    RETURN (lng + 2) / 320.0;
  END IF;

  x4 := substr(meshcode, 9, 1)::integer;
  x4 := 1 - x4 % 2;
  lng := lng + x4 * 2;
  IF length(meshcode) < 10 THEN
    RETURN (lng + 1) / 320.0;
  END IF;

  x5 := substr(meshcode, 10, 1)::integer;
  x5 := 1 - x5 % 2;
  lng := lng + x5;

  RETURN (lng + 0.5) / 320.0;

END;
$$ LANGUAGE plpgsql;

-- 後方互換性のための定義

CREATE OR REPLACE FUNCTION analysis.mesh2lng (
  meshcode varchar
)
RETURNS double precision AS $$
DECLARE
  lng double precision;
BEGIN
  SELECT analysis.evwh_mesh2lng(meshcode::text) INTO lng;
  RETURN lng;
END;
$$ LANGUAGE plpgsql;
