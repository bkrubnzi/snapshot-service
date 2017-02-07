#!/bin/bash

if [ $1 = "1" ];then
        echo "stdout"
else
        (>&2 echo "stderr")
fi
