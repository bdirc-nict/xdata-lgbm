--
-- 地域メッシュコードから緯度を計算する
--

CREATE OR REPLACE FUNCTION analysis.evwh_mesh2lat (
  meshcode text
)
RETURNS double precision AS $$
DECLARE
  y1 integer;
  y2 integer;
  y3 integer;
  y4 integer;
  y5 integer;
  lat double precision;
BEGIN

  IF NOT analysis.evwh_is_valid_meshcode(meshcode) THEN
    -- RAISE EXCEPTION 'Invalid meshcode';
    RETURN NULL;
  END IF;

  y1 := substr(meshcode, 1, 2)::integer;
  lat := y1 * 320;
  IF length(meshcode) < 6 THEN
    RETURN (lat + 160) / 480.0;
  END IF;

  y2 := substr(meshcode, 5, 1)::integer;
  lat := lat + y2 * 40;
  IF length(meshcode) < 8 THEN
    RETURN (lat + 20) / 480.0;
  END IF;

  y3 := substr(meshcode, 7, 1)::integer;
  lat := lat + y3 * 4;
  IF length(meshcode) < 9 THEN
    RETURN (lat + 2) / 480.0;
  END IF;

  y4 := substr(meshcode, 9, 1)::integer;
  y4 := (y4 - 1) / 2;
  lat := lat + y4 * 2;
  IF length(meshcode) < 10 THEN
    RETURN (lat + 1) / 480.0;
  END IF;

  y5 := substr(meshcode, 10, 1)::integer;
  y5 := (y5 - 1) / 2;
  lat := lat + y5;

  RETURN (lat + 0.5) / 480.0;

END;
$$ LANGUAGE plpgsql;

-- 後方互換性のための定義

CREATE OR REPLACE FUNCTION analysis.mesh2lat (
  meshcode varchar
)
RETURNS double precision AS $$
DECLARE
  lat double precision;
BEGIN
  SELECT analysis.evwh_mesh2lat(meshcode::text) INTO lat;
  RETURN lat;
END;
$$ LANGUAGE plpgsql;
