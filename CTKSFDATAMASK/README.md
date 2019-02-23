# SF Data Masking Utility

This utility is created to helps in automatically mask sensitive data especially useful post sandbox refreshes.

1. Windows - use maskData.bat
2. *nix - (Coming)

## Platform requirements
1. Windows (developed and tested on windows 10)
2. SFDX
3. jq (https://stedolan.github.io/jq/)
4. sed (Windows installer: http://gnuwin32.sourceforge.net/packages/sed.htm)

## Pre-Requisites
1. Copy/ download command line utiilty in desired folder
2. User should have logged in to target sandbox via SFDX

## Usage
1. Open Command prompt
2. Navigate to folder where utility is downloaded/ copied
3. Simply run utility by passing required parmeters

SYNTAX 

<em>maskemail USEERNAME OBJECTNAME QUERY</em>

where,
1. <em>USEERNAME</em> = Username of target salesforce instance (only sandboxes) asd@asd.com.dev
2. <em>OBJECTNAME</em> = API Name of sobject to be updated
3. <em>QUERY</em> = Query to retrieve data for masking

for example,
maskemail test@testinstance.com Contact "select id, email from Contact"

## Important
1. Query to retrieve should always include ID field, to ensure sucessful data updates
2. For large volume dataset, additional update batching may be required