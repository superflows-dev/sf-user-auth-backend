import { PutItemCommand, GetItemCommand, UpdateItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME, sesClient, FROM_EMAIL, PROJECT_NAME } from "./ddbClient.js";
import { generateOTP, generateToken } from './util.js';
import { ACCESS_TOKEN_DURATION, REFRESH_TOKEN_DURATION } from './globals.js'

export const processRefresh = async (event) => {
    
    
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
    const refreshToken = hAscii.split(":")[1]; 
    
    if(email == "" || !email.match(/^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/)) {
        return {statusCode: 400, body: {result: false, error: "Malformed headers!"}}
    }
    
    if(refreshToken.length < 5) {
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
    
    const now = new Date().getTime();
    
    //
    // Check if refreshToken exists and valid
    //
    
    var foundRefreshToken = false;
    var validRefreshToken = false;
    
    for(var i = 0; i < resultGet.Item.refreshTokens.L.length; i++) {
      
      console.log('comparing', resultGet.Item.refreshTokens.L[i].M.token.S, refreshToken)
      if(resultGet.Item.refreshTokens.L[i].M.token.S == refreshToken) {
        foundRefreshToken = true;
        if(parseInt(resultGet.Item.refreshTokens.L[i].M.expiry.S + "") > now) {
          validRefreshToken = true;
        }
      } 
    }
    
    //
    // Refresh token does not exist
    //
    
    if(!foundRefreshToken) {
      return {statusCode: 401, body: {result: false, error: "Unauthorized request!!"}};
    }
    
    //
    // Refresh token exists but is expired
    //
    
    if(foundRefreshToken && !validRefreshToken) {
      return {statusCode: 401, body: {result: false, error: "Unauthorized request!!"}};
    }
    
    //
    // Prepare access token array with rotated token
    //
    
    const newAccessToken = generateToken();
    const expiryAccessToken = new Date().getTime() + ACCESS_TOKEN_DURATION*(24 * 60 * 60 * 1000)
    
    // Create a new array with the old data + new token
    
    var newAccessTokenArr = {};
    newAccessTokenArr.L = [];
    
    if(resultGet.Item.accessTokens != null) {
      newAccessTokenArr.L = resultGet.Item.accessTokens.L;
    }
    
    newAccessTokenArr.L.push({
      "M": {
        "token" : {"S": newAccessToken },
        "expiry" : {"S": expiryAccessToken + ""}
      }
    });
    
    console.log('New accessToken', JSON.stringify(newAccessTokenArr))
    
    // Remove old entries and create a trimmed array
    
    var newAccessTokenTrimmedArr = {};
    newAccessTokenTrimmedArr.L = [];
    
    for(var i = 0; i < newAccessTokenArr.L.length; i++) {
      console.log('Comparing accessToken', newAccessTokenArr.L[i].M.expiry.S, now)
      if(parseInt(newAccessTokenArr.L[i].M.expiry.S + "") > now) {
          newAccessTokenTrimmedArr.L.push(newAccessTokenArr.L[i]);
      }
    }
    
    console.log('Trimmed accessToken', JSON.stringify(newAccessTokenTrimmedArr));
    
    //
    // Prepare refresh token array with rotated token
    //
    
    const newRefreshToken = generateToken();
    const expiryRefreshToken = new Date().getTime() + REFRESH_TOKEN_DURATION*(24 * 60 * 60 * 1000)
    
    // Create a new array with the old data + new token
    
    var newRefreshTokenArr = {};
    newRefreshTokenArr.L = [];
    
    if(resultGet.Item.refreshTokens != null) {
      newRefreshTokenArr.L = resultGet.Item.refreshTokens.L;
    }
    
    newRefreshTokenArr.L.push({
      "M": {
        "token" : {"S": newRefreshToken },
        "expiry" : {"S": expiryRefreshToken + ""}
      }
    });
    
    // Remove old entries and create a trimmed array
    
    var newRefreshTokenTrimmedArr = {};
    newRefreshTokenTrimmedArr.L = [];
    
    for(var i = 0; i < newRefreshTokenArr.L.length; i++) {
      if(parseInt(newRefreshTokenArr.L[i].M.expiry.S + "") > now) {
          newRefreshTokenTrimmedArr.L.push(newRefreshTokenArr.L[i]);
      }
    }
    
    
    console.log('Trimmed refreshToken', JSON.stringify(newRefreshTokenTrimmedArr));
    
    
    //
    // Update DB
    //
    
    var updateParams = {
      TableName: TABLE_NAME,
      Key: {
        email: { S: email },
      },
      UpdateExpression: "set accessTokens = :tokens1, refreshTokens = :tokens2",
      ExpressionAttributeValues: {
          ":tokens1": newAccessTokenTrimmedArr,
          ":tokens2": newRefreshTokenTrimmedArr
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
    
    console.log('resultUpdate', resultUpdate);
    
    return {statusCode: 200, body: {result: true, data: {accessToken: {token: newAccessToken, expiry: expiryAccessToken}, refreshToken: {token: newRefreshToken, expiry: expiryRefreshToken}}}};

}