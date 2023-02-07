import { PutItemCommand, GetItemCommand, UpdateItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME, sesClient, FROM_EMAIL, PROJECT_NAME } from "./ddbClient.js";
import { generateOTP } from './util.js';
import {OTP_RESEND_DELAY} from './globals.js';

export const processResend = async (event) => {
    
    var email = "";
    
    try {
        email = JSON.parse(event.body).email.trim();
    } catch (e) {
        return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
    }
    
    
    if(email == null || email == "" || !email.match(/^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/)) {
        return {statusCode: 400, body: {result: false, error: "Email not valid!"}}
    }
    
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
    
    const name = resultGet.Item.name.S;
    const now = new Date().getTime();
    const otpTime = parseInt(parseInt(resultGet.Item.otpTime.S));
    
    if((otpTime + OTP_RESEND_DELAY*1000) > now) {
      return {statusCode: 401, body: {result: false, error: "The verification email should normally reach your inbox immediately. But in some cases it may take some more time. Please wait for a minute before attempting to resend."}}
    }
    
    
    const otp = generateOTP();
    const expiry = now + (24 * 60 * 60 * 1000)
    
    var newOtpArr = resultGet.Item.otp;
    if(newOtpArr == null || newOtpArr.L == null) {
      newOtpArr.L = [];
    }
    
    newOtpArr.L.push({
      "M": { 
        "otp" : { "S": otp + ""},
        "expiry" : { "S": expiry + ""}
      }
    });
    
    var updateParams = {
        TableName: TABLE_NAME,
        Key: {
          email: { S: email },
        },
        UpdateExpression: "set otp = :otp1, otpTime = :otpTime1",
        ExpressionAttributeValues: {
            ":otp1": newOtpArr,
            ":otpTime1": {"S": now + ""},
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
    
    async function sendEmail() {
      try {
        return await sesClient.send(new SendEmailCommand({
            Destination: {
              CcAddresses: [],
              ToAddresses: [email,],
            },
            Message: {
              Body: {
                Html: {
                  Charset: "UTF-8",
                  Data: "Hi " + name + ",<br /><br />Your one-time-password for signin is <strong>"+otp+"</strong> and is valid for only 24 hours.<br /><br />Do not share it with anybody else. <br /><br />Team " + PROJECT_NAME,
                },
                Text: {
                  Charset: "UTF-8",
                  Data: "Hi " + name + ", your one-time-password for signin is "+otp+" and is valid for only 24 hours. Do not share it with anybody else.....Team " + PROJECT_NAME,
                },
              },
              Subject: {
                Charset: "UTF-8",
                Data: "[" + PROJECT_NAME + "] " + otp + " is your signin OTP",
              },
            },
            Source: FROM_EMAIL,
            ReplyToAddresses: [],
        }));
      } catch (e) {
        return e;
      }
    }
    
    await sendEmail();
    
    return {statusCode: 200, body: {result: true}};

}