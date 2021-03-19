--
-- 緯度と経度から地域メッシュコードを計算する
--

CREATE OR REPLACE FUNCTION analysis.evwh_loc2mesh (
  lat double precision,
  lng double precision,
  n integer = 5
)
RETURNS text AS $$
DECLARE
  y integer;
  y1 integer;
  y2 integer;
  y3 integer;
  y4 integer;
  y5 integer;
  x integer;
  x1 integer;
  x2 integer;
  x3 integer;
  x4 integer;
  x5 integer;
  c4 integer;
  c5 integer;
  ret text;
BEGIN

  IF NOT (20 <= lat AND lat < 46) THEN
    -- RAISE EXCEPTION 'Latitude must be 20 <= lat < 46, but %', lat;
    RETURN NULL;
  END IF;

  IF NOT (122 <= lng AND lng < 154) THEN
    -- RAISE EXCEPTION 'Longitude must be 122 <= lng < 154, but %', lng;
    RETURN NULL;
  END IF;

  IF NOT n BETWEEN 1 AND 5 THEN
    -- RAISE EXCEPTION 'n must be 1 <= n <= 5, but %', n;
    RETURN NULL;
  END IF;

  y := floor(lat * 480)::integer; -- lat * (3/2) * 320
  y1 := y / 320;
  y2 := (y % 320) / 40;
  y3 := (y % 40) / 4;
  y4 := (y % 4) / 2;
  y5 := y % 2;

  x := floor((lng - 100) * 320)::integer;
  x1 := x / 320;
  x2 := (x % 320) / 40;
  x3 := (x % 40) / 4;
  x4 := (x % 4) / 2;
  x5 := x % 2;

  c4 := y4 * 2 + x4 + 1;
  c5 := y5 * 2 + x5 + 1;

  ret := (y1::text || x1::text || y2::text || x2::text || y3::text || x3::text || c4::text || c5::text);

  IF n = 1 THEN
    ret := substring(ret, 1, 4);
  ELSIF n = 2 THEN
    ret := substring(ret, 1, 6);
  ELSIF n = 3 THEN
    ret := substring(ret, 1, 8);
  ELSIF n = 4 THEN
    ret := substring(ret, 1, 9);
  END IF;

  RETURN ret;

END;
$$ LANGUAGE plpgsql;

-- 後方互換性のための定義

CREATE OR REPLACE FUNCTION analysis.loc2mesh (
  lat double precision,
  lng double precision
)
RETURNS varchar AS $$
DECLARE
  ret text;
BEGIN
  SELECT analysis.evwh_loc2mesh(lat, lng) INTO ret;
  RETURN ret::varchar;
END;
$$ LANGUAGE plpgsql;
