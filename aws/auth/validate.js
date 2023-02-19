import { PutItemCommand, GetItemCommand, UpdateItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME, sesClient, FROM_EMAIL, PROJECT_NAME } from "./ddbClient.js";
import { generateOTP, generateToken } from './util.js';
import { ACCESS_TOKEN_DURATION, REFRESH_TOKEN_DURATION } from './globals.js'

export const processValidate = async (event) => {
    
    
    //
    // Sanity check
    //
    
    var hAscii = '';
    
    if((event["headers"]["Authorization"]) == null) {
      return {statusCode: 400, body: { result: false, error: "Malformed headers!"}};
    }
    
    
    if((event["headers"]["Authorization"].split(" ")[1]) == null) {
      return {statusCode: 400, body: { result: false, error: "Malformed headers!"}};
    }
    
    hAscii = Buffer.from((event["headers"]["Authorization"].split(" ")[1] + ""), 'base64').toString('ascii');
    
    if(hAscii.split(":")[1] == null) {
      return {statusCode: 400, body: { result: false, error: "Malformed headers!"}};
    }
    
    const email = hAscii.split(":")[0];
    const accessToken = hAscii.split(":")[1];
    
    if(email == "" || !email.match(/^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/)) {
        return {statusCode: 400, body: {result: false, error: "Malformed headers!"}}
    }
    
    if(accessToken.length < 5) {
        return {statusCode: 400, body: {result: false, error: "Malformed headers!"}}
    }
    
    //
    // if email does not exist, show error
    //
    
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
    
    console.log('ascii', hAscii);
    
    //
    // Check if accessToken exists and valid
    //
    
    const now = new Date().getTime();
    
    var foundAccessToken = false;
    var validAccessToken = false;
    
    for(var i = 0; i < resultGet.Item.accessTokens.L.length; i++) {
      
      console.log('comparing', resultGet.Item.accessTokens.L[i].M.token.S, accessToken)
      if(resultGet.Item.accessTokens.L[i].M.token.S == accessToken) {
        foundAccessToken = true;
        if(parseInt(resultGet.Item.accessTokens.L[i].M.expiry.S + "") > now) {
          validAccessToken = true;
        }
      } 
    }
    
    if(!foundAccessToken || !validAccessToken) {
      return {statusCode: 401, body: {result: false, error: "Unauthorized request!"}};
    }
    
    if(foundAccessToken && validAccessToken) {
      return {statusCode: 200, body: {result: true, admin: resultGet.Item.admin != null ? resultGet.Item.admin : false}};
    }

}