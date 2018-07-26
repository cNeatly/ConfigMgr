<#
AUTHOR  : Christian Säuberlich | neo42 GmbH
DATE    : 25-Juni-2018
COMMENT : Dieses Script liest die Datei Clients.txt aus,
          prüft ob diese Rechner im SCCM vorhanden sind,
          und löscht diese aus SCCM.
          Zusätzlich wird im ScriptOrdner eine Logdatei erstellt.

VERSION : 1.0
#>
# Festlegen der Scriptlokation und erstellen eines Logfiles
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$Date     = Get-Date -Format "dd-MM-yyyy_HH-mm-ss"
$logname      = "$ScriptDir\clientremoval_" + "$Date" + ".log"
$log = $logname
$ClientFile = "$ScriptDir\clients.txt"

"---------------------  Script executed on $Date (dd-MM-yyyy hh:mm:ss) ---------------------" + "`r`n" | Out-File $log -append
#Import SCCM Modul. Bei einem Fehler wird dieser ins Logfile geschrieben.
Try
{
Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
$SiteCode = Get-PSDrive -PSProvider CMSITE
$SMSProvider=$sitecode.SiteServer
Set-Location "$($SiteCode.Name):\"
}
Catch
{
 "$Date" + " [ERROR]`t SCCM Module couldn't be loaded. Script will exit!" | Out-File $log -append
 Exit 1
 }
  #Prüfen ob Clients.txt vorhanden ist.
 If ((Test-Path $ClientFile) -eq $True) {
"$Date" + " [INFO]`t Clients.txt exists. Script will continue!" | Out-File $log -append
}
 else {
 "$Date" + " [ERROR]`t Clients.txt not exists. Script will exit!" | Out-File $log -append
 Exit 1
      }
 #Prüfen ob Clients.txt befüllt ist.
 If ($Null -ne (Get-Content $ClientFile)) {
"$Date" + " [INFO]`t Clients.txt is not empty. Script will continue!" | Out-File $log -append
}
 else {
 "$Date" + " [INFO]`t Clients.txt is empty. Script will exit!" | Out-File $log -append
 Exit 1
     }
# Auslesen der Client.txt. Vergleich der Einträge mit SCCM, und löschen der Einträge im SCCM.
 ForEach ($client in Get-Content $ScriptDir"\clients.txt" -ErrorAction Stop)
  {
   $CN=Get-CMDevice -Name $client
   $name=$CN.Name
   if ($name)
   {
   	try {
       "$date [INFO]`t $name found in SCCM " | Out-File $log -append
	   Remove-CMDevice -name $client -force
	   "$date [INFO]`t $name removed from SCCM " | Out-File $log -append
	    }
	catch
	  {"$date [WARNING]`t $name found in SCCM but unable to delete record.Check further " | Out-File $log -append
	  }
	  }
   else
    { "$date [WARNING]`t $client not found in SCCM " | Out-File $log -append}
   }