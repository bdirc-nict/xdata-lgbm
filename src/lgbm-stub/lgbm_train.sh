#!/bin/bash

BASEDIR=$(cd $(dirname $0) && pwd)
CSVDIR=$BASEDIR/csvs
LOGDIR=$BASEDIR/logs
LOGFILE=$LOGDIR/$(basename $0 .sh)-$(date +"%Y%m%d-%H%M%S").log

if [ -f "$BASEDIR/lgbm_config" ]; then
  . $BASEDIR/lgbm_config
else
  . $BASEDIR/lgbm_config.in
fi

transaction_table_name=$1
param_json=$2

DBNAME=$3

transaction_csv_base=$(uuidgen).csv
transaction_csv_remote_path=$REMOTE_DIR/data/csvs/$transaction_csv_base
transaction_csv_local_path=$CSVDIR/$transaction_csv_base

result_csv_base=$(uuidgen).csv
result_csv_remote_path=$REMOTE_DIR/data/csvs/$result_csv_base
result_csv_local_path=$CSVDIR/$result_csv_base

touch $LOGFILE
chmod 664 $LOGFILE

(
  psql $DBNAME -c "
    SELECT
      start_datetime,
      end_datetime,
      location,
      so2,
      no,
      no2,
      nox,
      co,
      ox,
      nmhc,
      ch4,
      thc,
      spm,
      \"pm2.5\",
      sp,
      wd,
      ws,
      temp,
      hum,
      st_x,
      st_y,
      station_id
      -- *,
      -- ST_X(ST_Centroid(location)) AS lon,
      -- ST_Y(ST_Centroid(location)) AS lat
    FROM
      $transaction_table_name
    ORDER BY
      start_datetime,
      station_id
      -- lon,
      -- lat
  " -A -F',' | head -n -1 >$transaction_csv_local_path

  scp $transaction_csv_local_path $REMOTE_HOST:$transaction_csv_remote_path
  rm $transaction_csv_local_path

  ssh -tt $REMOTE_HOST "$SLURM_CMD $REMOTE_DIR/scripts/lgbm_train.sh \
    $transaction_table_name \
    $transaction_csv_base \
    '$param_json' \
    $result_csv_base"

  scp $REMOTE_HOST:$result_csv_remote_path $result_csv_local_path
  ssh $REMOTE_HOST rm $transaction_csv_remote_path $result_csv_remote_path
) >>$LOGFILE 2>&1

cat $result_csv_local_path
rm $result_csv_local_path
