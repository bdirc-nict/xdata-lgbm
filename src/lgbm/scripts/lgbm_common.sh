#!/bin/bash

export PATH=/home/crnn/cuda-10.1/bin:$PATH
export LD_LIBRARY_PATH=/home/crnn/cuda-10.1/lib64:$LD_LIBRARY_PATH
export CPATH=/home/crnn/cuda-10.1/include:$CPATH
export LIBRARY_PATH=/home/crnn/cuda-10.1/lib64:$LIBRARY_PATH
export LANG=en_US.UTF-8

VENVPATH=$(cd $(dirname $0)/../venv && pwd)
source $VENVPATH/bin/activate

export CRNN_API=$(cd $(dirname $0)/../CRNN_API && pwd)
export PYTHONPATH=$CRNN_API:$PYTHONPATH
