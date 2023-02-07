import { PutItemCommand, GetItemCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, TABLE_NAME, sesClient, FROM_EMAIL, PROJECT_NAME } from "./ddbClient.js";
import { generateOTP } from './util.js';

export const processSignUp = async (event) => {
    
    var email = "";
    var name = "";
    
    try {
        email = JSON.parse(event.body).email.trim();
        name = JSON.parse(event.body).name.trim();  
    } catch (e) {
        return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
    }
    
    
    if(email == null || email == "" || !email.match(/^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/)) {
        return {statusCode: 400, body: {result: false, error: "Email not valid!"}}
    }
    
    if(name == null || name == "" || name.length < 3 ) {
        return {statusCode: 400, body: {result: false, error: "Name not valid!"}}
    }
    
    var getParams = {
        TableName: TABLE_NAME,
        Key: {
          email: { S: email },
        },
        ProjectionExpression: "email",
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
    
    if(resultGet.Item != null) {
    
        return {statusCode: 409, body: {result: false, error: "Account already exists!"}}

    }
    
    const now = new Date().getTime();
    const otp = generateOTP();
    const expiry = now + (24 * 60 * 60 * 1000)
    
    var setParams = {
        TableName: TABLE_NAME,
        Item: {
          'email' : {"S": email},
          'name' : {"S": name},
          'otpTime' : {"S": now + ""},
          'otp' : {
            "L" : [
              {
                "M": {
                  'otp': {"S": otp + ""},
                  'expiry': {"S": expiry + ""}
                }
              }
            ]
          }
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
            console.log(e);
            return e;
            
          }
    }
    
    await sendEmail();
    
    return {statusCode: 200, body: {result: true}};

}