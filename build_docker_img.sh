#!/usr/bin/env sh
time docker build -t cbtm docker/. --output type=tar,dest=cbtm.tar
