function installed{
    $name = Get-Module | Select-Object -Property Name
    if ($name -match "PSWindowsUpdate"){
        return $true
    }
    else{
    Set-ExecutionPolicy Unrestricted -Scope CurrentUser
    Install-Module PSWindowsUpdate
    Import-Module PSWindowsUpdate
    return $true
    }
$current_date = Get-Date -Format yyyy'.'MM'.'dd' 'HH':'mm':'ss 
Write-Output $current_date

}
$validation_ofscript = installed
if($validation_ofscript){
    $sysinfo = HOSTNAME.EXE
    Get-WindowsUpdate | Export-CSV win_updates$sysinfo.csv
    $validation_ofFile = Get-ChildItem .\win_updates$sysinfo.csv
    if($validation_ofFile -match 'win_updates'+$sysinfo+'.csv'){
        $valid = $true
    }
    else{
        $valid = $false
    }
    if($valid){
        Write-Output "File succesfully created at:"
        Write-Output $current_date

    }
    else{
        Write-Output "Something went wrong..."
    }
}
else{
    Write-Output "Something went wrong with installation please check ur network connection"
}

