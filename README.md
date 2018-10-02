# SFUtilities
Salesforce Developer Utilities

This is a collection of small utilities helpful for Salesforce Developers.

## Custom Metadata File Generator
Filename: [CustomMetadataUtility.bas](VBAUtilities/CustomMetadataUtility.bas)
Generates metadata files for each record of custom metadata. It is a VBA utility. So you can copy the code into macros and run it.

### Pre-requisites:
1. MS-Excel file should be available
2. First row of data should be header row. It should contain api names of the fields
3. First column is reserved for record label

For e.g.

|label	|	ISOName__c	|	ISOCode__c |
| --- | --- | --- |
|United States of America	|United States	|US|
|Afghanistan|	Afghanistan	|AF|
|Albania	|Albania	|AL|
|Algeria	|Algeria	|DZ|
|Andorra	|Andorra	|AD|

### Pending Improvements:
1. Allow user to define type of each custom metadata attribute
2. Generate files with special characters