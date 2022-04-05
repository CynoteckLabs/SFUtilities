# SFDX Patch Utility :hammer_and_wrench:

:hammer_and_wrench: **THIS IS UNDER DEVELOPMENT - NOT READY YET**

This utility is creates a deployment patch for SFDX projects. For larger projects, it helps identtify delta (changes) between a given git branch or tag to identify files that were changed, to allow delta deployments

## Platform requirements
1. Windows (developed and tested on windows 10, not sure about the rest)
2. SFDX

## Pre-Requisites
1. Have a project folder which has git initiatlized and branches or tags available

## Setup
1. Copy this script to desired location (for example c:\tools\sfdx-patch.ps1)

## Usage
1. Open command prompt
2. Switch to project folder
3. Run command with parameters for example, ./sfdx-patch -old oldPatch -new newPath -pathfolder patch3

## Parameters
1. old : old branch/ tag name to use as baseline (Mandatory)
2. new : new branch/ tag name to be used as target codebase  (Mandatory)
3. patchfolder : name of folder to generate path (Optional). Default value is *patch*
