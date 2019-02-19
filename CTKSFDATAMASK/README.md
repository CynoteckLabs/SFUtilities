# SF Data Masking Utility

This utility is created to helps in automatically mask sensitive data especially useful post sandbox refreshes.

1. Windows - use maskData.bat
2. *nix - (Coming)

## Platform requirements
1. Windows (developed and tested on windows 10)
2. SFDX
3. *nix systems (Tested on Linux Mint 18.02)
4. jq (https://stedolan.github.io/jq/)
5. sed (Windows installer: http://gnuwin32.sourceforge.net/packages/sed.htm)

## Pre-Requisites
1. Copy/ download command line utiilty in given folder

## Usage
It's simply to be run by passing target username and query to retrieve data (to be masked)
SYNTAX 
maskemail USEERNAME OBJECT_NAME QUERY

where,
USEERNAME = Username of target salesforce instance (only sandboxes) asd@asd.com.dev
QUERY = Query to retrieve data for masking

for example,
maskemail test@testinstance.com "select id, email from Contact"

## Important
1. Query to retrieve should always include ID field, to ensure sucessful data updates
2. For large dataset, additional update batching may be required