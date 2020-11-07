[cmdletbinding()]
param(
    [string]$ImageName = '2019-latest'
    ,
    [SecureString]$InitialPassword
    ,
    [string]$ContainerName
    ,
    [SecureString]$NewPassword
    ,
    [parameter(Mandatory)]
    [ValidateSet('Pull', 'Run', 'ChangePassword')]
    [string[]]$Operation
)

switch ($Operation)
{
    'Pull'
    {
        docker pull mcr.microsoft.com/mssql/server:$ImageName
    }
    'Run'
    {
        if ($null -eq $InitialPassword)
        {
            Throw ('Run operation requires a value for -InitiaLPassword')
        }
        if ([string]::IsNullOrWhiteSpace($ContainerName))
        {
            Throw ('Run operation requires a value for -ContainerName')
        }
        $PlainInitialPassword = $InitialPassword | ConvertFrom-SecureString -AsPlainText -ErrorAction Stop

        docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=$PlainInitialPassword" `
            -p 1433:1433 --name $ContainerName `
            --mount 'type=volume,source=sqlvolume,destination=/var/opt/mssql' `
            -d mcr.microsoft.com/mssql/server:$ImageName

        Write-Verbose -Message 'Sleeping for 10'
        Start-Sleep -Seconds 10
    }
    'ChangePassword'
    {
        if ($null -eq $InitialPassword -or $null -eq $NewPassword)
        {
            Throw ('ChangePassword operation requires a value for -InitiaLPassword and for -NewPassword')
        }
        $PlainNewPassword = $NewPassword | ConvertFrom-SecureString -AsPlainText -ErrorAction Stop

        Write-Verbose -Message "NewPassword is $PlainNewPassword"
        $Query = "`"ALTER LOGIN SA WITH PASSWORD=`'$PlainNewPassword`';`""
        Write-Verbose -Message "Query is $Query"

        docker exec -it $ContainerName /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $PlainInitialPassword -Q $Query

    }
}
