# Salesforce Data Migration Utility

## Purpose
Basic ETL (Extract - Transform - Load) utility for Data Migration from/to Salesforce.

## Features
* Configuration based job execution
* Schema - Auto-generate required SQL script to generate Database tables and Data extraction views
* Mapping - Automatic mapping of old record id to new record ID, to retain record relationship during migration
* Extract - automated data extraction (using Salesforce CLI) and import into local staging database
* Transform - autogenerate database views to extract data with mapping fields for relationships
> Any target field name changes can be added to the Database Views script or View (if automatically created in Database)
* Load - Automatically import data into Target (Salesforce or a Database) 


## Tools Used
1. Salesforce command line utility
2. PostgreSQL Database
3. PSQl utility (installed with PostgreSQL isntaller)
4. Powershell

## Pre-Requisites
Before using this utility, ensure you have following on workstation:
1. Salesforce command line utility installed and authenticated to all target salesforce orgs
2. PostgreSQL installed (along with psql command line utility)
3. PostgreSQL server should be running


## Setup
### Setup Environment Configuration
Setup configuration file as a JSON file with following properties
|Property|Purpose|Additional Details|
|--|--|--| 
|sf_env|Default Salesforce environment alias/username to be used| This can be overridden via command line. Ensure given alias/username is authenticated on current workstation|
|db_host| Hostname of database server localhost | Example: localhost|
|db_port| Port to be used on host | |
|db_name| Postgres Database name| This is were data will be staged/stored for migration purposes|
|db_username|Postgres Database user name||
|db_pwd|Postgres Database user password||
|objectSettings|A JSON object array containing object realted settings| For more information refer Object Settings|


#### Object Settings
|Property|Purpose|Additional Details|
|--|--|--| 
|name|Salesforce object API Name (including namespace, as applicable)| Special name **COMMON_OBJECT** can be used to provide object agnostic configurations |
|excludeFields|JSON String array of fields to be excluded for data extraction||

Example Config.json file:
```
{
    "sf_env" : "SF_LEARN",
    "db_host" : "localhost",
    "db_port" : "5432",
    "db_name" : "DataMigration",
    "db_username" : "postgres",
    "db_pwd" : "",
    "objectSettings" : [
        {
            "name" : "COMMON_OBJECT",
            "excludeFields" : [
                "CreatedDate",
                "CreatedById",
                "LastModifiedDate",
                "LastModifiedById",
                "LastActivityDate",
                "LastViewedDate",
                "LastReferencedDate",
                "OwnerId",
                "LastCURequestDate", 
                "LastCUUpdateDate",
                "PhotoUrl"
            ] 
        },
        {
            "name" : "Contact",
            "excludeFields" : [
                "Legacy__c",
                "IndividualId",
                "Name", 
                "IsEmailBounced", 
                "IsPriorityRecord"
            ]
        }
    ]
}
```


### Setup Job file
Each job file can contain multiple tasks in JSON format. Ideally each job file will have only one source and target. Also:
* Each task is a distinct operation based on available task types (detailed below)
* A job file can have multiple tasks
* Tasks are executed in same sequence as their order within the job file

|Environment|Task Type|Purpose|
|--|--|--|
|Salesforce|SFSELECT|Extract data from Salesforce (CSV)| 
|Salesforce|SFUPSERT|Upsert data into Salesforce| 
|Salesforce|SFSOBJECTTOTABLESQL|Generate SQL to create table as clone of Given Salesforce object| 
|Database (PostgreSQL)|DBINSERT|Insert data into Database| 
|Database (PostgreSQL)|DBDATAEXTRACTVIEWSQL| Generate Data extraction view | 
|Database (PostgreSQL)|DBSELECT|Extract data from Database (primarily used to get data from data extraction views)|
|Database (PostgreSQL)|DBCOMMAND| (General-purpose) Perform any data base operation| 
|Database (PostgreSQL) | DBCSVHEADERTOTABLESQL | Generate SQL script to create table for staging data within a CSV file |


#### Common Properties of All Task Types
|Properties|Purpose|Example|
|--|--|--| 
|action|Task type|SFSELECT | 
|description| Documentation for the task|extract accounts data from Salesforce| 

#### SFSELECT
|Properties|Purpose|Additional Details|
|--|--|--| 
|query|SQOL Query to be used to extract data||
|outputFile| File where the fetched records (CSV) format should be saved|| 
|wait|Minutes command should wait for data to be exported| Note: Provide higher number to ensure resulting SFDX command doesn't end early, without extracting any data| 

Example 1 (Extract using Object name):
```
{
    "action" : "SFSELECT",
    "description" : "extract accounts data from Salesforce",
    "object" : "Account",
    "outputFile" : "c:\\datamigration\\src_accounts.csv",
    "wait" : 5
},
```

Example 2 (Extract using SOQL Query):
```
{
    "action" : "SFSELECT",
    "description" : "extract contacts data from Salesforce",
    "query" : "SELECT Id, MasterRecordId, AccountId, LastName, FirstName, Salutation, OtherStreet, OtherCity, OtherState, OtherPostalCode, OtherCountry, OtherLatitude, OtherLongitude, OtherGeocodeAccuracy, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude, MailingGeocodeAccuracy, Phone, Fax, MobilePhone, HomePhone, OtherPhone, AssistantPhone, ReportsToId, Email, Title, Department, AssistantName, LeadSource, Birthdate, Description, EmailBouncedReason, EmailBouncedDate, Jigsaw, JigsawContactId, CleanStatus, Level__c, Languages__c  FROM Contact",
    "outputFile" : "c:\\datamigration\\src_contacts.csv",
    "wait" : 5
}
```

#### SFUPSERT
|Properties|Purpose|Additional Details|
|--|--|--|
|object|Target object, where data will be upserted||
|inputFile| CSV file containing records to be upserted|Note: Only tested for files in local workstation| 
|wait|Minutes command should wait for data to be upserted| Note: Provide higher number to ensure resulting SFDX command doesn't end early, without completing work|
|externalid| API Name (case sensitive) of the salesforce object field to be used as externalid||
|outputFile| (Optional) outputfile where output of command should be exported (in JSON format)|:bulb: For any data upload failures into Salesforce refer to file specified within parameter outputFile|
|legacyField| (Optional) name of table column containing old record id. It should be same value as specified in corresponding **DBDATAEXTRACTVIEWSQL** task for the entity within field named **legacyField** | :bulb: If this value is provided, utility automatically parses results and stores within database table named **MIGRATIONSTATUS**|

Example:
```
{
    "action" : "SFUPSERT",
    "description" : "Upsert accounts data into Salesforce",
    "object" : "Account",
    "inputFile" : "c:\\datamigration\\load_accounts.csv",
    "outputFile" : "c:\\datamigration\\accounts_logs.json",
    "wait" : 5,
    "externalid" : "Id",
    "legacyField" : "Legacy__c"
}
```

#### SFSOBJECTTOTABLESQL
|Properties|Purpose|Additional Details|
|--|--|--| 
|object|Salesforce object for which data model is to be replicated|Provide full api name, including namespace (as applicable)|
|tableName| Name of table to be created within Datbase|| 
|appendToFile|Outfile file, where SQL should be appended| Note: SQL Script will be appended to the target file| 

Example:
```
{
    "action" : "SFSOBJECTTOTABLESQL",
    "description" : "create staging table for Contact",
    "object" : "Contact",
    "tableName" : "IN_Contact",
    "appendToFile" : "c:\\datamigration\\step1_createschemascript2.sql"
},
```

#### DBINSERT
|Properties|Purpose|Additional Details|
|--|--|--| 
|table| Name of table where records are to be inserted|| 
|inputFile|CSV file having records to be inserted|| 

Example:
```
{
    "action" : "DBINSERT",
    "description" : "import accounts data into staging table",
    "table" : "IN_Account",
    "inputFile" : "c:\\datamigration\\src_accounts.csv"
},
```

#### DBDATAEXTRACTVIEWSQL
|Properties|Purpose|Additional Details|
|--|--|--| 
|name| Name of Data extraction view to be created|| 
|object|Salesforce object related to operation| This is used to automatically identify relationship fields and create resuling mapping SQL | 
|tableName|Database table where data is stored| This is used as datasource for data extraction | 
|legacyField| API Name of field which will store legacy id of record| Use this to store Source system unique identifier for record within Target system <br/> :bulb: Recommend creating a custom field on the custom object (within Target org) to store old Record id |
|mappingTable| Table containing mapping between old legacy id and new id of related records||
|appendToFile| Outfile file, where SQL should be appended| Note: SQL Script will be appended to the target file| 


Example:
```
{
    "action" : "DBDATAEXTRACTVIEWSQL",
    "description" : "create view to extract data for account",
    "name" : "EXT_ACCOUNT",
    "object" : "Account",
    "tableName" : "IN_Account",
    "legacyField" : "Legacy__c",
    "mappingTable" : "IDMAPPING",
    "appendToFile" : "c:\\datamigration\\step1_createschemascript2.sql"
},
```

#### DBCSVHEADERTOTABLESQL

|Properties|Purpose|Additional Details|
|--|--|--| 
|inputFile| Input File (CSV) containing data to migrate|| 
|apendToFile | Append script to output file ||
|tableName | Name of table to be created ||
```
{
    "action" : "DBCSVHEADERTOTABLESQL",
    "description" : "Create Test Table from CSV",
    "inputFile" : "c:\\datamigration\\src_accounts.csv",
    "appendToFile" : "c:\\datamigration\\step1_createschemascript3.sql",
    "tableName" : "TEST_ACCOUNTS"
}
```

#### DBSELECT
|Properties|Purpose|Additional Details|
|--|--|--|
|command| SQL to extract data from Database table||
|exportfile| File where exported data will be stored in CSV format|| 


Example:
```
{
    "action" : "DBSELECT",
    "description" : "Extract account staged data",
    "command" : "select * from EXT_Account",
    "exportfile" : "c:\\datamigration\\load_accounts.csv"
}
```

#### DBCOMMAND
|Properties|Purpose|Additional Details|
|--|--|--|
|command| PSQL command to be executed. To be used for general purpose database operation||

Example:
```
{
    "action" : "DBCOMMAND",
    "description" : "Insert old and new id of Contacts for cross mapping",
    "command" : "copy IDMAPPING(oldid,newid) from 'c:\\datamigration\\contacts_keymapping.csv' delimiter ',' CSV HEADER ENCODING 'UTF8' QUOTE  '\"' ESCAPE ''''"
}
```
> Ensure to use escape special characters in command (as per given example above)


## Usage
Execute job using powershell utility parameters:

|Parameter|Purpose|Additional Details|
|--|--|
|configFilePath| JSON file path containing utility configurations| Default value is ./config.json |
|actionsFilePath| JSON file path containing job configurations| Default value is ./actions.json |
|sfenv| Salesforce environment to be used as target or source |  |

> Switch to powershell mode, before executing following command

```
PS> ./sfdatamigration.ps1 -configFilePath ./config.json -actionsFilePath ./schemaactions.json -sfenv AI
```

## Considerations
* To extract large data volume from Salesforce, ensure to setup *org-max-query-limit* configuration variable. For example, to export up to 50,000 records, set configuration limit as follows:
```
> sf config set org-max-query-limit 50000
```
For more details, visit https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_dev_cli_config_values.htm

* Any data quality failures need to be fixed before loading into target, to avoid any data failures