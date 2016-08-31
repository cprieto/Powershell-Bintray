#require -version 4.0

$base_uri = "https://api.bintray.com"

Function Get-BintrayCredentials {
  Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $User,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Token
  )

  Process {
    New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Token -AsPlainText -Force))
  }
}

Function Get-BintrayVersion {
  Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Token,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Account,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Repository,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Package,

    [ValidateNotNullOrEmpty()]
    [String] $User = $Account,

    [ValidateNotNullOrEmpty()]
    [String] $Version = "_latest",
  )

  Process {
    $credential = Get-BintrayCredentials -User $User -Token $Token
    $url = "$base_uri/packages/$Account/$Repository/$Package/versions/$Version"

    Invoke-WebRequest -Uri $url -Credential $credential | ConvertFrom-JSON
  }
}

Function Get-BintrayRepository {
  Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Token,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Account,

    [ValidateNotNullOrEmpty()]
    [String] $User = $Account,

    [String] $Repository
  )
  Process {
    $credential = Get-BintrayCredentials -User $User -Token $Token
    $url = "$base_uri/repos/$Account"
    If ([String]::IsNullOrWhiteSpace($Repository) -ne $true) {
      $url = "$url/$Repository"
    }

    Invoke-WebRequest -Uri $url -Credential $credential -Method Get | ConvertFrom-JSON
  }
}

Function Get-BintrayPackage {
  Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Token,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Account,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Repository,

    [ValidateNotNullOrEmpty()]
    [String] $User = $Account,

    [String] $Package
  )

  Process {
    $credential = Get-BintrayCredentials -User $User -Token $Token
    $url = "$base_uri/repos/$Account/$Repository/packages"
    If ([String]::IsNullOrWhiteSpace($Package) -ne $true) {
      $url = "$base_uri/packages/$Account/$Repository/$Package"
    }

    Invoke-WebRequest -Uri $url -Credential $credential -Method Get | ConvertFrom-JSON
  }
}

Function New-BintrayRepository {
  Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Token,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Account,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Repository,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Type,

    [ValidateNotNullOrEmpty()]
    [String] $User = $Account,

    [String] $Description = "",
    [Switch] $Private
  )
  Process {
    $credential = Get-BintrayCredentials -User $User -Token $Token
    $url = "$base_uri/repos/$Account/$Repository"
    $body = @{
      description = $Description;
      type = $Type;
      Private = "false"
    }

    If ($Private) {
      $body.Set_Item("Private", "true")
    }

    Invoke-WebRequest -Uri $url -Credential $credential -Method Post `
      -Body ($body | ConvertTo-JSON) -ContentType "application/json" `
      | ConvertFrom-JSON
  }
}

Function Remove-BintrayRepository {
  Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Token,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Account,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Repository,

    [ValidateNotNullOrEmpty()]
    [String] $User = $Account
  )

  Process {
    $credential = Get-BintrayCredentials -User $User -Token $Token
    $url = "$base_uri/repos/$Account/$Repository"

    [void] (Invoke-WebRequest -Uri $url -Credential $credential -Method Delete)
  }
}

Export-ModuleMember Get-BintrayVersion
Export-ModuleMember Get-BintrayRepository
Export-ModuleMember Get-BintrayPackage

Export-ModuleMember New-BintrayRepository

Export-ModuleMember Remove-BintrayRepository
