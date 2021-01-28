#!/bin/bash
CMD=$1

case $CMD in
  (start)
    echo "Starting the web server on port [$WEBSERVER_PORT]"
    exec python -m SimpleHTTPServer $WEBSERVER_PORT
    ;;
  (*)
    echo "Don't understand [$CMD]"
    ;;
esac