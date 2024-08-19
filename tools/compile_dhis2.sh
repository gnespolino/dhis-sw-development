#!/bin/bash -x
BASE_PATH="$DHIS_DEV_HOME/sw/dhis-2"

mvn -f $BASE_PATH/pom.xml clean install -DskipTests

notify-send "DONE!" "Backend build complete!"
