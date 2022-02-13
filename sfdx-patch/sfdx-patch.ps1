<#
.SYNOPSIS
	Generates differential patch for Salesforce code base
.EXAMPLE
	PS> ./sfdx-patch -old oldPatch -new newPath
.NOTES
	Author: Anshul Verma / Cynoteck Technology Solutions LLC
#>

# Command parameters

# param (
#     [Parameter( Mandatory = $true, ParameterSetName="o",HelpMessage="Provide last baseline branch or tag")]
#     [string]$oldpath,    
#     [Parameter( Mandatory = $true, ParameterSetName="n", HelpMessage="Provide new branch or tag")] 
#     [string]$newpath,
#     [Parameter( ParameterSetName = "p", HelpMessage="Output directory path for patch(default = patch)")]
#     [string]$patchdir
# )

try{

    # if(-not (Test-Path -Path $oldPath)){
    #     throw "$($patchDir) not found"
    # }

    # if(-not (Test-Path -Path $patchDir)){
    #     $patchDir = './patch';
    # }

    ## TODO show command usage

    ## Get diff of two branches to identify delta
    # $changeFiles = git diff --raw --name-only $oldPath..$newPath
    # git diff --raw --name-only $oldPath..$newPath
    $changeFiles = (git diff --raw --name-only 8FEBSITDEPLOYMENT..main)
    # echo $oldpath
    # echo $newpath
    # $changeFiles = (git diff --raw --name-only $oldpath..$newpath)

    $arrChangeFiles = $changeFiles.split([Environment]::NewLine)

    # echo $arrChangeFiles

    foreach($file in $arrChangeFiles){
        New-Item -Type File -Force -Path ".\patch\$file"
        Copy-Item -Path $file -Destination  ".\patch\$file" 
    }




    ## TODO Loop through all changed files and generate a path folder (as per path provided) to create patch

        ##TODO copy changed file from source to target path

}catch{
    "Error: $($Error[0]) ($($MyInvocation.MyCommand.Name):$($_.InvocationInfo.ScriptLineNumber))"
	exit 1
}