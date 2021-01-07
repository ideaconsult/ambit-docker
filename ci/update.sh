#!/usr/bin/env bash
set -o noclobber
set -o errexit
set -o pipefail
set -o nounset

declare -A tags=(
    ['ambit-api/tomcat10-jdk8-openjdk']='   tomcat10-jdk8-openjdk   tomcat10-jdk8   tomcat10'
    ['ambit-api/tomcat9-jdk8-openjdk']='    tomcat9-jdk8-openjdk    tomcat9-jdk8    tomcat9'
    ['ambit-api/tomcat8.5-jdk8-openjdk']='  tomcat8.5-jdk8-openjdk  tomcat8.5-jdk8  tomcat8.5'
    ['ambit-api/tomcat7-jdk8-openjdk']='    tomcat7-jdk8-openjdk    tomcat7-jdk8    tomcat7     latest'
    ['ambit-db/mariadb/10.5']='             mariadb-10.5            mariadb-10      mariadb     latest'
    ['ambit-db/mariadb/10.4']='             mariadb-10.4'
    ['ambit-db/mariadb/10.3']='             mariadb-10.3'
    ['ambit-db/mariadb/10.2']='             mariadb-10.2'
    ['ambit-db/mariadb/10.1']='             mariadb-10.1'
    ['ambit-db/mysql/8.0']='                mysql-8.0               mysql-8         mysql'
    ['ambit-db/mysql/5.7']='                mysql-5.7               mysql-5'
    ['ambit-db/mysql/5.6']='                mysql-5.6'
)

base="${PWD}"

for dir in "${!tags[@]}"; do
    cd "${base}/${dir}"
    image="${dir%%/*}"
    unset tag_opt
    for tag in ${tags[$dir]}; do
        tag_opt+=" --tag ideaconsult/${image}:${tag} "
    done
    # shellcheck disable=SC2086
    docker build --pull ${tag_opt} .
done

docker push ideaconsult/ambit-api
docker push ideaconsult/ambit-db

# vim: set ts=4 sts=4 sw=4 tw=100 et:
