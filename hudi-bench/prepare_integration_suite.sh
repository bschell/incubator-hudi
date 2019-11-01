#!/bin/bash

# Determine the current working directory
_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Preserve the calling directory
_CALLING_DIR="$(pwd)"

#########################
# The command line help #
#########################
usage() {
    echo "Usage: $0"
    echo "   --spark-command, prints the spark command"
    echo "   -h, hdfs-version"
    echo "   -s, spark version"
    echo "   -p, parquet version"
    echo "   -a, avro version"
    echo "   -s, hive version"
    exit 1
}

get_spark_command() {
echo "spark-submit --packages com.databricks:spark-avro_2.11:4.0.0 \
--master $0 \
--deploy-mode $1 \
--properties-file $2 \
--class org.apache.hudi.bench.job.HoodieTestSuiteJob \
`ls target/hudi-bench-*-SNAPSHOT.jar` \
--source-class $3 \
--source-ordering-field $4 \
--input-base-path $5 \
--target-base-path $6 \
--target-table $7 \
--props $8 \
--storage-type $9 \
--payload-class "${10}" \
--workload-yaml-path "${11}" \
--input-file-size "${12}" \
--<deltastreamer-ingest>"
}

case "$1" in
   --help)
       usage
       exit 0
       ;;
esac

case "$1" in
   --spark-command)
       get_spark_command
       exit 0
       ;;
esac

while getopts ":h:s:p:a:s:" opt; do
  case $opt in
    h) hdfs="$OPTARG"
    printf "Argument hdfs is %s\n" "$hdfs"
    ;;
    s) spark="$OPTARG"
    printf "Argument spark is %s\n" "$spark"
    ;;
    p) parquet="$OPTARG"
    printf "Argument parquet is %s\n" "$parquet"
    ;;
    a) avro="$OPTARG"
    printf "Argument avro is %s\n" "$avro"
    ;;
    s) hive="$OPTARG"
    printf "Argument hive is %s\n" "$hive"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done


get_versions () {
  base_command=''
  if [ -z "$hdfs" ]
   then
    base_command=$base_command
  else
    hdfs=$1
    base_command+=' -Dhadoop.version='$hdfs
  fi

  if [ -z "$hive" ]
  then
    base_command=$base_command
  else
    hive=$2
    base_command+=' -Dhive.version='$hive
  fi
  echo $base_command
}

versions=$(get_versions $hdfs $hive)

final_command='mvn clean install -DskipTests '$versions
printf "Final command $final_command \n"

# change to the project root directory to run maven command
move_to_root='cd ..'
$move_to_root && $final_command

# change back to original working directory
cd $_CALLING_DIR

printf "A sample spark command to start the integration suite \n"
get_spark_command