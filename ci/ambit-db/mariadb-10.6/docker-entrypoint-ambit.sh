#!/usr/bin/env bash
set -o noclobber
set -o errexit
set -o pipefail
set -o nounset


ambit_db_user="${AMBIT_DB_USER:-ambit}"
ambit_db_pass="${AMBIT_DB_PASS:-ambit}"
ambit_users_db="${AMBIT_USERS_DB:-ambit_users}"
ambit_databases="${AMBIT_DATABASES:-ambit}"

ambit_base='/opt/ambit'
ambit_tmp="${ambit_base}/tmp"
ambit_sql_tables="${ambit_tmp}/create_tables.sql"
ambit_sql_users="${ambit_tmp}/users.sql"
ambit_sql_data_import="${ambit_base}/data_import"

declare -a procedure_list=(
    'findByProperty'
    'deleteDataset'
    'createBundleCopy'
    'createBundleVersion'
)

declare -A public_db_import_urls=(
    ['calibrate']='https://sandbox.zenodo.org/record/1114164/files/calibrate.sql.xz'
    ['nanoreg1']='https://zenodo.org/record/3467016/files/nanoreg_nrfiles.sql.xz'
    ['nanoreg2']='https://zenodo.org/record/4713745/files/nanoreg2.sql.xz'
)

initdb_d_base='/docker-entrypoint-initdb.d'
initdb_d_init_databases="${initdb_d_base}/00-init-databases.sql"
initdb_d_create_ambit_tables="${initdb_d_base}/01-create-ambit-tables.sql"
initdb_d_create_ambit_user_tables="${initdb_d_base}/02-create-ambit-user-tables.sql"
initdb_d_init_procedure_grants="${initdb_d_base}/03-init-procedure-grants.sql"
initdb_d_populate_databases="${initdb_d_base}/04-populate-databases.sql"


# Run the initialization process if both are true:
#   * the initialization has not already been performed;
#   * no custom command is passed or it's only an option for MariaDB/MySQL.

mysql_datadir="$(mysqld --verbose --help --log-bin-index=/dev/null 2>/dev/null \
    | awk '/^datadir[[:blank:]]/ { print $2 }')"

if [[ ! -d ${mysql_datadir}mysql && ( -z ${1} || ${1:0:1} = '-' ) ]]; then

    # Create the AMBIT user and the AMBIT users database.
    # FIXME: We also need the 'guest'@'localhost' user.
    guest_pass="$(openssl rand -base64 32)"
    {
        echo "CREATE USER 'guest'@'localhost' IDENTIFIED BY '${guest_pass}';"
        echo "CREATE USER '${ambit_db_user}'@'%' IDENTIFIED BY '${ambit_db_pass}';"
        echo "CREATE DATABASE \`${ambit_users_db}\` CHARACTER SET utf8;"
        echo "GRANT ALL ON \`${ambit_users_db}\`.* TO '${ambit_db_user}'@'%';"
    } >"${initdb_d_init_databases}"


    # Create the AMBIT database(s) and the associated grants.
    for ambit_db in ${ambit_databases}; do
        echo "CREATE DATABASE  \`${ambit_db}\` CHARACTER SET utf8;"
        echo "GRANT ALL     ON \`${ambit_db}\`.* TO '${ambit_db_user}'@'%';"
        echo "GRANT TRIGGER ON \`${ambit_db}\`.* TO '${ambit_db_user}'@'%';"
    done >>"${initdb_d_init_databases}"


    # Initialize the AMBIT databases.
    for ambit_db in ${ambit_databases}; do
        echo "USE \`${ambit_db}\`;"
        cat "${ambit_sql_tables}"
    done >"${initdb_d_create_ambit_tables}"


    # Initialize the AMBIT users database.
    {
        echo "USE \`${ambit_users_db}\`;"
        sed 's|"/ambit2"|"/ambit"|g' "${ambit_sql_users}"
    } >"${initdb_d_create_ambit_user_tables}"


    # Set up the execute procedure grants.
    for ambit_db in ${ambit_databases}; do
        for procedure in "${procedure_list[@]}"; do
            echo "GRANT EXECUTE ON PROCEDURE \`${ambit_db}\`.${procedure} TO '${ambit_db_user}'@'%';"
        done
    done >"${initdb_d_init_procedure_grants}"


    # If well-known public databases are defined, populate them.
    echo '[Entrypoint AMBIT] Populating databases...'
    for ambit_db in ${ambit_databases}; do
        set +o nounset
        if [[ -r ${ambit_sql_data_import}/${ambit_db}.sql.xz ]]; then
            set -o nounset
            echo "USE \`${ambit_db}\`;"
            xzcat "${ambit_sql_data_import}/${ambit_db}.sql.xz"
        # Well-known DB names (e.g. "nanoreg1") could be set as keys in the associative array
        # ${public_db_import_urls}, with the URI to fetch the (compressed) SQL from as value.
        elif [[ ${public_db_import_urls[${ambit_db}]} ]]; then
            set -o nounset
            import_url="${public_db_import_urls[${ambit_db}]}"
            echo "USE \`${ambit_db}\`;"
            curl -s "${import_url}" | xzcat
        else
            set -o nounset
            echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *" >/dev/stderr
            echo >/dev/stderr
            echo "WARNING: Missing SQL import file for database \"${ambit_db}\"" >/dev/stderr
            echo >/dev/stderr
            echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *" >/dev/stderr
        fi
    done >"${initdb_d_populate_databases}"


    # Clean up.
    rm -r "${ambit_tmp}"


# End the initialization "if" block.
fi


# Switch to the upstream Docker image entrypoint script.
exec /usr/local/bin/docker-entrypoint.sh "$@"
