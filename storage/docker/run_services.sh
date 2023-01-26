#!/bin/bash

set -e # exit on error

rm -f /opt/volume/status/HADOOP_STATE

if [ ! -f /opt/volume/namenode/current/VERSION ]; then
    if [ ${NODE_ID} == "0" ]; then
        "${HADOOP_HOME}/bin/hdfs" namenode -format
    fi
    # $HIVE_HOME/bin/schematool -dbType derby -initSchema
fi

# Start ssh service
sudo service ssh start

export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HADOOP_HOME/lib/native


if [ ${NODE_ID} == "0" ]; then # Start HDFS on node 0 only, later we will start datanodes on other storage nodes
    echo "Starting Name Node ..."
    "${HADOOP_HOME}/bin/hdfs" --daemon start namenode

    echo "Starting Data Node ..."
    "${HADOOP_HOME}/bin/hdfs" --daemon start datanode
fi


export CLASSPATH=$(bin/hadoop classpath)
sleep 1

# Hive setup
# export PATH=$PATH:$HIVE_HOME/bin
# $HIVE_HOME/bin/hive --service metastore &> /opt/volume/metastore/metastore.log &
# sleep 1

# python3 ${HADOOP_HOME}/bin/metastore/hive_metastore_proxy.py &

python3 ${HADOOP_HOME}/bin/metastore/qflock_metastore_server.py &

pushd /R23/spark/spark_changes/scripts/stats_server
python3 stats_server.py &
popd

echo "HADOOP_READY"
echo "HADOOP_READY" > /opt/volume/status/HADOOP_STATE

echo "RUNNING_MODE $RUNNING_MODE"

if [ "$RUNNING_MODE" = "daemon" ]; then
    sleep infinity
fi