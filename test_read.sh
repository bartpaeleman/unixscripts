#!/bin/bash
if bash -c 'read -e -i "test" -t 0.1' 2>/dev/null; then
  echo "yes"
else
  echo "no"
fi
