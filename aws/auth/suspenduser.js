import { GetItemCommand, UpdateItemCommand } from "@aws-sdk/client-dynamodb";
import { ddbClient, TABLE_NAME, sesClient, FROM_EMAIL, PROJECT_NAME } from "./ddbClient.js";
import { generateOTP, generateToken } from './util.js';
import { ACCESS_TOKEN_DURATION, REFRESH_TOKEN_DURATION } from './globals.js'
import { processValidate } from './validate.js'

export const processSuspendUser = async (event) => {
    
    // body sanity check
  
    var body = null;
    
    try {
        body = JSON.parse(event.body);
    } catch (e) {
        return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
    }
    
    var email = "";
    var reason = "";
    
    try {
        email = body.email.trim();
        reason = body.reason.trim();
    } catch (e) {
        return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
    }
    
    
    if(email == null || email == "" || !email.match(/^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/)) {
        return {statusCode: 400, body: {result: false, error: "Email not valid!"}}
    }
    
    if(reason == null || reason.length < 3) {
        return {statusCode: 400, body: {result: false, error: "Provide a reason for suspension please!"}}
    }
    
    // validate access token
    
    const resultValidate = await processValidate(event);
    if(!resultValidate.body.result || !resultValidate.body.admin) {
        return {statusCode: 401, body: {result: false, error: "Unauthorized request!"}};
    }
    
    // get user
    
    var getParams = {
        TableName: TABLE_NAME,
        Key: {
          email: { S: email },
        },
    };
    
    async function ddbGet () {
        try {
          const data = await ddbClient.send(new GetItemCommand(getParams));
          return data;
        } catch (err) {
          return err;
        }
    };
    
    var resultGet = await ddbGet();
    
    if(resultGet.Item == null) {
    
        return {statusCode: 404, body: {result: false, error: "Account does not exist!"}}

    }
    
    if(resultGet.Item.admin) {
        return {statusCode: 409, body: {result: false, error: "Admin cannot be suspended!"}}
    }
    
    // set suspended flag and reason
    
    var updateParams = {
        TableName: TABLE_NAME,
        Key: {
          email: { S: email },
        },
        UpdateExpression: "set accessTokens = :access1, refreshTokens = :refresh1, otp = :otp1, suspended = :suspended1, reason = :reason1",
        ExpressionAttributeValues: {
            ":access1": { "L": [] },
            ":refresh1": { "L": [] },
            ":otp1": { "L": [] },
            ":suspended1": { "BOOL": true },
            ":reason1": { "S": reason },
        }
    };
      
    const ddbUpdate = async () => {
        try {
            const data = await ddbClient.send(new UpdateItemCommand(updateParams));
            return data;
        } catch (err) {
            return err;
        }
    };
      
    var resultUpdate = await ddbUpdate();
    
    return {statusCode: 200, body: {result: true}};
    
}