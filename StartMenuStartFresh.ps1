# Finds and removes the registry key of a remote computer that has Start Menu and Taskbar layout settings
# ...so you can set a custom layout for users that already have profiles loaded on the machine.

# solves https://community.spiceworks.com/topic/2280246-updating-windows-start-menu-for-existing-users-in-windows-10-1909

# Use this after you update the layout at C:\Users\'username here'\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml

$PC = 'targetPChere'

# Get Current User SID since you can't remotely connect to HKEY_CURRENT_USER
$currentSID = Invoke-Command -ComputerName $PC -ScriptBlock {
    $currentusersid = Get-WmiObject -Class win32_computersystem |
    Select-Object -ExpandProperty Username |
    ForEach-Object { ([System.Security.Principal.NTAccount]$_).Translate([System.Security.Principal.SecurityIdentifier]).Value }
    $currentusersid # needed to send the variable down the pipeline above
}

# looks at all folders in the location before finding a match
$EnumerateFolders = Invoke-Command -ComputerName $PC -ScriptBlock {
    Get-ChildItem -Path "REGISTRY::HKEY_USERS\$using:currentSID\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount\"
}

#Since the folder we're looking for has a random SID, we need to match it with a known part of the name
$MatchKey = 'start.tilegrid'
$TileCollection = $EnumerateFolders | Select-String $MatchKey
Write-Output $TileCollection

# Removes the registry key containing Start and Taskbar settings
Invoke-Command -ComputerName $PC -ScriptBlock {
    Remove-ItemProperty "REGISTRY::$using:TileCollection\Current" -Name Data 
}
