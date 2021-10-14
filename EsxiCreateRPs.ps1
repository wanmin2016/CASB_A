#=======================================================================#
#   script:        EsxiCreateRPs.ps1                                    #
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
$NameFile = $DirPath + "\icgqa\namelist.csv"
$PassFile = $DirPath + "\pass"
$LoginUser = Get-Content ($DirPath + "\vCenterUsername.txt")
$VC = 'vCenterServer-0'

#import credentials
read-host -assecurestring | convertfrom-securestring | out-file $PassFile
$pwd = Get-Content $PassFile | ConvertTo-SecureString
$credentials = New-Object System.Management.Automation.PsCredential $LoginUser, $pwd
#Connect to vCenter
Connect-VIServer -Server $VC -Credential $credentials

$devhost = Get-VMHost -Name qa-Maldives
$ICG_RDRole = Get-VIRole -Name "ICG_R&D"
$vmFolder = Get-Folder -Type "VM" -Name "vm"

foreach($person in Import-Csv $NameFile)
{
    $gAcc = Get-VIAccount -Group ($person.domaim + "\" + $person.name) -ErrorAction SilentlyContinue
    if (($null -eq $gAcc) -or ($gAcc.Id.Equals("ºÎÐÀ")))
    {
        continue
    }

    $RP = Get-ResourcePool -Location $devhost -Name $person.name -ErrorAction SilentlyContinue
    if ($null -eq $RP)
    {
        $RP = New-ResourcePool -Location $devhost -Name $person.name
        New-VIPermission -Entity $RP -Principal $gAcc -Role $ICG_RDRole -Propagate:$true
        continue
    }
    $vmPrefix = $person.vmPrefix + "(_|-).+"
    Get-VM | Where-Object {$_.Name -match $vmPrefix} | Move-VM -Destination $RP

    $permi = Get-VIPermission -Entity $RP -Principal $gAcc -ErrorAction SilentlyContinue
    if ($null -eq $permi)
    {
        New-VIPermission -Entity $RP -Principal $gAcc -Role $ICG_RDRole -Propagate:$true
    }
    elseif ($false -eq $permi.Role.Equals($ICG_RDRole.Name))
    {
        Set-VIPermission -Permission $permi -Role $ICG_RDRole -Propagate:$true
    }
}

Disconnect-VIServer -Server $VC -Confirm:$false
