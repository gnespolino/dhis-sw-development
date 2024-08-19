#!/bin/bash
docker inspect --format='{{.Name}}' $(docker ps -q --no-trunc) | grep "dhis" | cut -c2-
