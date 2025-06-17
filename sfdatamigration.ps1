
param (
    [string]$configFilePath = "./config.json",
    [string]$actionsFilePath = "./actions.json",
    #[string]$logFilePath = "./sfdatamigration.log",
    [string]$sfenv = ""
)

#################################################### CONSTANTS ###############################################################
$dataEncoding = 'UTF8';


#################################################### LOAD CONFIGURATIONS ###############################################################

$envConfig = (Get-Content $configFilePath -Raw) | ConvertFrom-Json

if($sfEnv -eq $NULL -OR $sfEnv -eq ""){
    $sfEnv = $envConfig.sf_env
}

$PSQLUTILITY = 'psql';
if( -NOT($envConfig.psqlPath -eq "")){
    $PSQLUTILITY = $envConfig.psqlPath + '//' + $PSQLUTILITY
}

[Console]::OutputEncoding = New-Object -typename System.Text.UTF8Encoding

# SAMPLE CONFIG FILE
# config.json
# {
#     sf_env : "",
#     db_name : "",
#     db_username : "",
#     db_pwd : ""
# },


$lstActionsConfig = (Get-Content $actionsFilePath -Raw) | ConvertFrom-Json

# SAMPLE ACTIONS FILE

# actions.json
# [
#   {
#         "action" : "DBSELECT"
#         "command" : "select id from V_ACCOUNT",
#         "exportfileName" : "abcd_sf_input.csv"
#   },
#   {
#         "action" : "SFUPSERT"
#         "object" : "Account",
# 		"inputFile" : "abcd_sf_input.csv",
#         "outputFile" : "account_customers"
#         "wait" : 100,
#         "externalid" : "accountnumber"
#   },
#   {
#         "action" : "DBINSERT"
#         "table" : "IN_Account_IDMap",
#         "inputdatasetname" : "account_customers.csv"
#   },
# 	{
#         "action" : "DBSELECT"
#         "command" : "select id from V_Contact",
#         "exportfileName" : "contact_sf_input.csv"
#   },
# 	{
#         "action" : "SFUPSERT"
#         "object" : "Contact",
# 		"inputFile" : "contact_sf_input.csv",
#         "outputFile" : "acContacts.csv"
#         "wait" : 100,
#         "externalid" : "asdasd"
#   },
#   {
#         "action" : "DBINSERT"
#         "table" : "IN_Contact_IDMap",
#         "inputdatasetname" : "acContacts.csv"
#   },
# ]

#################################################### HELPER FUNCTIONS ###############################################################

# Select and retrieve content from Database (PostgreSQL)
function DBCOMMAND{
    param (
        $actionConfig
    )
    & $PSQLUTILITY -h $envConfig.db_host -p $envConfig.db_port -U $envConfig.db_username -d $envConfig.db_name -c $actionConfig.command
}

# Create tracking tables 
function DBINIT{
    $actionConfig = @{};

    # Create table to Old and New IDs
    $actionConfig.command = 'CREATE TABLE IF NOT EXISTS IDMAPPING ( newid text, oldid text);';
    DBCOMMAND -actionConfig $actionConfig

    # Create table to Track Migration Status
    $actionConfig.command = 'CREATE TABLE IF NOT EXISTS MIGRATIONSTATUS ( newid text, oldid text, details text);';
    DBCOMMAND -actionConfig $actionConfig
}



# Select and retrieve content from Database (PostgreSQL)
function DBSCRIPT{
    param (
        $actionConfig
    )
    & $PSQLUTILITY -h $envConfig.db_host -p $envConfig.db_port -U $envConfig.db_username -d $envConfig.db_name -f $actionConfig.scriptPath
}

# Select and retrieve content from Database (PostgreSQL)
function DBSELECT{
    param (
        $actionConfig
    )
    $sqlCmd = "COPY (" + $actionConfig.command + ") TO '" + $actionConfig.exportfile + "' WITH DELIMITER ',' CSV HEADER ENCODING '$dataEncoding' QUOTE '""' ESCAPE '""';"
    & $PSQLUTILITY -h $envConfig.db_host -p $envConfig.db_port -U $envConfig.db_username -d $envConfig.db_name -c $sqlCmd
}

# Insert data into database (PostgreSQL)
function DBINSERT{
    param (
        $actionConfig
    )
    
    $sqlCmd = "COPY " + $actionConfig.table + " FROM '" + $actionConfig.inputFile  + "' DELIMITER ',' CSV HEADER ENCODING '$dataEncoding' QUOTE '""' ESCAPE '""';"
    # echo $sqlCmd
    & $PSQLUTILITY -h $envConfig.db_host -p $envConfig.db_port -U $envConfig.db_username -d $envConfig.db_name -c $sqlCmd
}


# Upsert data into Salesforce
function SFUPSERT{
    param (
        $actionConfig
    )
    sf data upsert bulk -s $actionConfig.object -f $actionConfig.inputFile -o $sfEnv -w $actionConfig.wait -i $actionConfig.externalid --json > $actionConfig.outputFile
}

# Upsert data into Salesforce
function SFLOADRESULTS{
    param (
        $actionConfig
    )
    if( $actionConfig.legacyField -ne "" -AND $actionConfig.legacyField -ne $NULL){
        # Retrieve logs and populate within migratation status table
        $upsertLogs = (Get-Content $actionConfig.inputFile -Raw) | ConvertFrom-Json

        $migrationData = 'newid,oldid,details'

        # Get Successful records
        foreach ($recordLog in $upsertLogs.result.records.successfulResults){
            $migrationData += "`n" + $recordLog.sf__Id + "," +  $($recordLog.psObject.properties[$actionConfig.legacyField].value) + ","
        }

        # Get Failure records
        foreach ($recordLog in $upsertLogs.result.records.failedResults){
            $migrationData += "`n," + $($recordLog.psObject.properties[$actionConfig.legacyField].value) + ",""" + $recordLog.sf__Error + """"
        }

        # write data to file
        $datalodfilename = $actionConfig.inputFile + '.dataload'
        Set-Content $datalodfilename -value $migrationData -Encoding $dataEncoding -NoNewLine

        # Insert results into database
        $resultsLoadConfig = @{};
        $resultsLoadConfig.table = $actionConfig.table;
        $resultsLoadConfig.inputFile = $datalodfilename

        DBINSERT -actionConfig $resultsLoadConfig
    }
}

# Extract data from Salesforce
function SFSELECT{
    param (
        $actionConfig
    )
    $soqlScript = ""
    if( $actionConfig.object -eq "" -OR $actionConfig.object -eq $NULL){
        $soqlScript = $actionConfig.query
    }
    else{
        $objFields = GetMigrationFieldsByObject -objAPIName $actionConfig.object

        $fieldsStr = Join-String -InputObject $objFields -Property name -Separator ', '
        
        $soqlScript = 'SELECT ' + $fieldsStr + ' FROM ' + $actionConfig.object
    }

    sf data export bulk -q $soqlScript -o $sfEnv -w $actionConfig.wait -r csv --output-file $actionConfig.outputFile
}

# Filters fields for object
function GetMigrationFieldsByObject(){
    param(
        $objAPIName
    )

    $objDescribeInfo = sf sobject describe --sobject $objAPIName -o $sfEnv --json  | ConvertFrom-Json

    $objFields = @();

    $excludedFields = @();

    foreach ($objSettings in $envConfig.objectSettings){
        if($objSettings.name -eq 'COMMON_OBJECT' -OR $objSettings.name -eq $objDescribeInfo.result.name){
            $excludedFields += $objSettings.excludeFields
        }
    }

    foreach ($fieldInfo in $objDescribeInfo.result.fields){
        if( -NOT( $excludedFields -contains $fieldInfo.name)){
            $objFields += $fieldInfo
        }
    }

    return $objFields
}

# Clone Salesforce object to Database table (DML)
function SFSOBJECTTOTABLESQL{
    param (
        $actionConfig
    )
    $objFields = GetMigrationFieldsByObject -objAPIName $actionConfig.object

    $dmlScript = "-- Table for " + $actionConfig.object
    $dmlScript += "`nCREATE TABLE " + $actionConfig.tableName + " ("

    foreach ($fieldInfo in $objFields){

        # skip formula fields
        if( -NOT($fieldInfo.calculated)){ 

            if($fieldInfo.type -eq "double" -OR $fieldInfo.type -eq "currency" -OR $fieldInfo.type -eq "percent"   ){
                $dmlScript += "`n`t" + $fieldInfo.name + " real,"
            }
            else{
                $dmlScript += "`n`t" + $fieldInfo.name + " text,"
            }
        }
    }

    # TODO: Automatically track upsert outcomes within specific columns for reporting/investigation
    $dmlScript += ");`n`n"
    $dmlScript = $dmlScript.Replace(',);', ');')

    if( $actionConfig.appendToFile -ne $NULL -AND $actionConfig.appendToFile -ne "" ){
        Add-content $actionConfig.appendToFile -value $dmlScript
    }
    else{
        echo $dmlScript
    }
}

# Generate script to create Database Table
# All columns will be created as text
function DBCSVHEADERTOTABLESQL{
    param (
        $actionConfig
    )
    $csv = Import-Csv $actionConfig.inputFile
    $csvHeaders = $csv[0].psobject.Properties.Name

    $dmlScript = "-- Table for " + $actionConfig.tableName
    $dmlScript += "`nCREATE TABLE" + $actionConfig.tableName + " ("

    foreach ($fieldInfo in $csvHeaders){
        $dmlScript += "`n`t" + $fieldInfo + " text,"
    }

    $dmlScript += ");`n`n"
    $dmlScript = $dmlScript.Replace(',);', ');')

    if( $actionConfig.appendToFile -ne $NULL -AND $actionConfig.appendToFile -ne "" ){
        Add-content $actionConfig.appendToFile -value $dmlScript
    }
    else{
        echo $dmlScript
    }
}

function GETFIELDOVERRIDES{
    param (
        $objectName
    )

    $fieldOverrides = @();

    foreach ($objSettings in $envConfig.objectSettings){
        if($objSettings.name -eq 'COMMON_OBJECT' -OR $objSettings.name -eq $objectName){
            $fieldOverrides += $objSettings.mappingOverrides
        }
    }

    return $fieldOverrides
}

function GETFIELDOVERRIDEVALUE{
    param (
        $fieldName,
        $fieldOverrides
    )

    $overrideName = ""

    foreach ($overrideConfig in $fieldOverrides){
        if($overrideConfig.sourceName -eq $fieldName){
            $overrideName = $overrideConfig.targetName
            break
        }
    }

    return $overrideName
}

# Create Database View to extract data
function DBDATAEXTRACTVIEWSQL{
    param (
        $actionConfig
    )
    $objFields = GetMigrationFieldsByObject -objAPIName $actionConfig.object
    
    $fieldsToExtract
    $joinsToAdd
    $fieldMap = @{}
    
    $joinCounter = 1;

    $mappingTableName = $actionConfig.mappingTable;

    $fieldOverrides = GETFIELDOVERRIDES -objectName $actionConfig.object
    
    foreach ($fieldInfo in $objFields){

        $overriddenName = GETFIELDOVERRIDEVALUE -fieldName $fieldInfo.name -fieldOverrides $fieldOverrides

        # skip formula fields and Id field and address fields
        if( -NOT($fieldInfo.calculated) -AND $fieldInfo.name -ne "Id"){ 
            if($fieldInfo.type -eq "reference"){
                if($overriddenName -eq $NULL -OR $overriddenName -eq ""){
                    $overriddenName = $fieldInfo.name
                }
                $fieldsToExtract += "`n`t A" + $joinCounter + ".newid as $overriddenName," 
                $joinsToAdd += "`nLEFT OUTER JOIN $mappingTableName A" + $joinCounter + " on C." + $fieldInfo.name + " = A" + $joinCounter + ".oldid"
                $fieldMap[$fieldInfo.name] = "A" + $joinCounter + ".newid"
                $joinCounter = $joinCounter + 1
            }
            else{
                if($overriddenName -ne $NULL -AND $overriddenName -ne ""){
                    $fieldsToExtract += "`n`t " + $fieldInfo.name + " AS $overriddenName,"
                }
                else{
                    $fieldsToExtract += "`n`t " + $fieldInfo.name + ","
                }
            }
        }
    }

    #add legacy field is config is added
    if( $actionConfig.legacyField -ne $NULL -AND $actionConfig.legacyField -ne "" ){
        $fieldsToExtract += "`n`t Id as " + $actionConfig.legacyField + ","
    }

    # remove extra comma with last field
    if( $fieldsToExtract -ne $NULL){
        $fieldsLength = $fieldsToExtract.Length
        $fieldsToExtract = $fieldsToExtract.Remove($fieldsLength - 1, 1)
    }

    # Concatenate values to create view creation sql
    $dmlScript = "-- VIEW to exract " + $actionConfig.object
    $dmlScript += "`nCREATE VIEW " + $actionConfig.name + " AS "
    $dmlScript += "`nSELECT $fieldsToExtract "

    $dmlScript += "`nFROM " + $actionConfig.tableName + " C"
    $dmlScript += $joinsToAdd

    # add order by clause for view
    if( $actionConfig.orderBy -ne $NULL -AND $actionConfig.orderBy -ne "" ){
        $dmlScript += "`nORDER BY "
        foreach ($orderByField in $actionConfig.orderBy){
            $dmlScript += "`n" + $fieldMap[$orderByField] + ","
        }
    }
    
    $dmlScript += ";"

    $dmlScript = $dmlScript.Replace(",;", ";")

    
    if( $actionConfig.appendToFile -ne $NULL -AND $actionConfig.appendToFile -ne "" ){
        Add-content $actionConfig.appendToFile -value $dmlScript
    }
    else{
        echo $dmlScript
    }
}

#################################################### ACTIONS EXECUTION ###############################################################

$Env:PGPASSWORD = $envConfig.db_pwd;

foreach ($actionConfig in $lstActionsConfig){
    if($actionConfig.action -eq "DBINIT"){
        DBINIT -actionConfig $actionConfig
    }
    elseif($actionConfig.action -eq "DBSELECT"){
        DBSELECT -actionConfig $actionConfig
    }
    elseif($actionConfig.action -eq "DBINSERT"){
        DBINSERT -actionConfig $actionConfig
    }
    elseif($actionConfig.action -eq "SFUPSERT"){
        SFUPSERT -actionConfig $actionConfig
    }
    elseif($actionConfig.action -eq "SFSELECT"){
        SFSELECT -actionConfig $actionConfig
    }    
    elseif($actionConfig.action -eq "SFSOBJECTTOTABLESQL"){
        SFSOBJECTTOTABLESQL -actionConfig $actionConfig
    }
    elseif($actionConfig.action -eq "SFLOADRESULTS"){
        SFLOADRESULTS -actionConfig $actionConfig
    }
    elseif($actionConfig.action -eq "DBDATAEXTRACTVIEWSQL"){
        DBDATAEXTRACTVIEWSQL -actionConfig $actionConfig
    }
    elseif($actionConfig.action -eq "DBCOMMAND"){
        DBCOMMAND -actionConfig $actionConfig
    }
    elseif($actionConfig.action -eq "DBSCRIPT"){
        DBSCRIPT -actionConfig $actionConfig
    }
    elseif($actionConfig.action -eq "DBCSVHEADERTOTABLESQL"){
        DBCSVHEADERTOTABLESQL -actionConfig $actionConfig
    }
}