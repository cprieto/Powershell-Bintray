#require -version 4.0

$base_uri = "https://api.bintray.com"

Function Get-BintrayCredentials {
  Param(
    [Parameter(Mandatory=$true)]
    [String] $User,

    [Parameter(Mandatory=$true)]
    [String] $Token
  )

  Process {
    New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Token -AsPlainText -Force))
  }
}

Function _Try($block) {
  Try {
    &$block
  } Catch {
    Write-Error $_.Exception.Message
    Return -1
  }
}

Function Get-BintrayVersion {
  Param(
    [Parameter(Mandatory=$true)]
    [String] $Token,

    [Parameter(Mandatory=$true)]
    [String] $Account,

    [Parameter(Mandatory=$true)]
    [String] $Repository,

    [Parameter(Mandatory=$true)]
    [String] $Package,

    [String] $Version = "_latest",

    [String] $User = $Account
  )

  Process {
    $credential = Get-BintrayCredentials -User $User -Token $Token
    $url = "$base_uri/packages/$Account/$Repository/$Package/versions/$Version"
    _Try {
      Invoke-WebRequest -Uri $url -Credential $credential | ConvertFrom-JSON
    }
  }
}

Export-ModuleMember Get-BintrayVersion
