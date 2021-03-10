FROM mysql:5.7

ENV MYSQL_ROOT_PASSWORD ambitroot

RUN apt-get update && apt-get --yes install curl xz-utils

ADD https://raw.githubusercontent.com/ideaconsult/ambit-mirror/master/ambit2-all/ambit2-db/src/main/resources/ambit2/db/sql/create_tables.sql \
    /opt/ambit/tmp/

ADD https://raw.githubusercontent.com/vedina/RESTNet/master/restnet-db/src/main/resources/net/idea/restnet/db/aalocal/sql/users.sql \
    /opt/ambit/tmp/

COPY docker-entrypoint-ambit.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint-ambit.sh /
ENTRYPOINT ["docker-entrypoint-ambit.sh"]

CMD ["--character-set-server=utf8mb4", "--collation-server=utf8mb4_unicode_ci"]

# vim: set ts=4 sts=4 sw=4 et:
