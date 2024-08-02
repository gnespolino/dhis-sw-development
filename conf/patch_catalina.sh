#!/bin/sh

# if first param is "not patch nor revert" show an help screen
if [ "$1" != "patch" ] && [ "$1" != "revert" ]
then
  echo "Usage: patch_catalina.sh [patch|revert]"
  echo "This script will patch the catalina.sh file to use the DHIS2_HOME folder"
  echo "-----------------------------"
  echo "The script will use the following environment variables:"
  echo
  echo "-----------------------------"
  echo "DHIS_DEV_HOME: The path to the dhis-sw-development folder, default is ~/dhis-sw-development/"
  exit 1
fi

CATALINA_FOLDER=${DHIS_DEV_HOME-~/dhis-sw-development}/apache-tomcat/current

#if the catalina folder does not exist, exits
if [ ! -d "$CATALINA_FOLDER" ]
then
  echo "Catalina folder not found at $CATALINA_FOLDER"
  exit 1
fi

# if param is "revert" it undoes the patch
if [ "$1" = "revert" ]
then
  #checks if catalina.sh contains "# MARKER"
  if grep -q "# MARKER" $CATALINA_FOLDER/bin/catalina.sh
  then
    #removes the lines between # MARKER and # END_MARKER
    sed -i '/# MARKER/,/# END_MARKER/d' $CATALINA_FOLDER/bin/catalina.sh
    echo "Catalina reverted"
    exit 0
  else
    echo "Catalina not patched"
    exit 1
  fi
fi

#checks if catalina.sh contains "# MARKER"
if grep -q "# MARKER" $CATALINA_FOLDER/bin/catalina.sh
then
  echo "Catalina already patched"
  exit 0
fi

#creates a backup of the original catalina.sh
cp $CATALINA_FOLDER/bin/catalina.sh $CATALINA_FOLDER/bin/catalina.sh.bak

#adds code snippet starting at line 2 of the catalina.sh
sed -i '3i# MARKER' $CATALINA_FOLDER/bin/catalina.sh
sed -i '4iDHIS2_HOME=$(source $DHIS_DEV_HOME/conf/build_dhis_conf.sh build)' $CATALINA_FOLDER/bin/catalina.sh
sed -i '5iecho "USING $DHIS2_HOME as DHIS2_HOME folder"' $CATALINA_FOLDER/bin/catalina.sh
sed -i '6i# END_MARKER' $CATALINA_FOLDER/bin/catalina.sh

echo "Catalina patched"
exit 0


