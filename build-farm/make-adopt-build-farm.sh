#!/bin/sh
echo SXAEC $PWD: Executing docker run -t -v `pwd`:`pwd` -w `pwd` bash ${0}.1 "$@"
exec docker run -t -v `pwd`:`pwd` -w `pwd` demo_build_image bash ${0}.1 "$@"
