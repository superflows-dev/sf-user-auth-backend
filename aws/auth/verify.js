import { PutItemCommand, GetItemCommand, UpdateItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME, sesClient, FROM_EMAIL, PROJECT_NAME } from "./ddbClient.js";
import { generateOTP, generateToken } from './util.js';
import { ACCESS_TOKEN_DURATION, REFRESH_TOKEN_DURATION } from './globals.js'
import { processAddLog } from './addLog.js'

export const processVerify = async (event) => {
    
    
    //
    // Sanity check
    //
    
    var email = "";
    var otp = "";
    
    try {
        email = JSON.parse(event.body).email.trim();
        otp = JSON.parse(event.body).otp.trim();  
    } catch (e) {
      const response = {statusCode: 400, body: { result: false, error: "Malformed body!"}}; 
      processAddLog('norequest', 'verify', event, response, response.statusCode)
      return response;
    }
    
    
    if(email == null || email == "" || !email.match(/^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/)) {
      const response = {statusCode: 400, body: {result: false, error: "Email not valid!"}}
      processAddLog('norequest', 'verify', event, response, response.statusCode)
      return response;
    }
    
    if(otp == null || otp == "" || otp.length < 3 ) {
      const response = {statusCode: 400, body: {result: false, error: "OTP not valid!"}}
      processAddLog(email, 'verify', event, response, response.statusCode)
      return response;
    }
    
    
    //
    // Check if item exists
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
      processAddLog(email, 'verify', event, response, response.statusCode)
      return response;

    }
    
    if(resultGet.Item.suspended != null) {
      
      if(resultGet.Item.suspended['BOOL']) {
        
        const response = {statusCode: 401, body: {result: false, error: "Unauthorized request!"}};
        processAddLog(email, 'verify', event, response, response.statusCode)
        return response;
        
      }
      
    }
    
    //
    // Check otp correctness and validity
    //
    
    const now = new Date().getTime();
    
    var found = false;
    
    var newOtpArr = {};
    newOtpArr.L = [];
    
    for(var i = 0; i < resultGet.Item.otp.L.length; i++) {
      
      if(resultGet.Item.otp.L[i].M.otp.S == otp) {
        
        if(parseInt(resultGet.Item.otp.L[i].M.expiry.S + "") > now) {
          found = true;
        }
      } else {
        newOtpArr.L.push({
          "M": { 
            "otp" : { "S": resultGet.Item.otp.L[i].M.otp.S + ""},
            "expiry" : { "S": resultGet.Item.otp.L[i].M.expiry.S + ""}
          }
        });
        
      }
    }
    
    
    if(found) {
      
      //
      // Generate a new refresh token
      //
      
      var newRefreshTokenArr = {};
      newRefreshTokenArr.L = [];
      
      if(resultGet.Item.refreshTokens != null) {
        newRefreshTokenArr.L = resultGet.Item.refreshTokens.L;
      }
      
      const newRefreshToken = generateToken();
      const expiryRefreshToken = new Date().getTime() + REFRESH_TOKEN_DURATION*(24 * 60 * 60 * 1000)
      
      newRefreshTokenArr.L.push({
        "M": {
          "token" : {"S": newRefreshToken },
          "expiry" : {"S": expiryRefreshToken + ""}
        }
      });
      
      //
      // Update DB
      //
      
      var updateParams = {
        TableName: TABLE_NAME,
        Key: {
          email: { S: email },
        },
        UpdateExpression: "set otp = :otp1, refreshTokens = :tokens2",
        ExpressionAttributeValues: {
            ":otp1": newOtpArr,

            ":tokens2": newRefreshTokenArr
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
      
      const response = {statusCode: 200, body: {result: true, admin: resultGet.Item.admin != null ? resultGet.Item.admin : false, data: {refreshToken: {token: newRefreshToken, expiry: expiryRefreshToken}, name: resultGet.Item.name, email: resultGet.Item.email}}};
      processAddLog(email, 'verify', event, response, response.statusCode)
      return response;

    } else {
      
      const response = {statusCode: 401, body: {result: false, error: "Incorrect OTP!"}}
      processAddLog(email, 'verify', event, response, response.statusCode)
      return response;
      
    }

}