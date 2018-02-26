```
https://git.io/vby9m
  ==> https://gist.githubusercontent.com/cheretbe/1965da139998cdc31e89759a9d33a0d4/raw/
  (gist.github.com ==> cheretbe/vagrant_provision.ps1)
```

```powershell
-localTest
-gitBranch "develop"
-scriptParams @{"Verbose" = $TRUE}
```


```powershell
. ([scriptblock]::Create(((New-Object System.Net.WebClient).DownloadString("https://git.io/vby9m")))) -scriptName "windows-config-builder.ps1"
```
