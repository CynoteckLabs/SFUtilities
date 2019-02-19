################################### CONFIG SECTION #################################


#### ENVIRONMENTS

#### DO NOT ADD space between key and value (required by batch script)

#### DEV is used as your source org
DEV=<DEV INSTANCE USERNAME>

#### Used to validate build
BUILD=<BUILD INSTANCE USERNAME>

#### WAIT TIME (in minutes)
WAIT_RETRIEVE=10
WAIT_DEPLOY=20

#### EDITOR
EDITOR=code

################################### CONFIG ENDS ####################################

###############################################################################################################
###############################################################################################################
################################### DO NOT CHANGE ANYTHING AFTER THIS LINE ####################################
#################################### (Unless you know what you are doing) #####################################
###############################################################################################################
###############################################################################################################


showError(){
    echo "\033[31m$1\033[0m"
}



############## Display Top Menu #################

mainmenu(){
    echo ""
    echo "CYNOTECK SFDX UTILITY"
    echo "Select option:"
    echo "		1 - Retrieve (Source = $DEV)"
    echo "		2 - Deploy"
    echo "		3 - Test Build (Target = $BUILD)"
    echo "		4 - Run Local Tests"
    echo ""
    read choice
    
    if [ $choice -eq 4 ]; then
        runlocaltests
    elif [ $choice -eq 3 ]; then
        verifybuild
    elif [ $choice -eq 2 ]; then
        deploy
    elif [ $choice -eq 1 ]; then
        retrieve
    else
        showError "Invalid Input $choice. Try again"
        echo ""
        mainmenu
    fi
}

############# RETRIEVE FUNCTION ###################
retrieve(){

    echo ""
    echo ""
    echo "CTKSFDX: Retrieving components from DEV"

    ## Retrieve file
    mkdir temp_mdapipkg    
    sfdx force:mdapi:retrieve -w $WAIT_DEPLOY -r ./temp_mdapipkg -k ./src/package.xml -u $DEV

    echo "CTKSFDX: Zipped components retrieved. Initiating unzip"
    ## UNPACK ZIP FILE
    unzip -qq -o ./temp_mdapipkg/unpackaged.zip -d ./temp_mdapipkg
    
    echo "CTKSFDX: Unzip completed. Initiating copy"
    cp -R ./temp_mdapipkg/unpackaged/* -t ./src
    
    ## Delete zip file and temp src folder
    rm -f -r -d temp_mdapipkg
    
    echo "CTKSFDX: Retrieve complete"

}

############# DEPLOY FUNCTION ###################
deploy() {
    echo ""
    echo ""
    echo "Enter Target Org username:"
    read targetOrg 

    echo "CTKSFDX: Taking Backup from target org (UserName: $targetOrg)"

    sfdx force:mdapi:retrieve -w $WAIT_DEPLOY -r ./backup -k ./src/package.xml -u $targetOrg

    echo "CTKSFDX: Initiating deployment (UserName: $targetOrg)"

    sfdx force:mdapi:deploy -c -d ./src -w $WAIT_DEPLOY -u $targetOrg > deploy.log
    $EDITOR deploy.log
}

############# VERIFY BUILD FUNCTION ###################
verifybuild(){
    echo "CTKSFDX: Initiating build validation (UserName: $BUILD)"
    sfdx force:mdapi:deploy -c -l RunLocalTests -d ./src -w $WAIT_DEPLOY -u $BUILD > buildtest.log

    echo "View build test logs in buildtest.log file"
    $EDITOR buildtest.log
}

############# RUN LOCAL TESTS FUNCTION ###################
runlocaltests(){
    echo "CTKSFDX: Running all local tests (UserName: $BUILD)"
    sfdx force:apex:test:run --resultformat human -u $DEV -l RunLocalTests > localtestsrun.log

    echo "View test exeuction logs in localtestsrun.log file"
    $EDITOR localtestsrun.log
}

### Show menu
mainmenu
