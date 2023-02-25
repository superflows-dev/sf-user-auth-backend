import { GetItemCommand, UpdateItemCommand } from "@aws-sdk/client-dynamodb";
import { ddbClient, TABLE_NAME, sesClient, FROM_EMAIL, PROJECT_NAME } from "./ddbClient.js";
import { generateOTP, generateToken } from './util.js';
import { ACCESS_TOKEN_DURATION, REFRESH_TOKEN_DURATION } from './globals.js'
import { processValidate } from './validate.js'

export const processUpdateUser = async (event) => {
    
    // body sanity check
  
    var body = null;
    
    try {
        body = JSON.parse(event.body);
    } catch (e) {
        return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
    }
    
    var email = "";
    var name = ""
    var reason = "";
    var admin = false;
    var suspended = false;
    
    try {
        email = body.email.trim();
        name = body.name.trim();
        reason = body.reason.trim();
        admin = body.admin;
        suspended = body.suspended;
    } catch (e) {
        return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
    }
    
    
    if(email == null || email == "" || !email.match(/^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/)) {
        return {statusCode: 400, body: {result: false, error: "Email not valid!"}}
    }
    
    if(name == null || name.length < 3) {
        return {statusCode: 400, body: {result: false, error: "Name not valid!"}}
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
    
    // update record
    
    var updateParams = {
        TableName: TABLE_NAME,
        Key: {
          email: { S: email },
        },
        UpdateExpression: "set #name1 = :name1, admin = :admin1, accessTokens = :access1, refreshTokens = :refresh1, otp = :otp1, suspended = :suspended1, reason = :reason1",
        ExpressionAttributeNames: {
            "#name1": "name"
        },
        ExpressionAttributeValues: {
            ":access1": { "L": [] },
            ":refresh1": { "L": [] },
            ":otp1": { "L": [] },
            ":suspended1": { "BOOL": suspended },
            ":admin1": { "BOOL": admin },
            ":reason1": { "S": reason },
            ":name1": { "S": name },
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