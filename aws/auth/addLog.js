import { PutItemCommand, GetItemCommand, ScanCommand, DeleteItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME, LOG_TABLE_NAME, sesClient, FROM_EMAIL, PROJECT_NAME } from "./ddbClient.js";
import { generateOTP } from './util.js';
import { PRESERVE_LOGS_DAYS } from './globals.js'

export const processAddLog = async (email, op, req, resp, httpCode) => {
    
    
    const now = new Date().getTime();
    
    var setParams = {
        TableName: LOG_TABLE_NAME,
        Item: {
            'email' : {"S": email},
            'timestamp' : {"N": (now + "")},
            'httpCode' : {"S": (httpCode + "")},
            'operation' : {"S": op + ""},
            'response' : {"S": JSON.stringify(resp)},
            'request' : {"S": JSON.stringify(req)}
            
        }
    };
    
    const ddbPut = async () => {
        try {
          const data = await ddbClient.send(new PutItemCommand(setParams));
          return data;
        } catch (err) {
          return err;
        }
    };
    
    const resultPut = await ddbPut();
    
    // scan records
  
    var scanParams = {
        TableName: LOG_TABLE_NAME,
    }
    
    var resultItems = []
  
    async function ddbQuery () {
        try {
            const data = await ddbClient.send (new ScanCommand(scanParams));
            resultItems = resultItems.concat((data.Items))
            if(data.LastEvaluatedKey != null) {
                scanParams.ExclusiveStartKey = data.LastEvaluatedKey;
                await ddbQuery();
            }
        } catch (err) {
            return err;
        }
    };
    
    await ddbQuery();
    
    const ddbDelete = async () => {
        try {
            const data = await ddbClient.send(new DeleteItemCommand(deleteParams));
            return data;
        } catch (err) {
            console.log(err)
            return err;
        }
    };
    
    for(var i = 0; i < resultItems.length; i++) {
        const email = resultItems[i].email.S;
        const timestamp = resultItems[i].timestamp.N;
        if((parseInt(now) - parseInt(timestamp)) > PRESERVE_LOGS_DAYS*24*60*60*1000) {
                
            var deleteParams = {
                TableName: TABLE_NAME,
                Key: {
                    email: { S: email },
                    timestamp: {N: timestamp + ""}
                }
            };
            var resultDelete = await ddbDelete();
            
        }
    }
    
    
    return {statusCode: 200, body: {result: true}};

}