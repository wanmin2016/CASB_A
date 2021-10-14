#=======================================================================#
#   script:        EsxiCreateBaseEnv.ps1                                #
#   function:      Configuring initial environment                      #
#   owner:         hexin                                                #
#   vsphere:       VMware vSphere PowerCLI 6.0 Release 2 build 3056836  #
#   created:       12/21/2015                                           #
#   modified:      12/25/2015                                           #
#=======================================================================#
Add-PSSnapin VMware.VimAutomation.Core

# Get directory path
$0 = $MyInvocation.MyCommand.Definition
$DirPath = [System.IO.Path]::GetDirectoryName($0)

#The name list stored in $DirPath\namelist.csv. And encrypted passwd stored in $DirPath\pass.txt
$qaNameFile = $DirPath + "\icgqa\namelist.csv"
$devNameFile = $DirPath + "\icgdev\namelist.csv"
$PassFile = $DirPath + "\pass"
$LoginUser = Get-Content ($DirPath + "\vCenterUsername.txt")
$VC = 'vCenterServer-0'
$defaultDomain = 'vsphere.local'
$logFile = $DirPath + '\auto.log'

#import credentials
$pwd = Get-Content $PassFile | ConvertTo-SecureString
$credentials = New-Object System.Management.Automation.PsCredential $LoginUser, $pwd

#Connect to vCenter
Connect-VIServer -Server $VC -Credential $credentials

$allGroup = Get-VIAccount -Group -domain $defaultDomain | Where-Object {$_.Name -match ".*(ICG_|ESXi-admin).*"}

$ICG_RDRole = Get-VIRole -Name "ICG_R&D"

##################
## Network part ##
$netRootFolder = Get-Folder -Type Network -Name network
$pubNetFolder = New-Folder -Location $netRootFolder -Name "公用网络" -Confirm:$false
$prvNetFolder = New-Folder -Location $netRootFolder -Name "个人网络" -Confirm:$false
New-VIPermission -Entity $prvNetFolder -Principal  $allGroup -Role (Get-VIRole -Name NoAccess) -Propagate:$true

$autoNetFolder = New-Folder -Location $prvNetFolder -Name "autotest" -Confirm:$false
$devNetFolder = New-Folder -Location $prvNetFolder -Name "ICG-DEV" -Confirm:$false
$qaNetFolder = New-Folder -Location $prvNetFolder -Name "ICG-QA" -Confirm:$false
$templateNetFolder = New-Folder -Location $prvNetFolder -Name "template-use" -Confirm:$false

#Create personal network type folders
foreach($qa in Import-Csv $qaNameFile)
{
    $gAcc = Get-VIAccount -Group ($qa.domaim + "\" + $qa.name)
    if ($null -eq $gAcc)
    {
        continue
    }
    $qaFolder = New-Folder -Location $qaNetFolder -Name $qa.name -Confirm:$false
    New-VIPermission -Entity $qaFolder -Principal $gAcc -Role $ICG_RDRole -Propagate:$true
}

foreach($dev in Import-Csv $devNameFile)
{
    $gAcc = Get-VIAccount -Group ($dev.domaim + "\" + $dev.name)
    if ($null -eq $gAcc)
    {
        continue
    }
    $devFolder = New-Folder -Location $devNetFolder -Name $dev.name -Confirm:$false
    New-VIPermission -Entity $devFolder -Principal $gAcc -Role $ICG_RDRole -Propagate:$true
}
## Network part end ##
######################

##########################
## VM and template part ##
$vmRootFolder = Get-Folder -Type VM -Name vm
$vmFileName = $DirPath + '\baseinfo\vmFolderInfo.txt'

# Must have ICG-QA and ICG-DEV in the vmFolderInfo.txt
for($file=[System.IO.File]::OpenText("$vmFileName"); !($file.EndOfStream); $line=$file.ReadLine())
{
    $folderName = $line.Trim(" ")
    New-Folder -Name $folderName -Location $vmRootFolder
}
$file.Close()

$qaVMFolder = Get-Folder -Name 'ICG-QA' -Type vm
$devVMFolder = Get-Folder -Name 'ICG-DEV' -Type vm

if($null -ne $qaVMFolder)
{
    foreach($qa in Import-Csv $qaNameFile)
    {
        New-Folder -Name $qa.name -Location $qaVMFolder
    }
}
if($null -ne $devVMFolder)
{
    foreach($dev in Import-Csv $devNameFile)
    {
        New-Folder -Name $dev.name -Location $devVMFolder
    }
}
## VM folder part end ##
########################

########################
## Resource Pool part ##
$vmHostFile = $DirPath + '\baseinfo\esxHostInfo.txt'

foreach($esxHost in Import-Csv $vmHostFile)
{
    if($esxHost.group.Equals("qa"))
    {
        $NameFile = $qaNameFile
    }
    elseif($esxHost.group.Equals("dev"))
    {
        $NameFile = $devNameFile
    }
    else
    {
        continue
    }

    foreach($person in Import-Csv $NameFile)
    {
        $gAcc = Get-VIAccount -Group ($person.domaim + "\" + $person.name)
        if (($null -eq $gAcc) -or ($gAcc.Id.Equals("何欣")))
        {
            continue
        }

        $RP = New-ResourcePool -Location $esxHost -Name $person.name
        New-VIPermission -Entity $RP -Principal $gAcc -Role $ICG_RDRole -Propagate:$true
    }
}
## Resource Pool part end ##
############################

Disconnect-VIServer -Server $VC -Confirm:$false
