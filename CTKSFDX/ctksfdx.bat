@ECHO OFF

SETLOCAL 

REM ################################### CONFIG SECTION #################################


REM #### ENVIRONMENTS

REM #### DO NOT ADD space between key and value (required by batch script)

REM #### DEV is used as your source org
SET DEV=

REM #### Used to validate build
SET BUILD=

REM #### WAIT TIME (in minutes)
SET WAIT_RETRIEVE=10
SET WAIT_DEPLOY=20

REM ################################### CONFIG ENDS ####################################

REM ###############################################################################################################
REM ###############################################################################################################
REM ################################### DO NOT CHANGE ANYTHING AFTER THIS LINE ####################################
REM #################################### (Unless you know what you are doing) #####################################
REM ###############################################################################################################
REM ###############################################################################################################

REM ############## Display Top Menu #################
ECHO[
ECHO CYNOTECK SFDX UTILITY
ECHO Select option:
ECHO 		1 - Retrieve (Source = %DEV%)
ECHO 		2 - Deploy
ECHO 		3 - Test Build (Target = %BUILD%)
ECHO[
CHOICE /C:123

IF errorlevel 3 goto VERIFYBUILD
IF errorlevel 2 goto DEPLOY
IF errorlevel 1 goto RETRIEVE

REM ############# RETRIEVE FUNCTION ###################
:RETRIEVE
ECHO[
ECHO[
ECHO CYNOTECK: Retrieving components from DEV

REM Retrieve file
call sfdx force:mdapi:retrieve -w %WAIT_RETRIEVE% -r .\temp_mdapipkg -k .\src\package.xml -u %DEV%

REM UNPACK ZIP FILE
powershell Expand-Archive .\temp_mdapipkg\unpackaged.zip .\temp_src

REM COPY Zip file contents to SRC folder
xcopy /Y /S /Q .\temp_src\unpackaged .\src

REM Delete zip file and temp src folder
rmdir /q /s temp_mdapipkg
rmdir /q /s temp_src

ECHO CYNOTECK: Retrieve complete

EXIT /B 0

REM ############# DEPLOY FUNCTION ###################
:DEPLOY
ECHO[
ECHO[
set /P orgname=Enter Target Org username: 
call sfdx force:mdapi:deploy -d ./src -w %WAIT_DEPLOY% -u %orgname% > deploy.log
notepad deploy.log
EXIT /B 0

REM ############# VERIFY BUILD FUNCTION ###################
:VERIFYBUILD
call sfdx force:mdapi:deploy -c -l RunLocalTests -d ./src -w %WAIT_DEPLOY% -u %BUILD% > buildtest.log
ECHO View build test logs in buildtest.log file
notepad buildtest.log
EXIT /B 0