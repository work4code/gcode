###########################################################################################
# Title:	VMware health check 
# Filename:	healtcheck.sp1       		
# Date:		16-08-2019
# Version       1.4						
###########################################################################################
# Description:	Scripts that checks the status of a VMware      
# enviroment on the following point:		
# - VMware ESX server Hardware and version	       	
# - VMware VC version				
# - Active Snapshots				
# - CDROMs connected to VMs					
# - Datastores and the free space available	
# - VM information such as VMware tools version,  
#   processor and memory limits								
###########################################################################################
# Configuration:
#
#   Edit the powershell.ps1 file and edit the following variables:
#   $vcserver="localhost"
#   Enter the VC server, if you execute the script on the VC server you can use localhost
#   $filelocation="D:\temp\healthcheck.htm"
#   Specify the path where to store the HTML output
#   $enablemail="yes"
#   Enable (yes) or disable (no) to sent the script by e-mail
#   $smtpServer = "<>" 
#   Specify the SMTP server in your network
#   $mailfrom = "VMware Healtcheck <>"
#   Specify the from field
#   $mailto = "<>"
#   Specify the e-mail address
###########################################################################################
# Usage:
#
#   Manually run the healthcheck1.ps1 script":
#   1. Open Powershell
#   2. Browse to the directory where the healthcheck.ps1 script resides
#   3. enter the command:
#   .\healthcheck1.ps1
#
#   To create a schedule task in for example Windows 2003 use the following 
#   syntax in the run property:
#   powershell -command "& 'path\healthcheck.ps1'
#   edit the path 
###########################################################################################

####################################
# VMware VirtualCenter server name #
####################################
$vcserver="192.168.105.9"

##################
# Add VI-toolkit #
##################
Add-PSsnapin VMware.VimAutomation.Core
Initialize-VIToolkitEnvironment.ps1
connect-VIServer $vcserver

#############
# Variables #
#############
$filelocation="D:\temp\healthcheck_prod.htm"
$vcversion = get-view serviceinstance
$snap = get-vm | get-snapshot
$date=get-date

##################
# Mail variables #
##################
$enablemail="no"
#$enablemail="yes"
#$smtpServer = "mail.ivobeerens.nl" 
#$mailfrom = "VMware Healtcheck <powershell@ivobeerens.nl>"
#$mailto = "ivo@ivobeerens.nl"

#############################
# Add Text to the HTML file #
#############################
ConvertTo-Html �title "VMware Health Check " -body "<H1>VMware Health script</H1>" -head "<link rel='stylesheet' href='style.css' type='text/css' />" | Out-File $filelocation#
#ConvertTo-Html �title "VMware Health Check " -body "<H4>Date and time</H4>",$date -head "<link rel='stylesheet' href='style.css' type='text/css' />" | Out-File -Append $filelocation
#ConvertTo-Html –title “VMware Health Check ” –body “Date and time”,$date -head “body { background-color:#EEEEEE; } body,table,td,th { font-family:Tahoma; color:Black; Font-Size:10pt } th { font-weight:bold; background-color:#CCCCCC; } td { background-color:white; } ” | Out-File -Append $filelocation

#######################
# VMware ESX hardware #
#######################
Get-VMHost | Get-View | ForEach-Object { $_.Summary.Hardware } | Select-object Vendor, Model, MemorySize, CpuModel, CpuMhz, NumCpuPkgs, NumCpuCores, NumCpuThreads, NumNics, NumHBAs | ConvertTo-Html -title "VMware ESX server Hardware configuration" -body "<H2>VMware ESX server Hardware configuration.</H2>" -head "<link rel='stylesheet' href='style.css' type='text/css' />" | Out-File -Append $filelocation

Get-VMHost  |  select Name,ConnectionState,PowerState | ConvertTo-Html -title "VMware ESX servers status " -body "<H2>VMware ESX server versions and builds.</H2>" -head "<link rel='stylesheet' href='style.css' type='text/css' />" | Out-File -Append $filelocation

#######################
# VMware ESX versions #
#######################
get-vmhost | % { $server = $_ |get-view; $server.Config.Product | select { $server.Name }, Version, Build, FullName }| ConvertTo-Html -title "VMware ESX server versions" -body "<H2>VMware ESX server versions and builds.</H2>" -head "<link rel='stylesheet' href='style.css' type='text/css' />" | Out-File -Append $filelocation

######################
# VMware VC version  #
######################
$vcversion.content.about | select Version, Build, FullName | ConvertTo-Html -title "VMware VirtualCenter version" -body "<H2>VMware VC version.</H2>" -head "<link rel='stylesheet' href='style.css' type='text/css' />" |Out-File -Append $filelocation

#############
# Snapshots # 
#############
$snap | select vm, name,created,description | ConvertTo-Html -title "Snaphots active" -body "<H2>Snapshots active.</H2>" -head "<link rel='stylesheet' href='style.css' type='text/css' />"| Out-File -Append $filelocation

$Datastores = Get-Datastore | Sort Name
$myCol = @()
ForEach ($Datastore in $Datastores)
{
	$myObj = "" | Select-Object Datastore, UsedGB, FreeGB, PercFree
	$myObj.Datastore = $Datastore.Name
	$myObj.UsedGB = UsedSpace $Datastore
	$myObj.FreeGB = FreeSpace $Datastore
	$myObj.PercFree = PercFree $Datastore
	$myCol += $myObj
}
$myCol | Sort-Object PercFree | ConvertTo-Html -title "Datastore space " -body "<H2>Datastore space available.</H2>" -head "<link rel='stylesheet' href='style.css' type='text/css' />" | Out-File -Append $filelocation

# Invoke-Item $filelocation

######################
# E-mail HTML output #
######################
if ($enablemail -match "yes") 
{ 
$msg = new-object Net.Mail.MailMessage
$att = new-object Net.Mail.Attachment($filelocation)
$smtp = new-object Net.Mail.SmtpClient($smtpServer) 
$msg.From = $mailfrom
$msg.To.Add($mailto) 
$msg.Subject = "VMware Healthscript"
$msg.Body = "VMware healthscript"
$msg.Attachments.Add($att) 
$smtp.Send($msg)
}

##############################
# Disconnect session from VC #
##############################

disconnect-viserver -confirm:$false

##########################
# End Of Healthcheck.ps1 #
##########################



