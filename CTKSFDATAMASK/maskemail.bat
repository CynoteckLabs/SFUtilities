@ECHO OFF

SETLOCAL 
ECHO CYNOTECK DATA MASKING UTILITY


REM CHECK IF USERNAME IS PROVIDED
if -%1-==-- (
	GOTO USERNAMEMISSING
) 
if -%2-==-- (
	GOTO QUERYMISSING
)

GOTO INIT


:USERNAMEMISSING

ECHO[
ECHO[
ECHO ERROR: ORG USERNAME NOT PROVIDED
ECHO[

GOTO USAGEINFO

EXIT /B 0

:QUERYMISSING

ECHO[
ECHO[
ECHO ERROR: DATA QUERY NOT PROVIDED
ECHO[

GOTO USAGEINFO

EXIT /B 0

:USAGEINFO

ECHO[
ECHO USAGE
ECHO maskemail USEERNAME OBJECT_NAME QUERY
ECHO USEERNAME = Username of target salesforce instance (only sandboxes) asd@asd.com.dev
ECHO QUERY = Query to retrieve data for masking
ECHO[
ECHO Call command by passing username of target org.
ECHO For e.g. maskemail test@testinstance.com "select id, email from Contact"

EXIT /B 0

:INIT

SET DEV=%1%
SET QUERY=%2%
REM SET FIELDNAMES=%3%

REM VERIFY SCRIPT IS RUNNING IN SANDBOX
call sfdx force:data:soql:query -u %DEV% -q "select issandbox from organization" --json | jq ".result.records[0].IsSandbox" > issandbox.tmp

set /P ISSANDBOX=<issandbox.tmp

del issandbox.tmp

IF %ISSANDBOX%==true (
	GOTO SANDBOXDATAUPDATE
)
IF %ISSANDBOX%==false (
	ECHO[ 
	ECHO[ 
	ECHO ERROR: THIS IS PRODUCTION. SCRIPT EXITING
)

EXIT /B 0

:SANDBOXDATAUPDATE

REM ################## MASK CONTACT EMAIL ####################################

ECHO PHASE 1: Masking Contact Email addresses

REM SET QUERY="select id, %FIELDNAMES% from %OBJNAME%"

ECHO Intiating Query=%QUERY%

REM download contacts with email fields
ECHO --- Step 1: Downloading unmasked data(USER: %DEV%)
call sfdx force:data:soql:query -u %DEV% -q %QUERY% -r csv > unmaskedData.csv

REM add test domain at end of each email field
ECHO --- Step 2: Masking all email address values
type unmaskedData.csv | sed -r "s/\w+@\w+/masked@testorg/g" > maskedData.csv

ECHO --- Step 3: udpating contacts in salesforce (USER: %DEV%)
call sfdx force:data:bulk:upsert -u %DEV% -s Contact -w 30 -i Id -f maskedData.csv

REM Delete temporary data files
del unmaskedData.csv, maskedData.csv

EXIT /B 0