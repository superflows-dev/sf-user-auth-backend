###########
# Script Config
###########

correspondenceemail=P_CORRESPONDENCE_EMAIL
awsregion=P_AWS_REGION
weborigin=P_WEB_ORIGIN
appname=P_APP_NAME
tablename=P_TABLE_NAME
logtablename=P_LOG_TABLE_NAME
functionname=P_FUNCTION_NAME

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
      # echo -e "\n$NEXTSTEPS"
      # echo -e "$NEXTSTEPSINSTRUCTION\n" 
      # echo -e $EXITMESSAGE;
      # exit 1;

fi

echo -e "\n💬 SES configuration completed successfully for ${TBOLD}$correspondenceemail${TNORMAL} ${GREEN} ✓ ${NC}\n" 

sleep 5

###########
# Lambda Function Config
###########

echo -e "\n\nLambda Function Configuration"
echo -e "--------------------------------------"

echo -e "\n>> Function: ${TBOLD}$functionname${TNORMAL}";

rm -r aws_proc

cp -r aws aws_proc

find ./aws_proc -name '*.js' -exec sed -i -e "s|AWS_REGION|$awsregion|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|DB_TABLE_NAME|$tablename|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|DB_LOG_TABLE_NAME|$logtablename|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|WEB_ORIGIN|$weborigin|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|APP_NAME|$appname|g" {} \;
find ./aws_proc -name '*.js' -exec sed -i -e "s|CORRESP_EMAIL|$correspondenceemail|g" {} \;

zip -r -j ./aws_proc/auth.zip aws_proc/auth/*

echo -e "\n⏳ Updaing function ${TBOLD}$functionname${TNORMAL} code";

updatefunctioncommand="aws lambda update-function-code --function-name $functionname --zip-file fileb://aws_proc/auth.zip";

updatefunction=`eval $updatefunctioncommand`;



echo -e "Script Ended...\n";
