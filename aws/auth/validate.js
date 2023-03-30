import { PutItemCommand, GetItemCommand, UpdateItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME, sesClient, FROM_EMAIL, PROJECT_NAME } from "./ddbClient.js";
import { generateOTP, generateToken } from './util.js';
import { ACCESS_TOKEN_DURATION, REFRESH_TOKEN_DURATION } from './globals.js'
import { processAddLog } from './addLog.js'

export const newUuidV4 = () => {
  
  var d = new Date().getTime();//Timestamp
  var d2 = 0;//Time in microseconds since page-load or 0 if unsupported
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r = Math.random() * 16;//random number between 0 and 16
      if(d > 0){//Use timestamp until depleted
          r = (d + r)%16 | 0;
          d = Math.floor(d/16);
      } else {//Use microseconds since page-load if supported
          r = (d2 + r)%16 | 0;
          d2 = Math.floor(d2/16);
      }
      return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
  });

}

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
      const response = {statusCode: 400, body: {result: false, error: "Malformed headers!"}}
      //processAddLog('norequest', 'validate', event, response, response.statusCode)
      return response;
    }
    
    if(accessToken.length < 5) {
      const response = {statusCode: 400, body: {result: false, error: "Malformed headers!"}}
      //processAddLog(email, 'validate', event, response, response.statusCode)
      return response;
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
    
      const response = {statusCode: 404, body: {result: false, error: "Account does not exist!"}}
      //processAddLog(email, 'validate', event, response, response.statusCode)
      return response;

    }
    
    //
    // Check if accessToken exists and valid
    //
    
    const now = new Date().getTime();
    
    var foundAccessToken = false;
    var validAccessToken = false;
    
    for(var i = 0; i < resultGet.Item.accessTokens.L.length; i++) {
      
      
      if(resultGet.Item.accessTokens.L[i].M.token.S == accessToken) {
        foundAccessToken = true;
        if(parseInt(resultGet.Item.accessTokens.L[i].M.expiry.S + "") > now) {
          validAccessToken = true;
        }
      } 
    }
    
    if(!foundAccessToken || !validAccessToken) {
      const response = {statusCode: 401, body: {result: false, error: "Unauthorized request!"}};
      //processAddLog(email, 'validate', event, response, response.statusCode)
      return response;
    }

    var newUuid = "";
    
    if(resultGet.Item.userId == null) {
      
      newUuid = newUuidV4();
      
      var updateParams = {
          TableName: TABLE_NAME,
          Key: {
            email: { S: email },
          },
          UpdateExpression: "set #userId = :userId1",
          ExpressionAttributeValues: {
              ":userId1": {"S": newUuid}
          },
          ExpressionAttributeNames: {
              "#userId1": "userId"
          }
      };
      
      const ddbUpdate = async () => {
          try {
            const data = await ddbClient.send(new UpdateItemCommand(updateParams));
            return data;
          } catch (err) {
            console.log(err)
            return err;
          }
      };
      
      var resultUpdate = await ddbUpdate();
      
    } else {
      
      newUuid = resultGet.Item.userId.S;
      
    }
    
    if(foundAccessToken && validAccessToken) {
      const response = {statusCode: 200, body: {result: true, userId: newUuid, admin: resultGet.Item.admin != null ? resultGet.Item.admin : false}};
      //processAddLog(email, 'validate', event, response, response.statusCode)
      return response;
    }

}