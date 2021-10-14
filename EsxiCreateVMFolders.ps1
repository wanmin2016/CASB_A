#=======================================================================#
#   script:        EsxiCreateVMFolders.ps1                              #
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

#The name list stored in $DirPath\namelist.csv. And encrypted passwd stored in $DirPath\pass.txt
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

$vmRootFolder = Get-Folder -Type "VM" -Name "ICG-DEV"

foreach($person in Import-Csv $NameFile)
{
    $vmPrefix = $person.vmPrefix + "(_|-).+"
    $vmFolder = Get-Folder -Type "VM" -Name $person.name -ErrorAction SilentlyContinue
    if ($null -eq $vmFolder)
    {
        $vmFolder = New-Folder -Name $person.name -Location $vmRootFolder
    }
    Get-VM | Where-Object {$_.Name -match $vmPrefix} | Move-VM -Destination $vmFolder
}

Disconnect-VIServer -Server $VC -Confirm:$false
