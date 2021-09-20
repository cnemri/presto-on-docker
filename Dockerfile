FROM centos:7

LABEL Maintainer="Chouaieb Nemri<chouaib.nemri@gmail.com>"
LABEL Description="Presto Server"
LABEL Version="0.0.5"

ARG PRESTO_VERSION=0.254
ARG PRESTO_BASE_URL=https://repo1.maven.org/maven2/com/facebook/presto/presto-server-rpm
ARG PRESTO_CLI_BASE_URL=https://repo1.maven.org/maven2/com/facebook/presto/presto-cli
ARG PRESTO_CLI_BIN="${PRESTO_CLI_BASE_URL}/${PRESTO_VERSION}/presto-cli-${PRESTO_VERSION}-executable.jar"

ENV PRESTO_VAR_DIR=/var/presto \
    PRESTO_ETC_DIR=/etc/presto

ARG ALLUXIO_VERSION="2.6.2"

ENV env_ALLUXIO_VERSION=${ALLUXIO_VERSION}
    ALLUXIO_HOME=/opt/alluxio \
    ALLUXIO_CONF_DIR=/etc/alluxio \
    ALLUXIO_LOGS_DIR=/var/log/alluxio

##Update OS and Dependencies##
#USER root
 
## Download Presto server package and Presto CLI
RUN yum update -y &&\
    yum install -y curl wget vim less uuid python3 python3-pip ca-certificates python3-devel util-linux &&\
    pip3 install --upgrade pip 
RUN curl "${PRESTO_BASE_URL}/${PRESTO_VERSION}/presto-server-rpm-${PRESTO_VERSION}.rpm" -o "presto-server-rpm-${PRESTO_VERSION}.rpm"
RUN curl "${PRESTO_CLI_BIN}" -o "/usr/bin/presto"
RUN chmod +x /usr/bin/presto

# Install Presto server
RUN yum install -y java-1.8.0-openjdk \
 && yum localinstall -y "presto-server-rpm-${PRESTO_VERSION}.rpm" \
 && yum clean all \
 && rm -rf /var/cache/yum \
 && rm -rf /tmp/* \
 && mkdir -p ${PRESTO_VAR_DIR}/log \
 && mkdir -p ${PRESTO_VAR_DIR}/data \
 && mkdir -p ${PRESTO_ETC_DIR}/catalog \
 && rm ${PRESTO_ETC_DIR}/config.properties \
 && rm ${PRESTO_ETC_DIR}/node.properties

# Download and install Alluxio
RUN curl -sL --retry 3 "http://downloads.alluxio.org/downloads/files/${ALLUXIO_VERSION}/alluxio-${ALLUXIO_VERSION}-bin.tar.gz" \
  | tar xz -C /opt \
 && ln -s /opt/alluxio-${ALLUXIO_VERSION} ${ALLUXIO_HOME} \
 && chown -R root:root ${ALLUXIO_HOME} \
 && mkdir -p ${ALLUXIO_CONF_DIR} \
 && mkdir -p ${ALLUXIO_LOGS_DIR}


COPY ./scripts/entrypoint.sh ./scripts/start_presto.sh /usr/local/bin/
RUN rm "presto-server-rpm-${PRESTO_VERSION}.rpm"
EXPOSE 8080

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

CMD ["/usr/local/bin/start_presto.sh"]
