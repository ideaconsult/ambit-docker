FROM tomcat:9-jdk8-temurin

ENV AMBIT_CONFIG_OVERRIDE_DIR /opt/ambit/config_override

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /
ENTRYPOINT ["docker-entrypoint.sh"]

COPY tool3.war /usr/local/tomcat/webapps/tool3.war
ADD https://repo1.maven.org/maven2/net/sf/jnati/jnati-core/0.4/jnati-core-0.4.jar /usr/local/tomcat/lib/
ADD https://repo1.maven.org/maven2/net/sf/jnati/jnati-deploy/0.4/jnati-deploy-0.4.jar /usr/local/tomcat/lib/
ADD https://repo1.maven.org/maven2/net/sf/jni-inchi/jni-inchi/0.8/jni-inchi-0.8.jar /usr/local/tomcat/lib/
ADD https://repo1.maven.org/maven2/log4j/log4j/1.2.14/log4j-1.2.14.jar /usr/local/tomcat/lib/

CMD ["catalina.sh", "run"]

# vim: set ts=4 sts=4 sw=4 et ft=dockerfile:
