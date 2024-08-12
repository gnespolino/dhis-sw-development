#!/bin/bash

# se il ruolo è master
if [ "$ROLE" == "master" ]; then
  psql </tmp/script.sql >/dev/null 2>&1
fi

# helps shutting down the database gracefully
sleep 2

rm /tmp/script.sql
