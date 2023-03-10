import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { SESClient } from "@aws-sdk/client-ses";
const REGION = "AWS_REGION"; //e.g. "us-east-1"
const origin = "WEB_ORIGIN";
const ddbClient = new DynamoDBClient({ region: REGION });
const sesClient = new SESClient({ region: REGION });
const PROJECT_NAME = "APP_NAME";
const TABLE_NAME = "DB_TABLE_NAME";
const LOG_TABLE_NAME = "DB_LOG_TABLE_NAME";
const FROM_EMAIL = "CORRESP_EMAIL"
export { ddbClient, TABLE_NAME, sesClient, FROM_EMAIL, PROJECT_NAME, origin, LOG_TABLE_NAME };