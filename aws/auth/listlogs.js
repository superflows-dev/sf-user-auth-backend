import { ScanCommand } from "@aws-sdk/client-dynamodb";
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { ddbClient, LOG_TABLE_NAME, sesClient, FROM_EMAIL, PROJECT_NAME } from "./ddbClient.js";
import { generateOTP, generateToken } from './util.js';
import { ACCESS_TOKEN_DURATION, REFRESH_TOKEN_DURATION } from './globals.js'
import { processValidate } from './validate.js'

export const processListLogs = async (event) => {
    
    // body sanity check
  
    var body = null;
    
    try {
        body = JSON.parse(event.body);
    } catch (e) {
        return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
    }
    
    
    var offset = "";
    var limit = "";
    
    try {
        offset = parseInt(body.offset.trim());
        limit = parseInt(body.limit.trim());
    } catch (e) {
        return {statusCode: 400, body: { result: false, error: "Malformed body!"}};
    }
    
    
    // validate access token
    
    const resultValidate = await processValidate(event);
    if(!resultValidate.body.result || !resultValidate.body.admin) {
        return {statusCode: 401, body: {result: false, error: "Unauthorized request!"}};
    }
    
    // scan records
  
    var scanParams = {
        TableName: LOG_TABLE_NAME,
    }
    
    var resultItems = []
  
    async function ddbQuery () {
        try {
            const data = await ddbClient.send (new ScanCommand(scanParams));
            resultItems = resultItems.concat((data.Items))
            if(data.LastEvaluatedKey != null) {
                scanParams.ExclusiveStartKey = data.LastEvaluatedKey;
                await ddbQuery();
            }
        } catch (err) {
            console.log(err);
            return err;
        }
    };
    
    const resultQ = await ddbQuery();

    // unmarshall the records
  
    var unmarshalledItems = [];
  
    for(var i = 0; i < resultItems.length; i++) {
        var item = {};
        for(var j = 0; j < Object.keys(resultItems[i]).length; j++) {
            item[Object.keys(resultItems[i])[j]] = resultItems[i][Object.keys(resultItems[i])[j]][Object.keys(resultItems[i][Object.keys(resultItems[i])[j]])[0]];
        }
        unmarshalledItems.push(item);
    }
  
    // sort the items by timestamp
  
    var resultItemsSorted = unmarshalledItems;
    resultItemsSorted = resultItemsSorted.sort((a, b) => a['timestamp'] > b['timestamp'] ? -1: 1)  
    
    // filter the items
  
    var resultItemsFiltered = resultItemsSorted;
    if(body.filterKey != null) {
        if(body.filterString != null) {
            if(body.filterString.length > 1) {
                var resultArr = [];
                for(var i = 0; i < resultItemsFiltered.length; i++) {
                    if(resultItemsFiltered[i][body.filterKey].toLowerCase().indexOf(body.filterString.toLowerCase()) >= 0) {
                        resultArr.push(resultItemsFiltered[i]);
                    }
                }
                resultItemsFiltered = resultArr;
            }
        }
    }
    
    // slice the item set based on offset limit
  
    var resultItemsSliced = resultItemsFiltered;
  
    if(body.offset != null) {
    
        if(body.limit != null) {
            resultItemsSliced = resultItemsFiltered.slice(parseInt(body.offset), (parseInt(body.offset) + parseInt(body.limit)));
        } else {
            resultItemsSliced = resultItemsFiltered.slice(parseInt(body.offset));
        }
    
    }
    
    return {statusCode: 200, body: {result: true, data: {values: (resultItemsSliced), pages: Math.ceil (resultItemsFiltered.length / body.limit)}}};
    
}