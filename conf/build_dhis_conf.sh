#!/bin/sh

#defines a function to output to the standard error
log() {
    echo "$@" 1>&2
}

#if first param is "help" show an help screen
if [ "$1" = "help" ]
then
    echo "Usage: build_dhis_conf.sh [help|build]"
    echo "This script will create a dhis.conf and print to standard output"
    echo "-----------------------------"
    echo "The script will use the following environment variables:"
    echo
    echo "-----------------------------"
    echo "MAIN DATABASE"
    echo "-----------------------------"
    echo
    echo "CONNECTION_DRIVER_CLASS: The driver class to use for the connection, default is org.postgresql.Driver"
    echo "DB_NAME: The name of the database to use for the connection, default is not set"
    echo "URL_DB_HOST: The host of the database to use for the connection, default is localhost (only used if DB_NAME is not set)"
    echo "URL_DB_PORT: The port of the database to use for the connection, default is 5432 (only used if DB_NAME is not set)"
    echo "URL_DB_NAME: The name of the database to use for the connection, default is dhis2 (only used if DB_NAME is not set)"
    echo "CONNECTION_USERNAME: The username to use for the connection, default is dhis"
    echo "CONNECTION_PASSWORD: The password to use for the connection, default is password"
    echo
    echo "-----------------------------"
    echo "ANALYTICS DATABASE"
    echo "-----------------------------"
    echo
    echo "ANALITYCS_CITUS_EXTENSION: The citus extension to use for the analytics database, default is OFF"
    echo "ANALYTICS_DATABASE_ENABLED: If the analytics database is enabled, default is FALSE"
    echo "ANALYTICS_DB_NAME: The name of the analytics database, default is dhis2"
    echo "URL_ANALYTICS_DB_HOST: The host of the analytics database, default is localhost (only used if ANALYTICS_DB_NAME is not set)"
    echo "URL_ANALYTICS_DB_PORT: The port of the analytics database, default is 5432 (only used if ANALYTICS_DB_NAME is not set)"
    echo "URL_ANALYTICS_DB_NAME: The name of the analytics database, default is dhis2 (only used if ANALYTICS_DB_NAME is not set)"
    echo "ANALYTICS_CONNECTION_USERNAME: The username to use for the analytics connection, default is dhis"
    echo "ANALYTICS_CONNECTION_PASSWORD: The password to use for the analytics connection, default is password"
    exit 0
else
  #if first param is not "build" or help, exits
  if [ "$1" != "build" ]
  then
    log "Invalid command. Use 'help' for help or 'build' to build the dhis.conf"
    exit 1
  fi
fi

# creates a temp folder to store the config
TMP_DHIS2_HOME=$(mktemp -d)
TMP_DHIS2_FILES_DIR=$TMP_DHIS2_HOME/files
TMP_DHIS2_LOGS_DIR=$TMP_DHIS2_HOME/logs

DHIS2_CONFIG_FILE=$TMP_DHIS2_HOME/dhis.conf

log "Temp folder created at "$TMP_DHIS2_HOME

# creates config, config/files and config/logs folder under temp
mkdir -p $TMP_DHIS2_HOME
mkdir -p $TMP_DHIS2_FILES_DIR
mkdir -p $TMP_DHIS2_LOGS_DIR

echo "connection.driver_class = "${CONNECTION_DRIVER_CLASS:-org.postgresql.Driver} >> $DHIS2_CONFIG_FILE

if [ -z "$DB_NAME" ]
then
    log "DB_NAME is not set using URL_DB_HOST, URL_DB_PORT and URL_DB_NAME"
    URL_DB_HOST_VAL=${URL_DB_HOST:-localhost}
    URL_DB_PORT_VAL=${URL_DB_PORT:-5432}
    URL_DB_NAME_VAL=${URL_DB_NAME:-dhis2}
    CONNECTION_URL_VAL="jdbc:postgresql://$URL_DB_HOST_VAL:$URL_DB_PORT_VAL/$URL_DB_NAME_VAL"
else
    CONNECTION_URL_VAL="jdbc:postgresql:$DB_NAME"
fi

echo "connection.url = "$CONNECTION_URL_VAL >> $DHIS2_CONFIG_FILE
echo "connection.username = "${CONNECTION_USERNAME:-dhis} >> $DHIS2_CONFIG_FILE
echo "connection.password = "${CONNECTION_PASSWORD:-password} >> $DHIS2_CONFIG_FILE

# setup citus extension if enabled
if [ -z "$ANALITYCS_CITUS_EXTENSION" ]
then
    log "ANALITYCS_CITUS_EXTENSION is not enabled"
else
    log "ANALITYCS_CITUS_EXTENSION is enabled"
    log "Setting up citus extension"
    echo "analytics.citus.extension = "${ANALITYCS_CITUS_EXTENSION:-OFF} >> $DHIS2_CONFIG_FILE
fi

if [ "$ANALYTICS_DATABASE_ENABLED" = "TRUE" ]
then
    log "Setting up analytics database"
    if [ -z "$ANALYTICS_DB_NAME" ]
    then
        log "ANALYTICS_DB_NAME is not set using URL_ANALYTICS_DB_HOST, URL_ANALYTICS_DB_PORT and URL_ANALYTICS_DB_NAME"
        URL_ANALYTICS_DB_HOST_VAL=${URL_ANALYTICS_DB_HOST:-localhost}
        URL_ANALYTICS_DB_PORT_VAL=${URL_ANALYTICS_DB_PORT:-5432}
        URL_ANALYTICS_DB_NAME_VAL=${URL_ANALYTICS_DB_NAME:-dhis2}
        ANALYTICS_CONNECTION_URL_VAL="jdbc:postgresql://$URL_ANALYTICS_DB_HOST_VAL:$URL_ANALYTICS_DB_PORT_VAL/$URL_ANALYTICS_DB_NAME_VAL"
    else
        ANALYTICS_CONNECTION_URL_VAL="jdbc:postgresql:$ANALYTICS_DB_NAME"
    fi
    echo "analytics.connection.url = "$ANALYTICS_CONNECTION_URL_VAL >> $DHIS2_CONFIG_FILE
    echo "analytics.connection.username = "${ANALYTICS_CONNECTION_USERNAME:-dhis} >> $DHIS2_CONFIG_FILE
    echo "analytics.connection.password = "${ANALYTICS_CONNECTION_PASSWORD:-password} >> $DHIS2_CONFIG_FILE
    echo "analytics.citus.extension = "${ANALITYCS_CITUS_EXTENSION:-OFF} >> $DHIS2_CONFIG_FILE
else
    log "Analytics database is not enabled"
fi

# variuos hardcoded values
echo "server.https = off" >> $DHIS2_CONFIG_FILE
echo "server.base.url = http://localhost/" >> $DHIS2_CONFIG_FILE
echo "tracker.import.preheat.cache.enabled = off" >> $DHIS2_CONFIG_FILE

# print the dhis.conf to standard error
log
log "dhis.conf created at "$TMP_DHIS2_HOME
log
log "######################################################################################"
cat $DHIS2_CONFIG_FILE 1>&2
log "######################################################################################"
log
#return the path to the dhis.conf
log
log "return value for the caller: "$TMP_DHIS2_HOME
log
echo $TMP_DHIS2_HOME



