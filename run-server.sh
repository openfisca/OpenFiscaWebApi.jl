#!/bin/bash

while true; do
  echo "=== Loading server…"
  julia start_app.jl &
  PID=$!
  inotifywait -r -e modify -e close_write -e create -e delete src
  echo "=== File changed, killing server…"
  kill -SIGINT $PID
  echo -e "\n\n\n\n\n\n"
done
