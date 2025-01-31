import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, from_unixtime, date_format, lit, current_timestamp, from_json, explode, explode_outer, sum as spark_sum, when
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, ArrayType, BooleanType
from datetime import datetime

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'rds_connection_name'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)
logger = glueContext.get_logger()

logger.info("Starting Script for ETL of RDS data")

datasource = glueContext.create_dynamic_frame.from_options(
    connection_type = "postgresql",
    connection_options = {
        "connectionName": args['rds_connection_name'],
        "dbtable": "template",
        "useConnectionProperties": "true",
    },
    transformation_ctx = "datasource"
).toDF()

# Print the dataframe data
logger.info("Dataframe data")
for row in datasource.collect():
    logger.info(f"Data row: {row}")

job.commit()
