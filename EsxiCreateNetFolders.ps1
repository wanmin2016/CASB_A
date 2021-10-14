#=======================================================================#
#   script:        EsxiCreateNetFolders.ps1                             #
#   function:           #
#   owner:         hexin                                                #
#   vsphere:       VMware vSphere PowerCLI 6.0 Release 2 build 3056836  #
#   created:       12/21/2015                                           #
#   modified:      12/21/2015                                           #
#=======================================================================#
Add-PSSnapin VMware.VimAutomation.Core

# Get directory path
$0 = $MyInvocation.MyCommand.Definition 
$DirPath = [System.IO.Path]::GetDirectoryName($0)

#The name list stored in $DirPath\Name.txt. And encrypted passwd stored in $DirPath\pass.txt
$NameFile = $DirPath + "\icgdev\namelist.csv"
$PassFile = $DirPath + "\pass"
$LoginUser = Get-Content ($DirPath + "\vCenterUsername.txt")
$VC = 'vCenterServer-0'

#import credentials
#read-host -assecurestring | convertfrom-securestring | out-file $PassFile
$pwd = Get-Content $PassFile | ConvertTo-SecureString
$credentials = New-Object System.Management.Automation.PsCredential $LoginUser, $pwd
#Connect to vCenter
Connect-VIServer -Server $VC -Credential $credentials

$ICG_RDRole = Get-VIRole -Name "ICG_R&D"
$netRootFolder = Get-Folder -Type "network" -Name "ICG-DEV"

foreach($person in Import-Csv $NameFile)
{
    $gAcc = Get-VIAccount -Group ($person.domaim + "\" + $person.name)
    if ($null -eq $gAcc)
    {
        continue
    }

    $netFolder = Get-Folder -Type "network" -Name $person.name
    if ($null -eq $netFolder)
    {
        $netFolder = New-Folder -Name $person.name -Location $netRootFolder
        New-VIPermission -Entity $netFolder -Principal $gAcc -Role $ICG_RDRole -Propagate:$true
    }
}

Disconnect-VIServer -Server $VC -Confirm:$false
