#!/usr/bin/env bash
set -e


#############################
# Default Values
#############################
: "${PRESTO_JVM_MEMORY_MS_MX:=8G}"
: "${PRESTO_JVM_SETTINGS:=-server \
-Xmx${PRESTO_JVM_MEMORY_MS_MX} \
-XX:-UseBiasedLocking \
-XX:+UseG1GC \
-XX:+ExplicitGCInvokesConcurrent \
-XX:+HeapDumpOnOutOfMemoryError \
-XX:+UseGCOverheadLimit \
-XX:+ExitOnOutOfMemoryError \
-XX:ReservedCodeCacheSize=512M}"

# node
: "${PRESTO_NODE_ENVIRONMENT:=docker}"
: "${PRESTO_NODE_ID:=$(uuidgen)}"

# config
: "${PRESTO_CONF_COORDINATOR:=true}"
: "${PRESTO_CONF_INCLUDE_COORDINATOR:=true}"
: "${PRESTO_CONF_HTTP_PORT:=8080}"
: "${PRESTO_CONF_DISCOVERY_SERVER_ENABLED:=true}"
: "${PRESTO_CONF_DISCOVERY_URI:=http://localhost:8080}"
: "${PRESTO_CONF_QUERY_MAX_MEMORY:=5GB}"
: "${PRESTO_CONF_QUERY_MAX_MEMORY_PER_NODE:=1GB}"
: "${PRESTO_CONF_QUERY_MAX_TOTAL_MEMORY_PER_NODE:=2GB}"

# catalogs
# jmx
: "${PRESTO_CATALOG_JMX:=true}"
: "${PRESTO_CATALOG_TPCDS:=true}"
: "${PRESTO_CATALOG_TPCH:=true}"
: "${PRESTO_CATALOG_BLACKHOLE:=true}"


# hive
: "${PRESTO_CATALOG_HIVE:=true}"
: "${PRESTO_CATALOG_HIVE_NAME:=hive}"

# alluxio
: "${PRESTO_CATALOG_ALLUXIO:=true}"
: "${PRESTO_CATALOG_ALLUXIO_NAME:=catalog_alluxio}"

# mysql
: "${PRESTO_CATALOG_MYSQL:=true}"
: "${PRESTO_CATALOG_MYSQL_NAME:=mysql}"
: "${PRESTO_CATALOG_MYSQL_HOST:=mysql}"
: "${PRESTO_CATALOG_MYSQL_PORT:=3306}"
: "${PRESTO_CATALOG_MYSQL_USER:=dbuser}"
: "${PRESTO_CATALOG_MYSQL_PASSWORD:=dbuser}"

#############################
# jvm.config
#############################
presto_jvm_config() {
    for i in ${PRESTO_JVM_SETTINGS}
        do
            prnt="$prnt\n$i"       # New line directly 
        done
    echo -e "${prnt:2}"  # Trim the leading newline
            
} > /etc/presto/jvm.config

#############################
# log.properties
#############################
presto_log_config() {
    echo "com.facebook.presto=INFO"  
    echo "com.sun.jersey.guice.spi.container.GuiceComponentProviderFactory=WARN"
    echo "com.ning.http.client=WARN"
    echo "com.facebook.presto.server.PluginManager=DEBUG"            
} > /etc/presto/log.properties


#############################
# node.properties
#############################
presto_node_config()
{
    echo "node.environment=${PRESTO_NODE_ENVIRONMENT}"
    echo "node.id=${PRESTO_NODE_ID}"
    echo "catalog.config-dir=/etc/presto/catalog"
    echo "plugin.dir=/usr/lib/presto/lib/plugin"
} > /etc/presto/node.properties


#############################
# config.properties
#############################
presto_settings_config()
{
    echo "coordinator=${PRESTO_CONF_COORDINATOR}"
    echo "http-server.http.port=${PRESTO_CONF_HTTP_PORT}"
    echo "discovery.uri=${PRESTO_CONF_DISCOVERY_URI}"
    echo "query.max-memory=${PRESTO_CONF_QUERY_MAX_MEMORY}"
    echo "query.max-memory-per-node=${PRESTO_CONF_QUERY_MAX_MEMORY_PER_NODE}"
    echo "query.max-total-memory-per-node=${PRESTO_CONF_QUERY_MAX_TOTAL_MEMORY_PER_NODE}"
    
    # Only write out coordinator specific configs if this is a coordinator
    if [ $PRESTO_CONF_COORDINATOR == "true" ]; then
        echo "discovery-server.enabled=${PRESTO_CONF_DISCOVERY_SERVER_ENABLED}"
        echo "node-scheduler.include-coordinator=${PRESTO_CONF_INCLUDE_COORDINATOR}"
    fi

} > /etc/presto/config.properties

#############################
# catalog jmx
#############################
catalog_jmx_config()
{
    echo "connector.name=jmx"
} > "/etc/presto/catalog/jmx.properties"


#############################
# catalog tpcds
#############################
catalog_tpcds_config()
{
    echo "connector.name=tpcds"
} > "/etc/presto/catalog/tpcds.properties"

#############################
# catalog tpch
#############################
catalog_tpch_config()
{
    echo "connector.name=jmx"
} > "/etc/presto/catalog/tpch.properties"

#############################
# catalog blackhole
#############################
catalog_blackhole_config()
{
    echo "connector.name=blackhole"
} > "/etc/presto/catalog/blackhole.properties"


#############################
# catalog hive
#############################
catalog_hive_config()
{
    #Defaults
    echo "connector.name=hive-hadoop2"
    echo "hive.collect-column-statistics-on-write=true"
    echo "hive.recursive-directories=true"
    echo "hive.orc.use-column-names=true"
    echo "hive.parquet.use-column-names=true"
    echo "hive.allow-drop-table=true"
    echo "hive.allow-rename-table=true"
    echo "hive.allow-add-column=true"
    echo "hive.allow-drop-column=true"
    echo "hive.allow-rename-column=true"
    echo "hive.non-managed-table-writes-enabled=true"
    echo "hive.non-managed-table-creates-enabled=true"
    echo "hive.metastore.uri=${PRESTO_CATALOG_HIVE_METASTORE_URI}"
    echo "hive.config.resources=${PRESTO_CATALOG_HIVE_CONFIG_RESOURCES}"
} > "/etc/presto/catalog/${PRESTO_CATALOG_HIVE_NAME}.properties"

#############################
# catalog alluxio
#############################
catalog_alluxio_config()
{
  echo "connector.name=hive-hadoop2"
  echo "hive.metastore=alluxio"
  echo "hive.metastore.alluxio.master.address=alluxio-master-0:19998"
} > "/etc/presto/catalog/${PRESTO_CATALOG_ALLUXIO_NAME}.properties"


#############################
# catalog mysql
#############################
catalog_mysql_config() 
{
    echo "connector.name=mysql"
    echo "connection-url=jdbc:mysql://${PRESTO_CATALOG_MYSQL_HOST}:${PRESTO_CATALOG_MYSQL_PORT}?useSSL=false"
    echo "connection-user=${PRESTO_CATALOG_MYSQL_USER}"
    echo "connection-password=${PRESTO_CATALOG_MYSQL_PASSWORD}"
} >/etc/presto/catalog/${PRESTO_CATALOG_MYSQL_NAME}.properties

#############################
# Work around for now for AWS SDK (Currently hive config with glue is not working without this)
# Seems to be a bug
# Doesn't look like the glue portion of the connector is bootstrapping
# from the connector config. S3 Access alone works, but not with glue
# 06/26: Seems to be fixed in .255 so no longer an issue
#############################
aws_sdk_credentials_config() 
{
        echo "[default]"
        echo "aws_access_key_id=${PRESTO_CATALOG_HIVE_S3_AWS_ACCESS_KEY}"
        echo "aws_secret_access_key=${PRESTO_CATALOG_HIVE_S3_AWS_SECRET_KEY}"
    
} > /root/.aws/credentials

#############################
# Let er rip
#############################
presto_log_config
presto_jvm_config
presto_settings_config
presto_node_config


# jmx
if [ $PRESTO_CATALOG_JMX == "true" ]; then
    catalog_jmx_config
fi

# tpcds
if [ $PRESTO_CATALOG_TPCDS == "true" ]; then
    catalog_tpcds_config
fi

# tpch
if [ $PRESTO_CATALOG_TPCH == "true" ]; then
    catalog_tpch_config
fi

# blackhole
if [ $PRESTO_CATALOG_BLACKHOLE == "true" ]; then
    catalog_blackhole_config
fi

# hive
if [ $PRESTO_CATALOG_HIVE == "true" ]; then
    catalog_hive_config

    # Workaround for now
    # Use glue specific keys
    # 06/26 Yaay! looks like someone fixed it
    # mkdir -p /root/.aws/
    # aws_sdk_credentials_config
fi

# alluxio
if [ $PRESTO_CATALOG_ALLUXIO == "true" ]; then
    catalog_alluxio_config
fi

# hive
if [ $PRESTO_CATALOG_MYSQL == "true" ]; then
    catalog_mysql_config
fi

# Copy alluxio jar to presto plugins directory
cp ${ALLUXIO_HOME}/client/alluxio-${env_ALLUXIO_VERSION}-client.jar /usr/lib/presto/lib/plugin/hive-hadoop2


#############################
# execute
#############################
echo "Executing: $@"
exec "$@"
