# HLD Module  


### Description  

Handles migration of auth databases from source to target sql servers.

* Ensures simple recovery
* Removes user accounts
* Applies permissions from scm
* Handles naming matched to Octopus lifecycle stages


### Deployment Targets  
* `Local` = `{localhost}\{instance_name}`
* `DEV` = `<SERVERNAME>`
* `UAT` = `<SERVERNAME>`
* `NONPROD` = `<SERVERNAME>`
* `PROD` = _Unknown_

### How To Use  

```sh
# To restore HLD and Dashboard onto DEV
$Databases = @('HLD,HighLevelDashboard').Split(',')
foreach ($Database in $Databases) {
    $c = '<SERVERNAME>'
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
$env:localhost = 'x03997'
$e = '<SERVERNAME>'
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
$h = 'MyDatabase'
$params4 = @{
    SourceServer        = $liveMdf
    Database            = $h
    TargetEnvironment   = 'UAT'
}
Invoke-TheGreatMigrator @params4
```
