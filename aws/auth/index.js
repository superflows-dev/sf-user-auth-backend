import { processSignUp } from './signUp.js'
import { processSignIn } from './signIn.js'
import { processVerify } from './verify.js'
import { processValidate } from './validate.js'
import { processRefresh } from './refresh.js'
import { processResend } from './resend.js'
import { processDetailUser } from './detailuser.js'
import { processLogoutUser } from './logoutuser.js'
import { processSuspendUser } from './suspenduser.js'
import { processResumeUser } from './resumeuser.js'
import { processUpdateUser } from './updateuser.js'
import { processListLogs } from './listlogs.js'
import { origin } from "./ddbClient.js";

export const handler = async (event, context, callback) => {
    
    const response = {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin" : origin,
        "Access-Control-Allow-Methods": "*",
        "Access-Control-Allow-Headers": "Authorization, Access-Control-Allow-Origin, Access-Control-Allow-Methods, Access-Control-Allow-Headers, Access-Control-Allow-Credentials, Content-Type, isBase64Encoded, x-requested-with",
        "Access-Control-Allow-Credentials" : true,
        'Content-Type': 'application/json',
        "isBase64Encoded": false
      },
    };
    
    if(event["httpMethod"] == "OPTIONS") {
      callback(null, response);
      return;
    }
    
    switch(event["path"]) {
      
      case "/signup":
        const resultSignUp = await processSignUp(event);
        response.body = JSON.stringify(resultSignUp.body);
        response.statusCode = resultSignUp.statusCode;
        break;
        
      case "/signin":
        const resultSignIn = await processSignIn(event);
        response.body = JSON.stringify(resultSignIn.body);
        response.statusCode = resultSignIn.statusCode;
        break;
        
      case "/verify":
        const resultVerify = await processVerify(event);
        response.body = JSON.stringify(resultVerify.body);
        response.statusCode = resultVerify.statusCode;
        break;
        
      case "/validate":
        const resultValidate = await processValidate(event);
        response.body = JSON.stringify(resultValidate.body);
        response.statusCode = resultValidate.statusCode;
        break;
        
      case "/refresh":
        const resultRefresh = await processRefresh(event);
        response.body = JSON.stringify(resultRefresh.body);
        response.statusCode = resultRefresh.statusCode;
        break;
        
      case "/resend":
        const resultResend = await processResend(event);
        response.body = JSON.stringify(resultResend.body);
        response.statusCode = resultResend.statusCode;
        break;
        
      case "/detailuser":
        const resultDetailUser = await processDetailUser(event);
        response.body = JSON.stringify(resultDetailUser.body);
        response.statusCode = resultDetailUser.statusCode; 
        break;
      
      case "/logoutuser":
        const resultLogoutUser = await processLogoutUser(event);
        response.body = JSON.stringify(resultLogoutUser.body);
        response.statusCode = resultLogoutUser.statusCode; 
        break;
        
      case "/suspenduser":
        const resultSuspendUser = await processSuspendUser(event);
        response.body = JSON.stringify(resultSuspendUser.body);
        response.statusCode = resultSuspendUser.statusCode; 
        break;
        
      case "/resumeuser":
        const resultResumeUser = await processResumeUser(event);
        response.body = JSON.stringify(resultResumeUser.body);
        response.statusCode = resultResumeUser.statusCode; 
        break;
        
      case "/updateuser":
        const resultUpdateUser = await processUpdateUser(event);
        response.body = JSON.stringify(resultUpdateUser.body);
        response.statusCode = resultUpdateUser.statusCode; 
        break;
        
      case "/listlogs":
        const resultListLogs = await processListLogs(event);
        response.body = JSON.stringify(resultListLogs.body);
        response.statusCode = resultListLogs.statusCode; 
        break;
        
      default:
        response.body = JSON.stringify({result: false, error: "Method not found"});
        response.statusCode = 404;
      
      
    }
    
    // response.body = JSON.stringify(event);
    
    callback(null, response);
    
}