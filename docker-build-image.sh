#!/usr/bin/env sh
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

docker build -t tmcw/mpur:0.6-1 -t tmcw/mpur:latest .
