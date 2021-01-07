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
ambit_sql_data_import="file://${ambit_base}/data_import"

declare -a procedure_list=(
    'findByProperty'
    'deleteDataset'
    'createBundleCopy'
    'createBundleVersion'
)

declare -A db_import_list=(
    ['echa_substance_food']="${ambit_sql_data_import}/echa_substance_food.sql.xz"
    ['nanoreg1']='https://zenodo.org/record/3467016/files/nanoreg_nrfiles.sql.xz'
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

if [[ ! -d ${mysql_datadir}/mysql && ( -z ${1} || ${1:0:1} = '-' ) ]]; then

    # Create the AMBIT user and the AMBIT users database.
    {
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
    echo '[Entrypoint AMBIT] Fetching well-known public databases if necessary...'
    for ambit_db in ${ambit_databases}; do
        # The well-known DB names (e.g. "nanoreg") should be keys in the associative array
        # ${db_import_list}, with the URI to fetch the (compressed) SQL from as value.
        set +o nounset
        if [[ ${db_import_list[${ambit_db}]} ]]; then
            import_source="${db_import_list[${ambit_db}]}"
            echo "USE \`${ambit_db}\`;"
            if [[ ${import_source%:*} = 'file' ]]; then
                import_file="${import_source#file://}"
                if [[ ! -r ${import_file} ]]; then
                    echo "ERROR: Missing import data file: ${import_file}" >/dev/stderr
                    exit 70
                else
                    xzcat "${import_file}"
                fi
            else
                curl -s "${import_source}" | xzcat
            fi
        fi
        set -o nounset
    done >"${initdb_d_populate_databases}"


    # Clean up.
    rm -r "${ambit_tmp}"


# End the initialization "if" block.
fi


# Switch to the upstream Docker image entrypoint script.
exec /usr/local/bin/docker-entrypoint.sh "$@"


# vim: set ts=4 sts=4 sw=4 tw=100 et:
