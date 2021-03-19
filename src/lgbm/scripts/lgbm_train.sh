#!/bin/bash

BASEDIR=$(cd $(dirname $0)/.. && pwd)

SOURCEDIR=$BASEDIR/CRNN_API
DATADIR=$BASEDIR/data
SCRIPTDIR=$BASEDIR/scripts

INPUTDIR=$DATADIR/csvs
OUTPUTDIR=$DATADIR/csvs
MODELDIR=$DATADIR/model

source $SCRIPTDIR/lgbm_common.sh

table_name=$1
transaction_csv_file=$2
param_json=$3
result_csv_file=$4

# Read parameters using jq (temporal solution)

JQ=${HOME}/bin/jq

test_date=$(echo $param_json | $JQ -r '.test_date')
rank_time=$(echo $param_json | $JQ -r '.rank_time')
change_time=$(echo $param_json | $JQ -r '.change_time')
min_rank=$(echo $param_json | $JQ -r '.min_rank')
max_rank=$(echo $param_json | $JQ -r '.max_rank')
area_name=$(echo $param_json | $JQ -r '.area_name')

echo "Server Param Check"
echo "--input_csv=$INPUTDIR/$transaction_csv_file"
echo "--table=$table_name"
echo "--test_date=\"$test_date\""
echo "--rank_time=$rank_time"
echo "--change_time=$change_time"
echo "--Min_rank=$min_rank"
echo "--Max_rank=$max_rank"
echo "--area-name=$area_name"
echo "param_json=$param_json"
echo "result_csv_file=$result_csv_file"

echo "BEGIN: $(date +"%F %T")"

(
  cd $SOURCEDIR

  python3 $SOURCEDIR/ForOzone/lgbm_train.py \
    --input_csv $INPUTDIR/$transaction_csv_file \
    --table $table_name \
    --test_date "$test_date" \
    --rank_time $rank_time \
    --change_time $change_time \
    --Min_rank $min_rank \
    --Max_rank $max_rank \
    --area-name $area_name \
    --json-params "$param_json" \
    --output $OUTPUTDIR/$result_csv_file
)

echo "END: $(date +"%F %T")"
