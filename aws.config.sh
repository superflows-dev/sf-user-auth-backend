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
NEXTSTEPSINSTRUCTION="💬 Do what the instruction says, then come back here and run me again"
EXITMESSAGE="Exiting for now..."

echo -e "\nHello there! I will be guiding you today to complete the aws configuration. There are a few steps involved, but you needn't worry, I will do all the heavy lifting for you 😀. In between though, I will need some inputs from you and will need you to follow my instructions. Just stay with me and I think you'll be good!\n";

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
      echo -e "\n💬 Email identity ${TBOLD}$correspondenceemail${TNORMAL} creation FAILED ${RED} x ${NC}";
      echo -e "\n💬 Email identity probably already exists in your AWS SES account, moving ahead with it\n" 
else
      echo -e "\n💬 Email identity ${TBOLD}$correspondenceemail${TNORMAL} creation SUCCESSFUL ${GREEN} ✓ ${NC}: $createidentity\n";
fi

echo -e "⏳ Checking the status of Email identity ${TBOLD}$correspondenceemail${TNORMAL}";

getidentitycommand="aws sesv2 get-email-identity --email-identity $correspondenceemail";

getidentity=`eval "$getidentitycommand | jq '.VerifiedForSendingStatus'"`;

if [ "$getidentity" = true ]
then
      echo -e "\n💬 Email identity ${TBOLD}$correspondenceemail${TNORMAL} ready for sending ${GREEN} ✓ ${NC} emails";
else
      echo -e "\n💬 SES: Email identity ${TBOLD}$correspondenceemail${TNORMAL} not yet ready for sending ${YELLOW} ⚠ ${NC} emails";
      echo -e "\n$INSTRUCTION"
      echo -e "💬 Verification email has been sent to ${TBOLD}$correspondenceemail${TNORMAL}, verify it" 
      echo -e "\n$NEXTSTEPS"
      echo -e "$NEXTSTEPSINSTRUCTION\n" 
      echo -e $EXITMESSAGE;
      exit 1;

fi

echo -e "\n💬 SES configuration completed successfully for ${TBOLD}$correspondenceemail${TNORMAL} ${GREEN} ✓ ${NC}\n" 

sleep 5

###########
# DyanmoDB Config
###########

echo -e "=============================="
echo -e "Step 2: DynamoDB Configuration"
echo -e "=============================="

echo -e "\n>> Table: ${TBOLD}$tablename${TNORMAL}";

echo -e "\n⏳ Checking if ${TBOLD}$tablename${TNORMAL} exists"

tableexistscommand="aws dynamodb describe-table --table-name $tablename";

tableexists=`eval "$tableexistscommand | jq '.Table.TableArn'"`;

if [ -z "$tableexists" ]
then
      echo -e "\n💬 Table ${TBOLD}$tablename${TNORMAL} does not exist ${YELLOW} ⚠ ${NC}, creating it";
      echo -e "\n⏳ Creating table ${TBOLD}$tablename${TNORMAL} exists, moving ahead with it";
      newtable=`aws dynamodb create-table \
      --table-name $tablename \
      --attribute-definitions AttributeName=email,AttributeType=S \
      --key-schema AttributeName=email,KeyType=HASH \
      --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=5 | jq '.TableDescription.TableArn'`
      if [ -z "$newtable" ]
      then
            echo -e "\n💬 DynamoDb table creation FAILED ${RED} x ${NC}";
      else
            echo -e "\n💬 DynamoDb table creation SUCCESSFUL ${GREEN} ✓ ${NC}: $newtable";
      fi
else
      echo -e "\n💬 Table ${TBOLD}$tablename${TNORMAL} exists, moving ahead with it ${GREEN} ✓ ${NC}";
      newtable="$tableexists";
fi




echo -e "\n>> Table: ${TBOLD}$logtablename${TNORMAL}";

echo -e "\n⏳ Checking if ${TBOLD}$logtablename${TNORMAL} exists"

logtableexistscommand="aws dynamodb describe-table --table-name $logtablename";

logtableexists=`eval "$logtableexistscommand | jq '.Table.TableArn'"`;

if [ -z "$logtableexists" ]
then
      echo -e "\n💬 Table ${TBOLD}$logtablename${TNORMAL} does not exist ${YELLOW} ⚠ ${NC}, creating it";
      echo -e "\n⏳ Creating table ${TBOLD}$logtablename${TNORMAL} exists, moving ahead with it";
      lognewtable=`aws dynamodb create-table \
      --table-name $logtablename \
      --attribute-definitions AttributeName=email,AttributeType=S AttributeName=timestamp,AttributeType=N \
      --key-schema AttributeName=email,KeyType=HASH AttributeName=timestamp,KeyType=RANGE \
      --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=5 | jq '.TableDescription.TableArn'`
      if [ -z "$lognewtable" ]
      then
            echo -e "\n💬 DynamoDb table creation FAILED ${RED} x ${NC}";
      else
            echo -e "\n💬 DynamoDb table creation SUCCESSFUL ${GREEN} ✓ ${NC}: $lognewtable";
      fi
else
      echo -e "\n💬 Table ${TBOLD}$logtablename${TNORMAL} exists, moving ahead with it ${GREEN} ✓ ${NC}";
      lognewtable="$logtableexists";
fi




echo -e "\n>> Admin email: ${TBOLD}$adminemail${TNORMAL}";

echo -e "\n⏳ Creating admin ${TBOLD}$adminemail${TNORMAL}";

sleep 10

putitemadmincommand="aws dynamodb put-item --table-name $tablename --item '{ \"email\": {\"S\": \"$adminemail\"}, \"admin\": {\"BOOL\": true} }' --return-consumed-capacity TOTAL --return-item-collection-metrics SIZE"

putitemadmin=`eval "$putitemadmincommand | jq '.ConsumedCapacity'"`;

if [ -z "$putitemadmin" ]
then
      echo -e "\n💬 Admin creation FAILED ${RED} x ${NC}";
else
      echo -e "\n💬 Admin creation SUCCESSFUL ${GREEN} ✓ ${NC}: ${TBOLD}$adminemail${TNORMAL}";
fi

echo -e "\n💬 DynamoDB configuration completed successfully for ${TBOLD}$tablename${TNORMAL} ${GREEN} ✓ ${NC}\n" 

###########
# Lambda Function Config
###########

echo -e "====================================="
echo -e "Step 3: Lambda Function Configuration"
echo -e "====================================="

echo -e "\n\nStep 3a: Policy Configuration"
echo -e "-----------------------------"

echo -e "\n>> Policy: ${TBOLD}$policyname${TNORMAL}";

echo -e "\n⏳ Checking if ${TBOLD}$policyname${TNORMAL} exists";

getpolicycommand="aws iam get-policy --policy-arn arn:aws:iam::$awsaccount:policy/$policyname"

getpolicy=`eval "$getpolicycommand | jq '.Policy.Arn'"`;
getpolicyversion=`eval "$getpolicycommand | jq '.Policy.DefaultVersionId'"`;

if [ -z "$getpolicy" ]
then
      echo -e "\n💬 Policy ${GREEN} ✓ ${NC}: ${TBOLD}$policyname${TNORMAL} does not exist ${RED} x ${NC}";
      echo -e "\n⏳ Creating policy ${TBOLD}$policyname${TNORMAL}";
      policydocument="{\"Version\": \"2012-10-17\", \"Statement\": [{\"Sid\": \"Stmt1674124196543\",\"Action\": \"dynamodb:*\",\"Effect\": \"Allow\",\"Resource\": ${newtable}}, {\"Sid\": \"Stmt1674124196544\",\"Action\": \"dynamodb:*\",\"Effect\": \"Allow\",\"Resource\": ${lognewtable}}, {\"Sid\": \"VisualEditor0\",\"Effect\": \"Allow\",\"Action\": [\"ses:SendEmail\",\"ses:SendTemplatedEmail\",\"ses:SendRawEmail\"],\"Resource\": \"*\"}]}"
      policycommand="aws iam create-policy --policy-name $policyname --policy-document '$policydocument'";
      policy=`eval "$policycommand | jq '.Policy.Arn'"`;
      getpolicy="$policy";
      if [ -z "$policy" ]
      then
            echo -e "💬 Policy creation FAILED ${RED} x ${NC}";
      else
            echo -e "💬 Policy creation SUCCESSFUL ${GREEN} ✓ ${NC}: $policy";
      fi
else
      echo -e "\n💬 Policy ${TBOLD}$policyname${TNORMAL} exists ${GREEN} ✓ ${NC}";
      echo -e "\n⏳ Checking details of policy ${TBOLD}$policyname${TNORMAL}";
      getpolicyversioncommand="aws iam get-policy-version --policy-arn $getpolicy --version-id $getpolicyversion";
      getpolicyversion=`eval "$getpolicyversioncommand | jq '.PolicyVersion.Document'"`
      
      if [[ "$getpolicyversion" == *"dynamodb:*"* ]] && [[ "$getpolicyversion" == *"$newtable"* ]] && [[ "$getpolicyversion" == *"Allow"* ]]; then
            echo -e "\n💬 Policy ${TBOLD}$policyname${TNORMAL} details look good ${GREEN} ✓ ${NC}";
      else 
            echo -e "\n💬 Policy ${TBOLD}$policyname${TNORMAL} configuration is not according to the requirements ${RED} x ${NC}";
            echo -e "\n$INSTRUCTION"
            echo -e "💬 Change the policy name at the top of the script" 
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

echo -e "\n⏳ Checking if ${TBOLD}$rolename${TNORMAL} exists";

getrolecommand="aws iam get-role --role-name $rolename"

getrole=`eval "$getrolecommand | jq '.Role'"`;

if [ -z "$getrole" ]
then
      echo -e "\n💬 Role ${GREEN} ✓ ${NC}: ${TBOLD}$rolename${TNORMAL} does not exist ${RED} x ${NC}";
      echo -e "\n⏳ Creating role ${TBOLD}$rolename${TNORMAL}";
      rolecommand="aws iam create-role --role-name $rolename --assume-role-policy-document '{\"Version\": \"2012-10-17\",\"Statement\": [{ \"Effect\": \"Allow\", \"Principal\": {\"Service\": \"lambda.amazonaws.com\"}, \"Action\": \"sts:AssumeRole\"}]}'";

      role=`eval "$rolecommand" | jq '.Role.Arn'`;

      if [ -z "$role" ]
      then
            echo -e "\n💬 Role creation FAILED ${RED} x ${NC}";
            exit;
      else
            echo -e "\n💬 Role creation SUCCESSFUL ${GREEN} ✓ ${NC}: $role";
      fi

      echo -e "\n⏳ Attaching policy to role ${TBOLD}$rolename${TNORMAL}";
      attachrolepolicycommand="aws iam attach-role-policy --role-name $rolename --policy-arn $getpolicy"
      attachrolepolicy=`eval "$attachrolepolicycommand"`;

      echo -e "\n💬 Policy attach SUCCESSFUL ${GREEN} ✓ ${NC}: $rolename > $policyname";
      
else
      echo -e "\n💬 Role ${TBOLD}$rolename${TNORMAL} exists ${GREEN} ✓ ${NC}";
      echo -e "\n⏳ Checking details of role ${TBOLD}$rolename${TNORMAL}";
      
      role=`eval "$getrolecommand | jq '.Role.Arn'"`;

      if [[ "$getrole" == *"lambda.amazonaws.com"* ]] && [[ "$getrole" == *"sts:AssumeRole"* ]]; then
            echo -e "\n💬 Role ${TBOLD}$rolename${TNORMAL} details look good ${GREEN} ✓ ${NC}";
            echo -e "\n⏳ Checking policy of role ${TBOLD}$rolename${TNORMAL}";
            getrolepolicycommand="aws iam list-attached-role-policies --role-name $rolename";
            getrolepolicy=`eval "$getrolepolicycommand | jq '.AttachedPolicies | .[] | select(.PolicyName==\"$policyname\") | .PolicyName '"`;
            if [ -z "$getrolepolicy" ]
            then
                  echo -e "\n💬 Role ${TBOLD}$rolename${TNORMAL} configuration is not according to the requirements ${RED} x ${NC}";
                  echo -e "\n$INSTRUCTION"
                  echo -e "💬 Change the role name at the top of the script" 
                  echo -e "\n$NEXTSTEPS"
                  echo -e "$NEXTSTEPSINSTRUCTION\n" 
                  echo -e $EXITMESSAGE;
                  exit 1;
            else
                  echo -e "\n💬 Role ${TBOLD}$rolename${TNORMAL} configuration is good ${GREEN} ✓ ${NC}";
            fi
            
      else 
            echo -e "\n💬 Role ${TBOLD}$rolename${TNORMAL} configuration is not according to the requirements ${RED} x ${NC}";
            echo -e "\n$INSTRUCTION"
            echo -e "💬 Change the role name at the top of the script" 
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

echo -e "\n⏳ Preparing function code ${TBOLD}$rolename${TNORMAL}";

rm -r aws_proc

cp -r aws aws_proc

find ./aws_proc -name '*.js' -exec sed -i -e "s|AWS_REGION|$awsregion|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|DB_TABLE_NAME|$tablename|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|DB_LOG_TABLE_NAME|$logtablename|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|WEB_ORIGIN|$weborigin|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|APP_NAME|$appname|g" {} \;

zip -r -j ./aws_proc/auth.zip aws_proc/auth/*

echo -e "\n⏳ Checking if function ${TBOLD}$functionname${TNORMAL} exists";

getfunctioncommand="aws lambda get-function --function-name $functionname";

getfunction=`eval "$getfunctioncommand | jq '.Configuration.FunctionArn'"`;

if [ -z "$getfunction" ]
then
      echo -e "\n💬 Function doesn't exist ${RED} x ${NC}: $functionname";
      echo -e "\n⏳ Creating function ${TBOLD}$rolename${TNORMAL}";
      createfunctioncommand="aws lambda create-function --function-name $functionname --zip-file fileb://aws_proc/auth.zip --handler index.handler --runtime nodejs18.x --timeout 30 --role $role"
      echo $createfunctioncommand;
      createfunction=`eval "$createfunctioncommand | jq '.FunctionArn'"`;
      getfunction="$createfunction";
      if [ -z "$createfunction" ]
      then
            echo -e "\n💬 Function creation FAILED ${RED} x ${NC}";
            exit 1;
      else
            echo -e "\n💬 Function creation SUCCESSFUL ${GREEN} ✓ ${NC}: $functionname";
      fi
else
      echo -e "\n💬 Function exists ${GREEN} ✓ ${NC}: $functionname";
      # TODO: Update code zip
fi

echo -e "\n💬 Lambda configuration completed successfully for ${TBOLD}$functionname${TNORMAL} ${GREEN} ✓ ${NC}\n" 

sleep 10

###########
# API Gateway Config
###########

echo -e "================================="
echo -e "Step 4: API Gateway Configuration"
echo -e "================================="

echo -e "\n\nStep 4a: Create API"
echo -e "------------------"

echo -e "\n⏳ Creating API Gateway";

createapicommand="aws apigateway create-rest-api --name '$api' --region $awsregion";

createapi=`eval "$createapicommand" | jq '.id'`;

if [ -z "$createapi" ]
then
      echo -e "API creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 API creation SUCCESSFUL ${GREEN} ✓ ${NC}: $createapi";
fi

echo -e "\n⏳ Getting resource handle";

getresourcescommand="aws apigateway get-resources --rest-api-id $createapi --region $awsregion"

getresources=`eval "$getresourcescommand | jq '.items | .[] | .id'"`

echo -e "\n💬 API resource obtained ${GREEN} ✓ ${NC}: $getresources";

echo -e "\n\nStep 4b: SignUp"
echo -e "--------------"

echo -e "\n⏳ Creating signup method";

createresourcesignupcommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part signup";

createresourcesignup=`eval "$createresourcesignupcommand | jq '.id'"`

if [ -z "$createresourcesignup" ]
then
      echo -e "\n💬 Signup resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 Signup resource creation SUCCESSFUL ${GREEN} ✓ ${NC}: $createresourcesignup";
fi

putmethodsignupcommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcesignup --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodsignup=`eval "$putmethodsignupcommand | jq '.httpMethod'"`

if [ -z "$putmethodsignup" ]
then
      echo -e "\n💬 Signup method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\n💬 Signup method creation SUCCESSFUL ${GREEN} ✓ ${NC}: $putmethodsignup";
fi


putmethodsignupoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcesignup --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodsignupoptions=`eval "$putmethodsignupoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodsignupoptions" ]
then
      echo -e "\n💬 Signup options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\n💬 Signup options method creation SUCCESSFUL ${GREEN} ✓ ${NC}: $putmethodsignupoptions";
fi



echo -e "\n⏳ Creating lambda integration";

putintegrationsignupcommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcesignup --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationsignup=`eval "$putintegrationsignupcommand | jq '.passthroughBehavior'"`;

putintegrationsignupoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcesignup --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationsignupoptions=`eval "$putintegrationsignupoptionscommand | jq '.passthroughBehavior'"`;

# putintegrationresponsesignup200command="aws apigateway put-integration-response --region $awsregion --rest-api-id $createapi --resource-id $createresourcesignup --http-method POST --status-code 200 --selection-pattern \"\""

# putintegrationresponsesignup200=`eval "$putintegrationresponsesignup200command | jq '.statusCode'"`

echo -e "\n⏳ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionsignupcommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/signup\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionsignup=`eval "$lambdaaddpermissionsignupcommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionsignup" ]
then
      echo -e "\n💬 Signup lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 Signup lambda invoke grant creation SUCCESSFUL ${GREEN} ✓ ${NC}: $lambdaaddpermissionsignup";
fi

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionsignupoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/signup\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionsignupoptions=`eval "$lambdaaddpermissionsignupoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionsignupoptions" ]
then
      echo -e "\n💬 Signup options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 Signup options lambda invoke grant creation SUCCESSFUL ${GREEN} ✓ ${NC}: $lambdaaddpermissionsignup";
fi


echo -e "\n\nStep 4c: SignIn"
echo -e "--------------"

echo -e "\n⏳ Creating signin method";

createresourcesignincommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part signin";

createresourcesignin=`eval "$createresourcesignincommand | jq '.id'"`

if [ -z "$createresourcesignin" ]
then
      echo -e "\n💬 Signin resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 Signin resource creation SUCCESSFUL ${GREEN} ✓ ${NC}: $createresourcesignin";
fi

putmethodsignincommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcesignin --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodsignin=`eval "$putmethodsignincommand | jq '.httpMethod'"`

if [ -z "$putmethodsignin" ]
then
      echo -e "\n💬 Signin method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\n💬 Signin method creation SUCCESSFUL ${GREEN} ✓ ${NC}: $putmethodsignin";
fi


putmethodsigninoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcesignin --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodsigninoptions=`eval "$putmethodsigninoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodsigninoptions" ]
then
      echo -e "\n💬 Signin options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\n💬 Signin options method creation SUCCESSFUL ${GREEN} ✓ ${NC}: $putmethodsigninoptions";
fi



echo -e "\n⏳ Creating lambda integration";

putintegrationsignincommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcesignin --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationsignin=`eval "$putintegrationsignincommand | jq '.passthroughBehavior'"`;


putintegrationsigninoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcesignin --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationsigninoptions=`eval "$putintegrationsigninoptionscommand | jq '.passthroughBehavior'"`;


# putintegrationresponsesignin200command="aws apigateway put-integration-response --region $awsregion --rest-api-id $createapi --resource-id $createresourcesignin --http-method POST --status-code 200 --selection-pattern \"\""

# putintegrationresponsesignin200=`eval "$putintegrationresponsesignin200command | jq '.statusCode'"`

echo -e "\n⏳ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionsignincommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/signin\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionsignin=`eval "$lambdaaddpermissionsignincommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionsignin" ]
then
      echo -e "\n💬 Signin lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 Signin lambda invoke grant creation SUCCESSFUL ${GREEN} ✓ ${NC}: $lambdaaddpermissionsignin";
fi

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionsigninoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/signin\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionsigninoptions=`eval "$lambdaaddpermissionsigninoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionsigninoptions" ]
then
      echo -e "\n💬 Signin options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 Signin options lambda invoke grant creation SUCCESSFUL ${GREEN} ✓ ${NC}: $lambdaaddpermissionsignin";
fi




echo -e "\n\nStep 4d: Verify"
echo -e "--------------"

echo -e "\n⏳ Creating verify method";

createresourceverifycommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part verify";

createresourceverify=`eval "$createresourceverifycommand | jq '.id'"`

if [ -z "$createresourceverify" ]
then
      echo -e "\n💬 Verify resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 Verify resource creation SUCCESSFUL ${GREEN} ✓ ${NC}: $createresourceverify";
fi

putmethodverifycommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourceverify --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodverify=`eval "$putmethodverifycommand | jq '.httpMethod'"`

if [ -z "$putmethodverify" ]
then
      echo -e "\n💬 Verify method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\n💬 Verify method creation SUCCESSFUL ${GREEN} ✓ ${NC}: $putmethodverify";
fi


putmethodverifyoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourceverify --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodverifyoptions=`eval "$putmethodverifyoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodverifyoptions" ]
then
      echo -e "\n💬 Verify options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\n💬 Verify options method creation SUCCESSFUL ${GREEN} ✓ ${NC}: $putmethodverifyoptions";
fi


echo -e "\n⏳ Creating lambda integration";

putintegrationverifycommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourceverify --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationverify=`eval "$putintegrationverifycommand | jq '.passthroughBehavior'"`;

putintegrationverifyoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourceverify --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationverifyoptions=`eval "$putintegrationverifyoptionscommand | jq '.passthroughBehavior'"`;

# putintegrationresponseverify200command="aws apigateway put-integration-response --region $awsregion --rest-api-id $createapi --resource-id $createresourceverify --http-method POST --status-code 200 --selection-pattern \"\""

# putintegrationresponseverify200=`eval "$putintegrationresponseverify200command | jq '.statusCode'"`

echo -e "\n⏳ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionverifycommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/verify\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionverify=`eval "$lambdaaddpermissionverifycommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionverify" ]
then
      echo -e "\n💬 Verify lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 Verify lambda invoke grant creation SUCCESSFUL ${GREEN} ✓ ${NC}: $lambdaaddpermissionverify";
fi


random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionverifyoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/verify\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionverifyoptions=`eval "$lambdaaddpermissionverifyoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionverifyoptions" ]
then
      echo -e "\n💬 Verify options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 Verify options lambda invoke grant creation SUCCESSFUL ${GREEN} ✓ ${NC}: $lambdaaddpermissionverifyoptions";
fi



echo -e "\n\nStep 4e: Validate"
echo -e "--------------"

echo -e "\n⏳ Creating validate method";

createresourcevalidatecommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part validate";

createresourcevalidate=`eval "$createresourcevalidatecommand | jq '.id'"`

if [ -z "$createresourcevalidate" ]
then
      echo -e "\n💬 Validate resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 Validate resource creation SUCCESSFUL ${GREEN} ✓ ${NC}: $createresourcevalidate";
fi

putmethodvalidatecommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcevalidate --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodvalidate=`eval "$putmethodvalidatecommand | jq '.httpMethod'"`

if [ -z "$putmethodvalidate" ]
then
      echo -e "\n💬 Validate method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\n💬 Validate method creation SUCCESSFUL ${GREEN} ✓ ${NC}: $putmethodvalidate";
fi


echo -e "\n⏳ Creating lambda integration";

putintegrationvalidatecommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcevalidate --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationvalidate=`eval "$putintegrationvalidatecommand | jq '.passthroughBehavior'"`;

echo -e "\n⏳ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionvalidatecommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/validate\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionvalidate=`eval "$lambdaaddpermissionvalidatecommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionvalidate" ]
then
      echo -e "\n💬 Validate lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 Validate lambda invoke grant creation SUCCESSFUL ${GREEN} ✓ ${NC}: $lambdaaddpermissionvalidate";
fi




echo -e "\n\nStep 4f: Refresh"
echo -e "--------------"

echo -e "\n⏳ Creating refresh method";

createresourcerefreshcommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part refresh";

createresourcerefresh=`eval "$createresourcerefreshcommand | jq '.id'"`

if [ -z "$createresourcerefresh" ]
then
      echo -e "\n💬 Refresh resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 Refresh resource creation SUCCESSFUL ${GREEN} ✓ ${NC}: $createresourcerefresh";
fi

putmethodrefreshcommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcerefresh --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodrefresh=`eval "$putmethodrefreshcommand | jq '.httpMethod'"`

if [ -z "$putmethodrefresh" ]
then
      echo -e "\n💬 Refresh method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\n💬 Refresh method creation SUCCESSFUL ${GREEN} ✓ ${NC}: $putmethodrefresh";
fi

putmethodrefreshoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcerefresh --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodrefreshoptions=`eval "$putmethodrefreshoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodrefreshoptions" ]
then
      echo -e "\n💬 Refresh options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\n💬 Refresh options method creation SUCCESSFUL ${GREEN} ✓ ${NC}: $putmethodrefreshoptions";
fi


echo -e "\n⏳ Creating lambda integration";

putintegrationrefreshcommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcerefresh --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationrefresh=`eval "$putintegrationrefreshcommand | jq '.passthroughBehavior'"`;

putintegrationrefreshoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcerefresh --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationrefreshoptions=`eval "$putintegrationrefreshoptionscommand | jq '.passthroughBehavior'"`;

echo -e "\n⏳ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionrefreshcommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/refresh\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionrefresh=`eval "$lambdaaddpermissionrefreshcommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionrefresh" ]
then
      echo -e "\n💬 Refresh lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 Refresh lambda invoke grant creation SUCCESSFUL ${GREEN} ✓ ${NC}: $lambdaaddpermissionrefresh";
fi


random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionrefreshoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/refresh\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionrefreshoptions=`eval "$lambdaaddpermissionrefreshoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionrefreshoptions" ]
then
      echo -e "\n💬 Refresh options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 Refresh options lambda invoke grant creation SUCCESSFUL ${GREEN} ✓ ${NC}: $lambdaaddpermissionrefreshoptions";
fi



echo -e "\n\nStep 4g: Resend"
echo -e "--------------"

echo -e "\n⏳ Creating resend method";

createresourceresendcommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part resend";

createresourceresend=`eval "$createresourceresendcommand | jq '.id'"`

if [ -z "$createresourceresend" ]
then
      echo -e "\n💬 Resend resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 Resend resource creation SUCCESSFUL ${GREEN} ✓ ${NC}: $createresourceresend";
fi

putmethodresendcommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourceresend --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodresend=`eval "$putmethodresendcommand | jq '.httpMethod'"`

if [ -z "$putmethodresend" ]
then
      echo -e "\n💬 Resend method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\n💬 Resend method creation SUCCESSFUL ${GREEN} ✓ ${NC}: $putmethodresend";
fi

putmethodresendoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourceresend --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodresendoptions=`eval "$putmethodresendoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodresendoptions" ]
then
      echo -e "\n💬 Resend options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\n💬 Resend options method creation SUCCESSFUL ${GREEN} ✓ ${NC}: $putmethodresendoptions";
fi


echo -e "\n⏳ Creating lambda integration";

putintegrationresendcommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourceresend --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationresend=`eval "$putintegrationresendcommand | jq '.passthroughBehavior'"`;

putintegrationresendoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourceresend --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationresendoptions=`eval "$putintegrationresendoptionscommand | jq '.passthroughBehavior'"`;


echo -e "\n⏳ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionresendcommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/resend\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionresend=`eval "$lambdaaddpermissionresendcommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionresend" ]
then
      echo -e "\n💬 Resend lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 Resend lambda invoke grant creation SUCCESSFUL ${GREEN} ✓ ${NC}: $lambdaaddpermissionresend";
fi


random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionresendoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/resend\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionresendoptions=`eval "$lambdaaddpermissionresendoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionresendoptions" ]
then
      echo -e "\n💬 Resend options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 Resend options lambda invoke grant creation SUCCESSFUL ${GREEN} ✓ ${NC}: $lambdaaddpermissionresendoptions";
fi



echo -e "\n\nStep 4h: DetailUser"
echo -e "--------------"

echo -e "\n⏳ Creating detailuser method";

createresourcedetailusercommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part detailuser";

createresourcedetailuser=`eval "$createresourcedetailusercommand | jq '.id'"`

if [ -z "$createresourcedetailuser" ]
then
      echo -e "\n💬 DetailUser resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 DetailUser resource creation SUCCESSFUL ${GREEN} ✓ ${NC}: $createresourcedetailuser";
fi

putmethoddetailusercommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcedetailuser --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethoddetailuser=`eval "$putmethoddetailusercommand | jq '.httpMethod'"`

if [ -z "$putmethoddetailuser" ]
then
      echo -e "\n💬 DetailUser method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\n💬 DetailUser method creation SUCCESSFUL ${GREEN} ✓ ${NC}: $putmethoddetailuser";
fi

putmethoddetailuseroptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcedetailuser --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethoddetailuseroptions=`eval "$putmethoddetailuseroptionscommand | jq '.httpMethod'"`

if [ -z "$putmethoddetailuseroptions" ]
then
      echo -e "\n💬 DetailUser options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\n💬 DetailUser options method creation SUCCESSFUL ${GREEN} ✓ ${NC}: $putmethoddetailuseroptions";
fi


echo -e "\n⏳ Creating lambda integration";

putintegrationdetailusercommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcedetailuser --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationdetailuser=`eval "$putintegrationdetailusercommand | jq '.passthroughBehavior'"`;

putintegrationdetailuseroptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcedetailuser --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationdetailuseroptions=`eval "$putintegrationdetailuseroptionscommand | jq '.passthroughBehavior'"`;


echo -e "\n⏳ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissiondetailusercommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/detailuser\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissiondetailuser=`eval "$lambdaaddpermissiondetailusercommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissiondetailuser" ]
then
      echo -e "\n💬 DetailUser lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 DetailUser lambda invoke grant creation SUCCESSFUL ${GREEN} ✓ ${NC}: $lambdaaddpermissiondetailuser";
fi


random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissiondetailuseroptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/detailuser\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissiondetailuseroptions=`eval "$lambdaaddpermissiondetailuseroptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissiondetailuseroptions" ]
then
      echo -e "\n💬 DetailUser options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 DetailUser options lambda invoke grant creation SUCCESSFUL ${GREEN} ✓ ${NC}: $lambdaaddpermissiondetailuseroptions";
fi



echo -e "\n\nStep 4i: LogoutUser"
echo -e "--------------"

echo -e "\n⏳ Creating logoutuser method";

createresourcelogoutusercommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part logoutuser";

createresourcelogoutuser=`eval "$createresourcelogoutusercommand | jq '.id'"`

if [ -z "$createresourcelogoutuser" ]
then
      echo -e "\n💬 LogoutUser resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 LogoutUser resource creation SUCCESSFUL ${GREEN} ✓ ${NC}: $createresourcelogoutuser";
fi

putmethodlogoutusercommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcelogoutuser --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodlogoutuser=`eval "$putmethodlogoutusercommand | jq '.httpMethod'"`

if [ -z "$putmethodlogoutuser" ]
then
      echo -e "\n💬 LogoutUser method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\n💬 LogoutUser method creation SUCCESSFUL ${GREEN} ✓ ${NC}: $putmethodlogoutuser";
fi

putmethodlogoutuseroptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcelogoutuser --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodlogoutuseroptions=`eval "$putmethodlogoutuseroptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodlogoutuseroptions" ]
then
      echo -e "\n💬 LogoutUser options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\n💬 LogoutUser options method creation SUCCESSFUL ${GREEN} ✓ ${NC}: $putmethodlogoutuseroptions";
fi


echo -e "\n⏳ Creating lambda integration";

putintegrationlogoutusercommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcelogoutuser --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationlogoutuser=`eval "$putintegrationlogoutusercommand | jq '.passthroughBehavior'"`;

putintegrationlogoutuseroptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcelogoutuser --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationlogoutuseroptions=`eval "$putintegrationlogoutuseroptionscommand | jq '.passthroughBehavior'"`;


echo -e "\n⏳ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionlogoutusercommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/logoutuser\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionlogoutuser=`eval "$lambdaaddpermissionlogoutusercommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionlogoutuser" ]
then
      echo -e "\n💬 LogoutUser lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 LogoutUser lambda invoke grant creation SUCCESSFUL ${GREEN} ✓ ${NC}: $lambdaaddpermissionlogoutuser";
fi


random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionlogoutuseroptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/logoutuser\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionlogoutuseroptions=`eval "$lambdaaddpermissionlogoutuseroptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionlogoutuseroptions" ]
then
      echo -e "\n💬 LogoutUser options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 LogoutUser options lambda invoke grant creation SUCCESSFUL ${GREEN} ✓ ${NC}: $lambdaaddpermissionlogoutuseroptions";
fi




echo -e "\n\nStep 4j: ListLogs"
echo -e "--------------"

echo -e "\n⏳ Creating listlogs method";

createresourcelistlogscommand="aws apigateway create-resource --rest-api-id $createapi --region $awsregion --parent-id $getresources --path-part listlogs";

createresourcelistlogs=`eval "$createresourcelistlogscommand | jq '.id'"`

if [ -z "$createresourcelistlogs" ]
then
      echo -e "\n💬 ListLogs resource creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 ListLogs resource creation SUCCESSFUL ${GREEN} ✓ ${NC}: $createresourcelistlogs";
fi

putmethodlistlogscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcelistlogs --http-method POST --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodlistlogs=`eval "$putmethodlistlogscommand | jq '.httpMethod'"`

if [ -z "$putmethodlistlogs" ]
then
      echo -e "\n💬 ListLogs method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\n💬 ListLogs method creation SUCCESSFUL ${GREEN} ✓ ${NC}: $putmethodlistlogs";
fi

putmethodlistlogsoptionscommand="aws apigateway put-method --rest-api-id $createapi --resource-id $createresourcelistlogs --http-method OPTIONS --authorization-type \"NONE\" --region $awsregion --no-api-key-required";

putmethodlistlogsoptions=`eval "$putmethodlistlogsoptionscommand | jq '.httpMethod'"`

if [ -z "$putmethodlistlogsoptions" ]
then
      echo -e "\n💬 ListLogs options method creation FAILED ${RED} x ${NC}";
      exit ;
else
      echo -e "\n💬 ListLogs options method creation SUCCESSFUL ${GREEN} ✓ ${NC}: $putmethodlistlogsoptions";
fi


echo -e "\n⏳ Creating lambda integration";

putintegrationlistlogscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcelistlogs --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationlistlogs=`eval "$putintegrationlistlogscommand | jq '.passthroughBehavior'"`;

putintegrationlistlogsoptionscommand="aws apigateway put-integration --region $awsregion --rest-api-id $createapi --resource-id $createresourcelistlogs --http-method OPTIONS --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$awsregion:lambda:path/2015-03-31/functions/arn:aws:lambda:$awsregion:$awsaccount:function:$functionname/invocations"

putintegrationlistlogsoptions=`eval "$putintegrationlistlogsoptionscommand | jq '.passthroughBehavior'"`;


echo -e "\n⏳ Adding lambda invoke permission";

random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionlistlogscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/POST/listlogs\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionlistlogs=`eval "$lambdaaddpermissionlistlogscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionlistlogs" ]
then
      echo -e "\n💬 ListLogs lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 ListLogs lambda invoke grant creation SUCCESSFUL ${GREEN} ✓ ${NC}: $lambdaaddpermissionlistlogs";
fi


random=`echo $RANDOM`;
ts=`date +%s`

lambdaaddpermissionlistlogsoptionscommand="aws lambda add-permission --function-name $functionname --source-arn \"arn:aws:execute-api:$awsregion:$awsaccount:$createapi/*/OPTIONS/listlogs\" --principal apigateway.amazonaws.com  --statement-id ${random}${ts} --action lambda:InvokeFunction";

lambdaaddpermissionlistlogsoptions=`eval "$lambdaaddpermissionlistlogsoptionscommand | jq '.Statement'"`;

if [ -z "$lambdaaddpermissionlistlogsoptions" ]
then
      echo -e "\n💬 ListLogs options lambda invoke grant creation FAILED ${RED} x ${NC}";
      exit 1;
else
      echo -e "\n💬 ListLogs options lambda invoke grant creation SUCCESSFUL ${GREEN} ✓ ${NC}: $lambdaaddpermissionlistlogsoptions";
fi



echo -e "\n⏳ Deploying API Gateway function";

createdeploymentcommand="aws apigateway create-deployment --rest-api-id $createapi --stage-name $apistage --region $awsregion"

createdeployment=`eval "$createdeploymentcommand | jq '.id'"`

if [ -z "$createdeployment" ]
then
    echo -e "\n💬 Auth deployment creation FAILED ${RED} x ${NC}";
else
    echo -e "\n💬 Auth deployment creation SUCCESSFUL ${GREEN} ✓ ${NC}: $createdeployment";
fi


echo -e "Script Ended...\n";
