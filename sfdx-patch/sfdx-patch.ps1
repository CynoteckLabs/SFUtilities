<#
.SYNOPSIS
	Generates differential patch for Salesforce code base
.EXAMPLE
	PS> ./sfdx-patch -old oldPatch -new newPath -pathfolder patch3
.NOTES
	Author: Anshul Verma / Cynoteck Technology Solutions LLC
#>

# Command parameters
param (
    [Parameter( Mandatory = $true, HelpMessage="Provide last baseline branch or tag")]
    [string]$oldpath,    
    [Parameter( Mandatory = $true, HelpMessage="Provide new branch or tag")] 
    [string]$newpath,
    [Parameter( HelpMessage="Output directory path for patch(default = patch)")]
    [string]$patchdir=".\patch"
)


function is_local_branch([string] $branch) {
    return (git branch --list $branch) -ne $null
}

function is_local_tag([string] $tag) {
    return (git tag --list $tag) -ne $null
}

try{

    $err = $false

    # Validate if oldpath is valid branch of tag
    $isoldpathValid = (is_local_branch($oldpath)) -or (is_local_tag($oldpath))
    if( $isoldpathValid -eq $false ){
        throw "INVALID INPUT : No Branch of tag exists by name $($oldpath)"
        $err = $true
        # exit 1
    }

    # Validate if newpath is valid branch of tag
    $isnewpathValid = (is_local_branch($newpath)) -or (is_local_tag($newpath))
    if( $isnewpathValid -eq $false ){
        throw "INVALID INPUT : No Branch of tag exists by name $($newpath)"
        $err = $true
        # exit 1
    }

    if($err -eq $false){

        # get all files that changed between given branches/tags
		git diff --raw --name-only $oldpath..$newpath
        $changeFiles = (git diff --raw --name-only $oldpath..$newpath)

        if($changeFiles -ne $null){
            $arrChangeFiles = $changeFiles.split([Environment]::NewLine)

            # Loop through all changed files and generate a path folder (as per path provided) to create patch
            foreach($file in $arrChangeFiles){
                New-Item -Type File -Force -Path "$patchdir\$file"

                # copy changed file from source to target path
                Copy-Item -Path $file -Destination  "$patchdir\$file" 
            }
        }
    }
}catch{
    "Error: $($Error[0]) ($($MyInvocation.MyCommand.Name):$($_.InvocationInfo.ScriptLineNumber))"
	exit 1
}