# SFDX Utility

This utility is created to help beginners in utilizing sfdx commands without having to remember these commands. This utiilty is targeted towards team, which are yet not using scratch orgs. This helps in migrating team changesets/ ANT to SFDX based development processes.

1. Windows - use ctksfdx.bat
2. *nix - use ctksfdx.sh

## Platform requirements
1. Windows (developed and tested on windows 10, not sure about the rest)
2. SFDX
3. *nix systems (Tested on Linux Mint 18.02)

## Pre-Requisites
1. Create a project folder
2. Within project folder create source code folder named "src"
3. Within src folder, you can keep build manifest file (package.xml)
4. Using SFDX, login into your project instances (sandbox or production instances, to be used within projects)

## Setup
1. Copy this script to project folder
2. Edit Config section by providing following:
	* DEV instance username (username used with SFDX to login into instance) - instance used for development
	* BUILD instance username (username used with SFDX to login into instance) - instance used for build verification/ testing
3. Adjust wait time as per need	

## Usage
1. Retrieve - retrieve metadata of components defined within build manifest (package.xml)
2. Deploy - deploy build to given instance (can use any instance available within force:org:list)
3. Test Build - verify (verification build) your build against a dedicated build test environment
