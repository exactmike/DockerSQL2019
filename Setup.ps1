[cmdletbinding()]
param(
    [string]$ImageName = '2019-latest'
    ,
    [SecureString]$InitialPassword
    ,
    [string]$ContainerName
    ,
    [SecureString]$ProductionPassword
    ,
    [switch]$UpdatePassword
)
$PlainInitialPassword = $InitialPassword | ConvertFrom-SecureString -AsPlainText
$PlainProductionPassword = $ProductionPassword | ConvertFrom-SecureString -AsPlainText

if ($true -ne $UpdatePassword)
{
    docker pull mcr.microsoft.com/mssql/server:$ImageName

    docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=$PlainInitialPassword" `
        -p 1433:1433 --name $ContainerName `
        --mount 'type=volume,source=sqlvolume,destination=/var/opt/mssql' `
        -d mcr.microsoft.com/mssql/server:$ImageName

    Write-Verbose -Message 'Sleeping for 10'
    Start-Sleep -Seconds 10
}

docker exec -it $ContainerName /opt/mssql-tools/bin/sqlcmd `
    -S localhost -U SA -P $PlainInitialPassword `
    -Q "ALTER LOGIN SA WITH PASSWORD='$PlainProductionPassword'"
