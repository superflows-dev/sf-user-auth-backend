###########
# Script Config
###########

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

###########
# Delete API
###########

getapiscommand="aws apigateway get-rest-apis --no-paginate";

getapis=`eval "$getapiscommand | jq '.items  | .[] | select(.name==\"$api\") | .id  '"`;

if [ -z "$getapis" ]
then
    echo -e "\n💬 API ${TBOLD}$api${TNORMAL} not found ${RED} x ${NC}";
else
    echo -e "\n💬 API ${TBOLD}$api - $getapis${TNORMAL} found ${GREEN} ✓ ${NC}";
    echo -e "\n⏳ Deleting it ...";
    deleteapicommand="aws apigateway delete-rest-api --rest-api-id $getapis";
    deleteapi=`eval "$deleteapicommand"`;
fi

###########
# Delete Function
###########

echo -e "\n⏳ Deleting function if present $functionname ...";

deletefunctioncommand="aws lambda delete-function --function-name $functionname";
deletefunction=`eval "$deletefunctioncommand"`;

###########
# Delete Table
###########

echo -e "\n⏳ Deleting table if present $tablename ...";

deletetablecommand="aws dynamodb delete-table --table-name $tablename";
deletetable=`eval "$deletetablecommand"`;

###########
# Delete Log Table
###########

echo -e "\n⏳ Deleting log table if present $logtablename ...";

deletetablecommand="aws dynamodb delete-table --table-name $logtablename";
deletetable=`eval "$deletetablecommand"`;

###########
# Delete Policy
###########

getpoliciescommand="aws iam list-policies --no-paginate";

getpolicies=`eval "$getpoliciescommand | jq '.Policies  | .[] | select(.PolicyName==\"$policyname\") | .Arn  '"`;

if [ -z "$getpolicies" ]
then
    echo -e "\n💬 Policy ${TBOLD}$policyname${TNORMAL} not found ${RED} x ${NC}";
else
    echo -e "\n💬 Policy ${TBOLD}$policyname - $getpolicies${TNORMAL} found ${GREEN} ✓ ${NC}";
    echo -e "\n⏳ Detaching policy $getpolicies from role $rolename ...";
    detachcommand="aws iam detach-role-policy --policy-arn $getpolicies --role-name $rolename";
    detach=`eval "$detachcommand"`;
    sleep 5;
    echo -e "\n⏳ Deleting it ...";
    deletepolicycommand="aws iam delete-policy --policy-arn $getpolicies";
    deletepolicy=`eval "$deletepolicycommand"`;
fi

###########
# Delete Role
###########

echo -e "\n⏳ Deleting role if present $rolename ...";

deleterolecommand="aws iam delete-role --role-name $rolename";
deleterole=`eval "$deleterolecommand"`;

echo -e "\n\nScript Ended...\n";
