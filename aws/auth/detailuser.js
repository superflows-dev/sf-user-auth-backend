import { GetItemCommand } from "@aws-sdk/client-dynamodb";
import { ddbClient, TABLE_NAME, sesClient, FROM_EMAIL, PROJECT_NAME } from "./ddbClient.js";
import { generateOTP, generateToken } from './util.js';
import { ACCESS_TOKEN_DURATION, REFRESH_TOKEN_DURATION } from './globals.js'
import { processValidate } from './validate.js'

export const processDetailUser = async (event) => {
    
    // body sanity check
  
    var body = null;
    
    try {
        body = JSON.parse(event.body);
    } catch (e) {
        return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
    }
    
    var email = "";
    
    try {
        email = body.email.trim();
    } catch (e) {
        return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
    }
    
    
    if(email == null || email == "" || !email.match(/^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/)) {
        return {statusCode: 400, body: {result: false, error: "Email not valid!"}}
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
    
    var unmarshalledItem = {};
    for(var i = 0; i < Object.keys(resultGet.Item).length; i++) {
        unmarshalledItem[Object.keys(resultGet.Item)[i]] = resultGet.Item[Object.keys(resultGet.Item)[i]][Object.keys(resultGet.Item[Object.keys(resultGet.Item)[i]])[0]];
    }

    return {statusCode: 200, body: {result: true, data: {values: (unmarshalledItem)}}};
    
}