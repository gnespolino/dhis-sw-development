docker exec -it docker-worker-1 psql -c "SELECT run_command_on_workers(\$cmd\$ CREATE DATABASE dhis WITH OWNER dhis ENCODING 'UTF8' \$cmd\$);"
docker exec -it docker-worker-1 psql -c "GRANT ALL PRIVILEGES ON DATABASE dhis TO dhis;"
docker exec -it docker-worker-1 psql dhis -c "create extension citus;"
docker exec -it docker-worker-1 psql dhis -c "create extension postgis;"
docker exec -i docker-worker-1 psql dhis -U dhis <dhis2-db-sierra-leone.sql
