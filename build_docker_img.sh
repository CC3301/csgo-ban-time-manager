#!/usr/bin/env sh
time docker build -t cbtm docker/.
time docker save cbtm -o cbtm.tar
