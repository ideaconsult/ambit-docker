FROM tomcat:7-jdk8-openjdk

ENV AMBIT_CONFIG_OVERRIDE_DIR /opt/ambit/config_override

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /
ENTRYPOINT ["docker-entrypoint.sh"]

COPY ambit2.war /usr/local/tomcat/webapps/ambit.war

CMD ["catalina.sh", "run"]

# vim: set ts=4 sts=4 sw=4 et:
