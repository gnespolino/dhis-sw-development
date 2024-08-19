#!/bin/bash
export project_root=$DHIS_DEV_HOME/sw
echo $project_root
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
mvn spotless:apply -f $project_root/dhis-2/pom.xml 
mvn spotless:apply -f $project_root/dhis-2/dhis-test-e2e/pom.xml
