###########
# Script Config
###########

adminemail=P_ADMIN_EMAIL
correspondenceemail=P_CORRESPONDENCE_EMAIL
awsregion=P_AWS_REGION
awsaccount=P_AWS_ACCOUNT
apistage=P_API_STAGE
weborigin=P_WEB_ORIGIN
appname=P_APP_NAME
tablename=P_TABLE_NAME
logtablename=P_LOG_TABLE_NAME
rolename=P_ROLE_NAME
policyname=P_POLICY_NAME
functionname=P_FUNCTION_NAME
api=P_API

###########
# Script Config Ends
###########

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'
TBOLD=$(tput bold)
TNORMAL=$(tput sgr0)

INSTRUCTION=">> Instruction"
NEXTSTEPS=">> Next Steps"
NEXTSTEPSINSTRUCTION="š¬ Do what the instruction says, then come back here and run me again"
EXITMESSAGE="Exiting for now..."

echo -e "\nHello there! I will be guiding you today to complete the aws configuration. There are a few steps involved, but you needn't worry, I will do all the heavy lifting for you š. In between though, I will need some inputs from you and will need you to follow my instructions. Just stay with me and I think you'll be good!\n";

###########
# SES Config
###########

echo -e "========================="
echo -e "Step 1: SES Configuration"
echo -e "========================="

echo -e "\n>> Correspondence email: ${TBOLD}$correspondenceemail${TNORMAL}";

createidentitycommand="aws sesv2 create-email-identity --email-identity $correspondenceemail";

createidentity=`eval "$createidentitycommand | jq '.IdentityType'"`;

if [ -z "$createidentity" ]
then
      echo -e "\nš¬ Email identity ${TBOLD}$correspondenceemail${TNORMAL} creation FAILED ${RED} x ${NC}";
      echo -e "\nš¬ Email identity probably already exists in your AWS SES account, moving ahead with it\n" 
else
      echo -e "\nš¬ Email identity ${TBOLD}$correspondenceemail${TNORMAL} creation SUCCESSFUL ${GREEN} ā ${NC}: $createidentity\n";
fi

echo -e "ā³ Checking the status of Email identity ${TBOLD}$correspondenceemail${TNORMAL}";

getidentitycommand="aws sesv2 get-email-identity --email-identity $correspondenceemail";

getidentity=`eval "$getidentitycommand | jq '.VerifiedForSendingStatus'"`;

if [ "$getidentity" = true ]
then
      echo -e "\nš¬ Email identity ${TBOLD}$correspondenceemail${TNORMAL} ready for sending ${GREEN} ā ${NC} emails";
else
      echo -e "\nš¬ SES: Email identity ${TBOLD}$correspondenceemail${TNORMAL} not yet ready for sending ${YELLOW} ā  ${NC} emails";
      echo -e "\n$INSTRUCTION"
      echo -e "š¬ Verification email has been sent to ${TBOLD}$correspondenceemail${TNORMAL}, verify it" 
      # echo -e "\n$NEXTSTEPS"
      # echo -e "$NEXTSTEPSINSTRUCTION\n" 
      # echo -e $EXITMESSAGE;
      # exit 1;

fi

echo -e "\nš¬ SES configuration completed successfully for ${TBOLD}$correspondenceemail${TNORMAL} ${GREEN} ā ${NC}\n" 

sleep 5

###########
# DyanmoDB Config
###########

echo -e "=============================="
echo -e "Step 2: DynamoDB Configuration"
echo -e "=============================="

echo -e "\n>> Table: ${TBOLD}$tablename${TNORMAL}";

echo -e "\nā³ Checking if ${TBOLD}$tablename${TNORMAL} exists"

tableexistscommand="aws dynamodb describe-table --table-name $tablename";

tableexists=`eval "$tableexistscommand | jq '.Table.TableArn'"`;

if [ -z "$tableexists" ]
then
      echo -e "\nš¬ Table ${TBOLD}$tablename${TNORMAL} does not exist ${YELLOW} ā  ${NC}, creating it";
      echo -e "\nā³ Creating table ${TBOLD}$tablename${TNORMAL} exists, moving ahead with it";
      newtable=`aws dynamodb create-table \
      --table-name $tablename \
      --attribute-definitions AttributeName=email,AttributeType=S \
      --key-schema AttributeName=email,KeyType=HASH \
      --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=5 | jq '.TableDescription.TableArn'`
      if [ -z "$newtable" ]
      then
            echo -e "\nš¬ DynamoDb table creation FAILED ${RED} x ${NC}";
      else
            echo -e "\nš¬ DynamoDb table creation SUCCESSFUL ${GREEN} ā ${NC}: $newtable";
      fi
else
      echo -e "\nš¬ Table ${TBOLD}$tablename${TNORMAL} exists, moving ahead with it ${GREEN} ā ${NC}";
      newtable="$tableexists";
fi




echo -e "\n>> Table: ${TBOLD}$logtablename${TNORMAL}";

echo -e "\nā³ Checking if ${TBOLD}$logtablename${TNORMAL} exists"

logtableexistscommand="aws dynamodb describe-table --table-name $logtablename";

logtableexists=`eval "$logtableexistscommand | jq '.Table.TableArn'"`;

if [ -z "$logtableexists" ]
then
      echo -e "\nš¬ Table ${TBOLD}$logtablename${TNORMAL} does not exist ${YELLOW} ā  ${NC}, creating it";
      echo -e "\nā³ Creating table ${TBOLD}$logtablename${TNORMAL} exists, moving ahead with it";
      lognewtable=`aws dynamodb create-table \
      --table-name $logtablename \
      --attribute-definitions AttributeName=email,AttributeType=S AttributeName=timestamp,AttributeType=N \
      --key-schema AttributeName=email,KeyType=HASH AttributeName=timestamp,KeyType=RANGE \
      --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=5 | jq '.TableDescription.TableArn'`
      if [ -z "$lognewtable" ]
      then
            echo -e "\nš¬ DynamoDb table creation FAILED ${RED} x ${NC}";
      else
            echo -e "\nš¬ DynamoDb table creation SUCCESSFUL ${GREEN} ā ${NC}: $lognewtable";
      fi
else
      echo -e "\nš¬ Table ${TBOLD}$logtablename${TNORMAL} exists, moving ahead with it ${GREEN} ā ${NC}";
      lognewtable="$logtableexists";
fi




echo -e "\n>> Admin email: ${TBOLD}$adminemail${TNORMAL}";

echo -e "\nā³ Creating admin ${TBOLD}$adminemail${TNORMAL}";

sleep 10

putitemadmincommand="aws dynamodb put-item --table-name $tablename --item '{ \"email\": {\"S\": \"$adminemail\"}, \"admin\": {\"BOOL\": true}, \"name\": {\"S\": \"Administrator\"} }' --return-consumed-capacity TOTAL --return-item-collection-metrics SIZE"

putitemadmin=`eval "$putitemadmincommand | jq '.ConsumedCapacity'"`;

if [ -z "$putitemadmin" ]
then
      echo -e "\nš¬ Admin creation FAILED ${RED} x ${NC}";
else
      echo -e "\nš¬ Admin creation SUCCESSFUL ${GREEN} ā ${NC}: ${TBOLD}$adminemail${TNORMAL}";
fi

echo -e "\nš¬ DynamoDB configuration completed successfully for ${TBOLD}$tablename${TNORMAL} ${GREEN} ā ${NC}\n" 

###########
# Lambda Function Config
###########

echo -e "====================================="
echo -e "Step 3: Lambda Function Configuration"
echo -e "====================================="

echo -e "\n\nStep 3a: Policy Configuration"
echo -e "-----------------------------"

echo -e "\n>> Policy: ${TBOLD}$policyname${TNORMAL}";

echo -e "\nā³ Checking if ${TBOLD}$policyname${TNORMAL} exists";

getpolicycommand="aws iam get-policy --policy-arn arn:aws:iam::$awsaccount:policy/$policyname"

getpolicy=`eval "$getpolicycommand | jq '.Policy.Arn'"`;
getpolicyversion=`eval "$getpolicycommand | jq '.Policy.DefaultVersionId'"`;

if [ -z "$getpolicy" ]
then
      echo -e "\nš¬ Policy ${GREEN} ā ${NC}: ${TBOLD}$policyname${TNORMAL} does not exist ${RED} x ${NC}";
      echo -e "\nā³ Creating policy ${TBOLD}$policyname${TNORMAL}";
      policydocument="{\"Version\": \"2012-10-17\", \"Statement\": [{\"Sid\": \"Stmt1674124196543\",\"Action\": \"dynamodb:*\",\"Effect\": \"Allow\",\"Resource\": ${newtable}}, {\"Sid\": \"Stmt1674124196544\",\"Action\": \"dynamodb:*\",\"Effect\": \"Allow\",\"Resource\": ${lognewtable}}, {\"Sid\": \"VisualEditor0\",\"Effect\": \"Allow\",\"Action\": [\"ses:SendEmail\",\"ses:SendTemplatedEmail\",\"ses:SendRawEmail\"],\"Resource\": \"*\"}]}"
      policycommand="aws iam create-policy --policy-name $policyname --policy-document '$policydocument'";
      policy=`eval "$policycommand | jq '.Policy.Arn'"`;
      getpolicy="$policy";
      if [ -z "$policy" ]
      then
            echo -e "š¬ Policy creation FAILED ${RED} x ${NC}";
      else
            echo -e "š¬ Policy creation SUCCESSFUL ${GREEN} ā ${NC}: $policy";
      fi
else
      echo -e "\nš¬ Policy ${TBOLD}$policyname${TNORMAL} exists ${GREEN} ā ${NC}";
      echo -e "\nā³ Checking details of policy ${TBOLD}$policyname${TNORMAL}";
      getpolicyversioncommand="aws iam get-policy-version --policy-arn $getpolicy --version-id $getpolicyversion";
      getpolicyversion=`eval "$getpolicyversioncommand | jq '.PolicyVersion.Document'"`
      
      if [[ "$getpolicyversion" == *"dynamodb:*"* ]] && [[ "$getpolicyversion" == *"$newtable"* ]] && [[ "$getpolicyversion" == *"Allow"* ]]; then
            echo -e "\nš¬ Policy ${TBOLD}$policyname${TNORMAL} details look good ${GREEN} ā ${NC}";
      else 
            echo -e "\nš¬ Policy ${TBOLD}$policyname${TNORMAL} configuration is not according to the requirements ${RED} x ${NC}";
            echo -e "\n$INSTRUCTION"
            echo -e "š¬ Change the policy name at the top of the script" 
            echo -e "\n$NEXTSTEPS"
            echo -e "$NEXTSTEPSINSTRUCTION\n" 
            echo -e $EXITMESSAGE;
            exit 1;
      fi
      # deletepolicy=`eval "$deletepolicycommand"`
fi

sleep 5

echo -e "\n\nStep 3b: Role Configuration"
echo -e "---------------------------"

echo -e "\n>> Role: ${TBOLD}$rolename${TNORMAL}";

echo -e "\nā³ Checking if ${TBOLD}$rolename${TNORMAL} exists";

getrolecommand="aws iam get-role --role-name $rolename"

getrole=`eval "$getrolecommand | jq '.Role'"`;

if [ -z "$getrole" ]
then
      echo -e "\nš¬ Role ${GREEN} ā ${NC}: ${TBOLD}$rolename${TNORMAL} does not exist ${RED} x ${NC}";
      echo -e "\nā³ Creating role ${TBOLD}$rolename${TNORMAL}";
      rolecommand="aws iam create-role --role-name $rolename --assume-role-policy-document '{\"Version\": \"2012-10-17\",\"Statement\": [{ \"Effect\": \"Allow\", \"Principal\": {\"Service\": \"lambda.amazonaws.com\"}, \"Action\": \"sts:AssumeRole\"}]}'";

      role=`eval "$rolecommand" | jq '.Role.Arn'`;

      if [ -z "$role" ]
      then
            echo -e "\nš¬ Role creation FAILED ${RED} x ${NC}";
            exit;
      else
            echo -e "\nš¬ Role creation SUCCESSFUL ${GREEN} ā ${NC}: $role";
      fi

      echo -e "\nā³ Attaching policy to role ${TBOLD}$rolename${TNORMAL}";
      attachrolepolicycommand="aws iam attach-role-policy --role-name $rolename --policy-arn $getpolicy"
      attachrolepolicy=`eval "$attachrolepolicycommand"`;

      echo -e "\nš¬ Policy attach SUCCESSFUL ${GREEN} ā ${NC}: $rolename > $policyname";
      
else
      echo -e "\nš¬ Role ${TBOLD}$rolename${TNORMAL} exists ${GREEN} ā ${NC}";
      echo -e "\nā³ Checking details of role ${TBOLD}$rolename${TNORMAL}";
      
      role=`eval "$getrolecommand | jq '.Role.Arn'"`;

      if [[ "$getrole" == *"lambda.amazonaws.com"* ]] && [[ "$getrole" == *"sts:AssumeRole"* ]]; then
            echo -e "\nš¬ Role ${TBOLD}$rolename${TNORMAL} details look good ${GREEN} ā ${NC}";
            echo -e "\nā³ Checking policy of role ${TBOLD}$rolename${TNORMAL}";
            getrolepolicycommand="aws iam list-attached-role-policies --role-name $rolename";
            getrolepolicy=`eval "$getrolepolicycommand | jq '.AttachedPolicies | .[] | select(.PolicyName==\"$policyname\") | .PolicyName '"`;
            if [ -z "$getrolepolicy" ]
            then
                  echo -e "\nš¬ Role ${TBOLD}$rolename${TNORMAL} configuration is not according to the requirements ${RED} x ${NC}";
                  echo -e "\n$INSTRUCTION"
                  echo -e "š¬ Change the role name at the top of the script" 
                  echo -e "\n$NEXTSTEPS"
                  echo -e "$NEXTSTEPSINSTRUCTION\n" 
                  echo -e $EXITMESSAGE;
                  exit 1;
            else
                  echo -e "\nš¬ Role ${TBOLD}$rolename${TNORMAL} configuration is good ${GREEN} ā ${NC}";
            fi
            
      else 
            echo -e "\nš¬ Role ${TBOLD}$rolename${TNORMAL} configuration is not according to the requirements ${RED} x ${NC}";
            echo -e "\n$INSTRUCTION"
            echo -e "š¬ Change the role name at the top of the script" 
            echo -e "\n$NEXTSTEPS"
            echo -e "$NEXTSTEPSINSTRUCTION\n" 
            echo -e $EXITMESSAGE;
            exit 1;
      fi
fi

sleep 10

echo -e "\n\nStep 3c: Lambda Function Configuration"
echo -e "--------------------------------------"

echo -e "\n>> Function: ${TBOLD}$functionname${TNORMAL}";

echo -e "\nā³ Preparing function code ${TBOLD}$rolename${TNORMAL}";

rm -r aws_proc

cp -r aws aws_proc

find ./aws_proc -name '*.js' -exec sed -i -e "s|AWS_REGION|$awsregion|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|DB_TABLE_NAME|$tablename|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|DB_LOG_TABLE_NAME|$logtablename|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|WEB_ORIGIN|$weborigin|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|APP_NAME|$appname|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|CORRESP_EMAIL|$correspondenceemail|g" {} \;

zip -r -j ./aws_proc/auth.zip aws_proc/auth/*

echo -e "\nā³ Checking if function ${TBOLD}$functionname${TNORMAL} exists";

getfunctioncommand="aws lambda get-function --function-name $functionname";

getfunction=`eval "$getfunctioncommand | jq '.Configuration.FunctionArn'"`;

if [ -z "$getfunction" ]
then
      echo -e "\nš¬ Function doesn't exist ${RED} x ${NC}: $functionname";
      echo -e "\nā³ Creating function ${TBOLD}$rolename${TNORMAL}";
      createfunctioncommand="aws lambda create-function --function-name $functionname --zip-file fileb://aws_proc/auth.zip --handler index.handler --runtime nodejs18.x --timeout 30 --role $role"
      echo $createfunctioncommand;
      createfunction=`eval "$createfunctioncommand | jq '.FunctionArn'"`;
      getfunction="$createfunction";
      if [ -z "$createfunction" ]
      then
            echo -e "\nš¬ Function creation FAILED ${RED} x ${NC}";
            exit 1;
      else
            echo -e "\nš¬ Function creation SUCCESSFUL ${GREEN} ā ${NC}: $functionname";
      fi
else
      echo -e "\nš¬ Function exists ${GREEN} ā ${NC}: $functionname";
      # TODO: Update code zip
fi

echo -e "\nš¬ Lambda configuration completed successfully for ${TBOLD}$functionname${TNORMAL} ${GREEN} ā ${NC}\n" 

sleep 10

###########
# API Gateway Config
###########

echo -e "================================="
echo -e "Step 4: API Gateway Configuration"
echo -e "================================="

echo -e "\n\nStep 4a: Create API"
echo -e "------------------"

echo -e "\nā³ Creating API Gateway";

createapicommand="aws apigateway create-rest-api --name '$api' --region $awsregion";

createapi=`eval "$createapicommand" | jq '.id'`;

if [ -z "$createapi" ]
then
      echo -e "API creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ API creation SUCCESSFUL ${GREEN} ā ${NC}: -API-$createapi-API-";
fi

echo -e "\nā³ Getting resource handle";

getresourcescommand="aws apigateway get-resources --rest-api-id $createapi --region $awsregion"

getresources=`eval "$getresourcescommand | jq '.items | .[] | .id'"`

echo -e "\nš¬ API resource obtained ${GREEN} ā ${NC}: $getresources";

echo -e "\n\nStep 4b: SignUp"
echo -e "--------------"

echo -e "\nā³ Creating signup method";

createresourcesignupcommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part signup";

createresourcesignup=`eval "$createresourcesignupcommand | jq '.id'"`

if [ -z "$createresourcesignup" ]
then
      echo -e "\nš¬ Signup resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Signup resource creation SUCCESSFUL ${GREEN} ā ${NC}: $createresourcesignup";
fi

putmethodsignupcommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcesignup --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodsignup=`eval "$putmethodsignupcommand | jq '.httpMethod'"`

if [ -z "$putmethodsignup" ]
then
      echo -e "\nš¬ Signup method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Signup method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodsignup";
fi


putmethodsignupoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcesignup --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodsignupoptions=`eval "$putmethodsignupoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodsignupoptions" ]
then
      echo -e "\nš¬ Signup options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Signup options method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodsignupoptions";
fi



echo -e "\nā³ Creating lambda integration";

putintegrationsignupcommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcesignup --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationsignup=`eval "$putintegrationsignupcommand | jq '.passthroughBehavior'"`;

putintegrationsignupoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcesignup --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationsignupoptions=`eval "$putintegrationsignupoptionscommand | jq '.passthroughBehavior'"`;

# putintegrationresponsesignup200command="aws apigateway put-integration-response --region $awsregion --rest-api-id $createapi --resource-id $createresourcesignup --http-method POST --status-code 200 --selection-pattern \"\""

# putintegrationresponsesignup200=`eval "$putintegrationresponsesignup200command | jq '.statusCode'"`

echo -e "\nā³ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionsignupcommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/signup\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionsignup=`eval "$lambdaaddpermissionsignupcommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionsignup" ]
then
      echo -e "\nš¬ Signup lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Signup lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionsignup";
fi

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionsignupoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/signup\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionsignupoptions=`eval "$lambdaaddpermissionsignupoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionsignupoptions" ]
then
      echo -e "\nš¬ Signup options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Signup options lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionsignup";
fi


echo -e "\n\nStep 4c: SignIn"
echo -e "--------------"

echo -e "\nā³ Creating signin method";

createresourcesignincommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part signin";

createresourcesignin=`eval "$createresourcesignincommand | jq '.id'"`

if [ -z "$createresourcesignin" ]
then
      echo -e "\nš¬ Signin resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Signin resource creation SUCCESSFUL ${GREEN} ā ${NC}: $createresourcesignin";
fi

putmethodsignincommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcesignin --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodsignin=`eval "$putmethodsignincommand | jq '.httpMethod'"`

if [ -z "$putmethodsignin" ]
then
      echo -e "\nš¬ Signin method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Signin method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodsignin";
fi


putmethodsigninoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcesignin --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodsigninoptions=`eval "$putmethodsigninoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodsigninoptions" ]
then
      echo -e "\nš¬ Signin options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Signin options method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodsigninoptions";
fi



echo -e "\nā³ Creating lambda integration";

putintegrationsignincommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcesignin --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationsignin=`eval "$putintegrationsignincommand | jq '.passthroughBehavior'"`;


putintegrationsigninoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcesignin --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationsigninoptions=`eval "$putintegrationsigninoptionscommand | jq '.passthroughBehavior'"`;


# putintegrationresponsesignin200command="aws apigateway put-integration-response --region $awsregion --rest-api-id $createapi --resource-id $createresourcesignin --http-method POST --status-code 200 --selection-pattern \"\""

# putintegrationresponsesignin200=`eval "$putintegrationresponsesignin200command | jq '.statusCode'"`

echo -e "\nā³ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionsignincommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/signin\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionsignin=`eval "$lambdaaddpermissionsignincommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionsignin" ]
then
      echo -e "\nš¬ Signin lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Signin lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionsignin";
fi

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionsigninoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/signin\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionsigninoptions=`eval "$lambdaaddpermissionsigninoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionsigninoptions" ]
then
      echo -e "\nš¬ Signin options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Signin options lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionsignin";
fi




echo -e "\n\nStep 4d: Verify"
echo -e "--------------"

echo -e "\nā³ Creating verify method";

createresourceverifycommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part verify";

createresourceverify=`eval "$createresourceverifycommand | jq '.id'"`

if [ -z "$createresourceverify" ]
then
      echo -e "\nš¬ Verify resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Verify resource creation SUCCESSFUL ${GREEN} ā ${NC}: $createresourceverify";
fi

putmethodverifycommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourceverify --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodverify=`eval "$putmethodverifycommand | jq '.httpMethod'"`

if [ -z "$putmethodverify" ]
then
      echo -e "\nš¬ Verify method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Verify method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodverify";
fi


putmethodverifyoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourceverify --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodverifyoptions=`eval "$putmethodverifyoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodverifyoptions" ]
then
      echo -e "\nš¬ Verify options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Verify options method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodverifyoptions";
fi


echo -e "\nā³ Creating lambda integration";

putintegrationverifycommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourceverify --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationverify=`eval "$putintegrationverifycommand | jq '.passthroughBehavior'"`;

putintegrationverifyoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourceverify --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationverifyoptions=`eval "$putintegrationverifyoptionscommand | jq '.passthroughBehavior'"`;

# putintegrationresponseverify200command="aws apigateway put-integration-response --region $awsregion --rest-api-id $createapi --resource-id $createresourceverify --http-method POST --status-code 200 --selection-pattern \"\""

# putintegrationresponseverify200=`eval "$putintegrationresponseverify200command | jq '.statusCode'"`

echo -e "\nā³ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionverifycommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/verify\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionverify=`eval "$lambdaaddpermissionverifycommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionverify" ]
then
      echo -e "\nš¬ Verify lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Verify lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionverify";
fi


random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionverifyoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/verify\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionverifyoptions=`eval "$lambdaaddpermissionverifyoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionverifyoptions" ]
then
      echo -e "\nš¬ Verify options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Verify options lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionverifyoptions";
fi



echo -e "\n\nStep 4e: Validate"
echo -e "--------------"

echo -e "\nā³ Creating validate method";

createresourcevalidatecommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part validate";

createresourcevalidate=`eval "$createresourcevalidatecommand | jq '.id'"`

if [ -z "$createresourcevalidate" ]
then
      echo -e "\nš¬ Validate resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Validate resource creation SUCCESSFUL ${GREEN} ā ${NC}: $createresourcevalidate";
fi

putmethodvalidatecommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcevalidate --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodvalidate=`eval "$putmethodvalidatecommand | jq '.httpMethod'"`

if [ -z "$putmethodvalidate" ]
then
      echo -e "\nš¬ Validate method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Validate method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodvalidate";
fi


echo -e "\nā³ Creating lambda integration";

putintegrationvalidatecommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcevalidate --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationvalidate=`eval "$putintegrationvalidatecommand | jq '.passthroughBehavior'"`;

echo -e "\nā³ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionvalidatecommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/validate\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionvalidate=`eval "$lambdaaddpermissionvalidatecommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionvalidate" ]
then
      echo -e "\nš¬ Validate lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Validate lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionvalidate";
fi




echo -e "\n\nStep 4f: Refresh"
echo -e "--------------"

echo -e "\nā³ Creating refresh method";

createresourcerefreshcommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part refresh";

createresourcerefresh=`eval "$createresourcerefreshcommand | jq '.id'"`

if [ -z "$createresourcerefresh" ]
then
      echo -e "\nš¬ Refresh resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Refresh resource creation SUCCESSFUL ${GREEN} ā ${NC}: $createresourcerefresh";
fi

putmethodrefreshcommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcerefresh --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodrefresh=`eval "$putmethodrefreshcommand | jq '.httpMethod'"`

if [ -z "$putmethodrefresh" ]
then
      echo -e "\nš¬ Refresh method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Refresh method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodrefresh";
fi

putmethodrefreshoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcerefresh --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodrefreshoptions=`eval "$putmethodrefreshoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodrefreshoptions" ]
then
      echo -e "\nš¬ Refresh options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Refresh options method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodrefreshoptions";
fi


echo -e "\nā³ Creating lambda integration";

putintegrationrefreshcommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcerefresh --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationrefresh=`eval "$putintegrationrefreshcommand | jq '.passthroughBehavior'"`;

putintegrationrefreshoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcerefresh --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationrefreshoptions=`eval "$putintegrationrefreshoptionscommand | jq '.passthroughBehavior'"`;

echo -e "\nā³ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionrefreshcommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/refresh\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionrefresh=`eval "$lambdaaddpermissionrefreshcommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionrefresh" ]
then
      echo -e "\nš¬ Refresh lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Refresh lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionrefresh";
fi


random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionrefreshoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/refresh\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionrefreshoptions=`eval "$lambdaaddpermissionrefreshoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionrefreshoptions" ]
then
      echo -e "\nš¬ Refresh options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Refresh options lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionrefreshoptions";
fi



echo -e "\n\nStep 4g: Resend"
echo -e "--------------"

echo -e "\nā³ Creating resend method";

createresourceresendcommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part resend";

createresourceresend=`eval "$createresourceresendcommand | jq '.id'"`

if [ -z "$createresourceresend" ]
then
      echo -e "\nš¬ Resend resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Resend resource creation SUCCESSFUL ${GREEN} ā ${NC}: $createresourceresend";
fi

putmethodresendcommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourceresend --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodresend=`eval "$putmethodresendcommand | jq '.httpMethod'"`

if [ -z "$putmethodresend" ]
then
      echo -e "\nš¬ Resend method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Resend method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodresend";
fi

putmethodresendoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourceresend --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodresendoptions=`eval "$putmethodresendoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodresendoptions" ]
then
      echo -e "\nš¬ Resend options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ Resend options method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodresendoptions";
fi


echo -e "\nā³ Creating lambda integration";

putintegrationresendcommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourceresend --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationresend=`eval "$putintegrationresendcommand | jq '.passthroughBehavior'"`;

putintegrationresendoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourceresend --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationresendoptions=`eval "$putintegrationresendoptionscommand | jq '.passthroughBehavior'"`;


echo -e "\nā³ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionresendcommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/resend\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionresend=`eval "$lambdaaddpermissionresendcommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionresend" ]
then
      echo -e "\nš¬ Resend lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Resend lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionresend";
fi


random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionresendoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/resend\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionresendoptions=`eval "$lambdaaddpermissionresendoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionresendoptions" ]
then
      echo -e "\nš¬ Resend options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ Resend options lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionresendoptions";
fi



echo -e "\n\nStep 4h: DetailUser"
echo -e "--------------"

echo -e "\nā³ Creating detailuser method";

createresourcedetailusercommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part detailuser";

createresourcedetailuser=`eval "$createresourcedetailusercommand | jq '.id'"`

if [ -z "$createresourcedetailuser" ]
then
      echo -e "\nš¬ DetailUser resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ DetailUser resource creation SUCCESSFUL ${GREEN} ā ${NC}: $createresourcedetailuser";
fi

putmethoddetailusercommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcedetailuser --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethoddetailuser=`eval "$putmethoddetailusercommand | jq '.httpMethod'"`

if [ -z "$putmethoddetailuser" ]
then
      echo -e "\nš¬ DetailUser method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ DetailUser method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethoddetailuser";
fi

putmethoddetailuseroptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcedetailuser --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethoddetailuseroptions=`eval "$putmethoddetailuseroptionscommand | jq '.httpMethod'"`

if [ -z "$putmethoddetailuseroptions" ]
then
      echo -e "\nš¬ DetailUser options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ DetailUser options method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethoddetailuseroptions";
fi


echo -e "\nā³ Creating lambda integration";

putintegrationdetailusercommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcedetailuser --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationdetailuser=`eval "$putintegrationdetailusercommand | jq '.passthroughBehavior'"`;

putintegrationdetailuseroptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcedetailuser --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationdetailuseroptions=`eval "$putintegrationdetailuseroptionscommand | jq '.passthroughBehavior'"`;


echo -e "\nā³ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissiondetailusercommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/detailuser\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissiondetailuser=`eval "$lambdaaddpermissiondetailusercommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissiondetailuser" ]
then
      echo -e "\nš¬ DetailUser lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ DetailUser lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissiondetailuser";
fi


random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissiondetailuseroptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/detailuser\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissiondetailuseroptions=`eval "$lambdaaddpermissiondetailuseroptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissiondetailuseroptions" ]
then
      echo -e "\nš¬ DetailUser options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ DetailUser options lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissiondetailuseroptions";
fi



echo -e "\n\nStep 4i: LogoutUser"
echo -e "--------------"

echo -e "\nā³ Creating logoutuser method";

createresourcelogoutusercommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part logoutuser";

createresourcelogoutuser=`eval "$createresourcelogoutusercommand | jq '.id'"`

if [ -z "$createresourcelogoutuser" ]
then
      echo -e "\nš¬ LogoutUser resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ LogoutUser resource creation SUCCESSFUL ${GREEN} ā ${NC}: $createresourcelogoutuser";
fi

putmethodlogoutusercommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcelogoutuser --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodlogoutuser=`eval "$putmethodlogoutusercommand | jq '.httpMethod'"`

if [ -z "$putmethodlogoutuser" ]
then
      echo -e "\nš¬ LogoutUser method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ LogoutUser method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodlogoutuser";
fi

putmethodlogoutuseroptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcelogoutuser --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodlogoutuseroptions=`eval "$putmethodlogoutuseroptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodlogoutuseroptions" ]
then
      echo -e "\nš¬ LogoutUser options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ LogoutUser options method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodlogoutuseroptions";
fi


echo -e "\nā³ Creating lambda integration";

putintegrationlogoutusercommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcelogoutuser --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationlogoutuser=`eval "$putintegrationlogoutusercommand | jq '.passthroughBehavior'"`;

putintegrationlogoutuseroptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcelogoutuser --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationlogoutuseroptions=`eval "$putintegrationlogoutuseroptionscommand | jq '.passthroughBehavior'"`;


echo -e "\nā³ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionlogoutusercommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/logoutuser\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionlogoutuser=`eval "$lambdaaddpermissionlogoutusercommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionlogoutuser" ]
then
      echo -e "\nš¬ LogoutUser lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ LogoutUser lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionlogoutuser";
fi


random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionlogoutuseroptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/logoutuser\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionlogoutuseroptions=`eval "$lambdaaddpermissionlogoutuseroptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionlogoutuseroptions" ]
then
      echo -e "\nš¬ LogoutUser options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ LogoutUser options lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionlogoutuseroptions";
fi




echo -e "\n\nStep 4j: ListLogs"
echo -e "--------------"

echo -e "\nā³ Creating listlogs method";

createresourcelistlogscommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part listlogs";

createresourcelistlogs=`eval "$createresourcelistlogscommand | jq '.id'"`

if [ -z "$createresourcelistlogs" ]
then
      echo -e "\nš¬ ListLogs resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ ListLogs resource creation SUCCESSFUL ${GREEN} ā ${NC}: $createresourcelistlogs";
fi

putmethodlistlogscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcelistlogs --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodlistlogs=`eval "$putmethodlistlogscommand | jq '.httpMethod'"`

if [ -z "$putmethodlistlogs" ]
then
      echo -e "\nš¬ ListLogs method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ ListLogs method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodlistlogs";
fi

putmethodlistlogsoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcelistlogs --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodlistlogsoptions=`eval "$putmethodlistlogsoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodlistlogsoptions" ]
then
      echo -e "\nš¬ ListLogs options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\nš¬ ListLogs options method creation SUCCESSFUL ${GREEN} ā ${NC}: $putmethodlistlogsoptions";
fi


echo -e "\nā³ Creating lambda integration";

putintegrationlistlogscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcelistlogs --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationlistlogs=`eval "$putintegrationlistlogscommand | jq '.passthroughBehavior'"`;

putintegrationlistlogsoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcelistlogs --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationlistlogsoptions=`eval "$putintegrationlistlogsoptionscommand | jq '.passthroughBehavior'"`;


echo -e "\nā³ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionlistlogscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/listlogs\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionlistlogs=`eval "$lambdaaddpermissionlistlogscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionlistlogs" ]
then
      echo -e "\nš¬ ListLogs lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ ListLogs lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionlistlogs";
fi


random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionlistlogsoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/listlogs\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionlistlogsoptions=`eval "$lambdaaddpermissionlistlogsoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionlistlogsoptions" ]
then
      echo -e "\nš¬ ListLogs options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\nš¬ ListLogs options lambda invoke grant creation SUCCESSFUL ${GREEN} ā ${NC}: $lambdaaddpermissionlistlogsoptions";
fi



echo -e "\nā³ Deploying API Gateway function";

createdeploymentcommand="aws apigateway create-deployment --rest-api-id $createapi --stage-name $apistage --region $awsregion"

createdeployment=`eval "$createdeploymentcommand | jq '.id'"`

if [ -z "$createdeployment" ]
then
    echo -e "\nš¬ Auth deployment creation FAILED ${RED} x ${NC}";
else
    echo -e "\nš¬ Auth deployment creation SUCCESSFUL ${GREEN} ā ${NC}: $createdeployment";
fi


echo -e "Script Ended...\n";
