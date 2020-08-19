# HLD Module  


### Deployment Targets  
* `Local` = `{localhost}\{instance_name}`
* `DEV` = `ETLDEV02\MSSQL2016`
* `UAT` = `MDFLIVEDB01`
* `NONPROD` = `MDFPREPDB01`
* `PROD` = _Unknown_

### How To Use  

```sh
# To restore HLD and Dashboard onto DEV
$Databases = @('HLD,HighLevelDashboard').Split(',')
foreach ($Database in $Databases) {
    $c = 'TESTMDB01'
    $params2 = @{
        SourceServer      = $c
        Database          = $Database
        TargetEnvironment = 'DEV'
    }
}
Invoke-TheGreatMigrator @params2
```

```sh
# To move IdentityService onto local
$env:localhost = 'VDI-DEV99\SQL2017'
$e = 'DEVBUILD05'
$f = 'IdentityService'
$params3 = @{
    SourceServer        = $e
    Database            = $f
    TargetEnvironment   = 'Local'
}
Invoke-TheGreatMigrator @params3
```

```sh
# To restore Live MDF server onto UAT
$liveMdf = getLiveMDFDBServer
$h = 'MyDrFoster'
$params4 = @{
    SourceServer        = $liveMdf
    Database            = $h
    TargetEnvironment   = 'UAT'
}
Invoke-TheGreatMigrator @params4
```

### Examples  