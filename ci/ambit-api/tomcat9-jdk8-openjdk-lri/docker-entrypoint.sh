#!/usr/bin/env bash
set -o noclobber
set -o errexit
set -o pipefail
set -o nounset


ambit_internal_config_dir='WEB-INF/classes/ambit2/rest/config'
ambit2_props_file="${ambit_internal_config_dir}/ambit2.pref"
config_props_file="${ambit_internal_config_dir}/config.prop"
tomcat_webapps_dir='/usr/local/tomcat/webapps'
ambit_deploy_dir="${tomcat_webapps_dir}/tool3"
ambit_war="${ambit_deploy_dir}.war"

ambit_profile="${AMBIT_PROFILE:-enanomapper}"
ambit_database="${AMBIT_DATABASE:-ambit}"
ambit_db_host="${AMBIT_DB_HOST:-db}"
ambit_db_user="${AMBIT_DB_USER:-ambit}"
ambit_db_pass="${AMBIT_DB_PASS:-ambit}"
ambit_aa_enable="${AMBIT_AA_ENABLE:-false}"
ambit_users_db="${AMBIT_USERS_DB:-ambit_users}"

declare -A ambit2_props=(
    ['ambit.profile']="${ambit_profile}"
    ['Database']="${ambit_database}"
    ['Host']="${ambit_db_host}"
    ['User']="${ambit_db_user}"
    ['Password']="${ambit_db_pass}"
)

declare -A config_props=(
    ['aa.db.enabled']="${ambit_aa_enable}"
    ['Database']="${ambit_users_db}"
    ['Host']="${ambit_db_host}"
    ['User']="${ambit_db_user}"
    ['Password']="${ambit_db_pass}"
    ['secret']="$(tr -cd '[:alnum:]' </dev/urandom | head -c 16)"
)


# Run the initialization process if both are true:
#   * the initialization has not already been performed;
#   * no custom command is passed or it's only an option for Tomcat.
# The first condition is checked by simply looking if ambit.war has already been deployed.

if [[ ${1} = 'catalina.sh' && ! -d ${ambit_deploy_dir} ]]; then

    echo '[Entrypoint] Setting up AMBIT...'

    # Do the job in a temporary directory.
    tmp_dir="$(mktemp -d)" && cd "${tmp_dir}"

    # Extract the config files that we need to "patch".
    jar -xf "${ambit_war}" "${ambit2_props_file}" "${config_props_file}"

    # Update the configuration by "patching" the files.
    for key in "${!ambit2_props[@]}"; do
        sed "s|^${key}=.*|${key}=${ambit2_props[$key]}|" -i "${ambit2_props_file}"
    done
    for key in "${!config_props[@]}"; do
        sed "s|^${key}=.*|${key}=${config_props[$key]}|" -i "${config_props_file}"
    done

    # Update the WAR file with the "patched" files.
    jar -uf "${ambit_war}" "${ambit2_props_file}" "${config_props_file}"

    # Clean up.
    cd && rm -r "${tmp_dir}"

# End the initialization "if" block.
fi


# Execute any custom command provided.
exec "$@"
