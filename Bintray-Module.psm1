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

function isURIWeb($address) {
  $uri = $address -as [System.URI]
  $uri.AbsoluteURI -ne $null -and $uri.Scheme -match '[http|https]'
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
    [String] $Version = "_latest"
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

Function Get-BintrayLicense {
  Process {
    $url = "$base_uri/licenses/oss_licenses"
    Invoke-WebRequest -Uri $url -Method Get | ConvertFrom-JSON
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

    [ValidateNotNullOrEmpty()]
    [ValidateSet('generic', 'maven', 'debian', 'rpm', 'docker', 'npm', 'opkg', 'nuget', 'vagrant')]
    [String] $Type = 'generic',

    [ValidateNotNullOrEmpty()]
    [String] $User = $Account,

    [String] $Description = "",
    [String[]] $Labels,
    [Switch] $Private
  )

  Process {
    $credential = Get-BintrayCredentials -User $User -Token $Token
    $url = "$base_uri/repos/$Account/$Repository"
    $body = @{
      description = $Description;
      type = ($Type.ToLower());
      private = "false"
    }

    If ($Private) {
      $body.Set_Item("private", "true")
    }

    If ($Labels) {
      $body.Add("labels", $Labels)
    }

    Invoke-WebRequest -Uri $url -Credential $credential -Method Post `
      -Body ($body | ConvertTo-JSON) -ContentType "application/json" `
      | ConvertFrom-JSON
  }
}

Function New-BintrayPackage {
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
    [String] $Name,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String[]] $Licenses,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({isURIWeb $_})]
    [String] $VCSUrl,

    [ValidateNotNullOrEmpty()]
    [String] $User = $Account,

    [String] $Description = "",
    [String[]] $Labels
  )

  Process {
    $credential = Get-BintrayCredentials -User $User -Token $Token
    $url = "$base_uri/packages/$Account/$Repository"
    $body = @{
      name = $Name;
      description = $Description;
      licenses = $Licenses;
      vcs_url = $VCSUrl;
    }

    If ($Labels) {
      $body.Add("labels", $Labels)
    }

    Invoke-WebRequest -Uri $url -Credential $credential -Method Post `
      -Body ($body | ConvertTo-JSON) -ContentType "application/json" `
      | ConvertFrom-JSON
  }
}

Function New-BintrayVersion {
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

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Name,

    [ValidateNotNullOrEmpty()]
    [String] $User = $Account,

    [String] $Description = "",
    [String] $VCSTag,
    [DateTime] $ReleasedOn = (Get-Date)
  )

  Process {
    $credential = Get-BintrayCredentials -User $User -Token $Token
    $url = "$base_uri/packages/$Account/$Repository/$Package/versions"
    $body = @{
      name = $Name;
      description = $Description;
      released = $ReleasedOn;
      licenses = $Licenses;
    }

    If ($VCSTag) {
      $body.Set_Item("vcs_tag", $VCSTag)
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

Function Remove-BintrayPackage {
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
    [String] $User = $Account
  )

  Process {
    $credential = Get-BintrayCredentials -User $User -Token $Token
    $url = "$base_uri/packages/$Account/$Repository/$Package"

    [void] (Invoke-WebRequest -Uri $url -Credential $credential -Method Delete)
  }
}

Function Remove-BintrayVersion {
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

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Version,

    [ValidateNotNullOrEmpty()]
    [String] $User = $Account
  )

  Process {
    $credential = Get-BintrayCredentials -User $User -Token $Token
    $url = "/packages/$Account/$Repository/$Package/versions/$Version"

    [void] (Invoke-WebRequest -Uri $url -Credential $credential -Method Delete)
  }
}

Function Set-BintrayReleaseContent {
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

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $Version,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $InFile,

    [String] $Path,

    [ValidateNotNullOrEmpty()]
    [String] $User = $Account,

    [Switch] $Publish
  )

  Process {
    $credential = Get-BintrayCredentials -User $User -Token $Token
    If ($Path -ne $null) {
      $Path = [System.IO.Path]::GetFileName($InFile)
    }

    $url = "$base_uri/content/$Account/$Repository/$Package/$Version/$Path"
    If ($Publish) {
      $url = "$url`?publish=1"
    }

    Invoke-WebRequest -Uri $url -Credential $credential -Method Put -InFile $InFile `
        | ConvertFrom-Json
  }
}

Export-ModuleMember Get-BintrayVersion
Export-ModuleMember Get-BintrayRepository
Export-ModuleMember Get-BintrayPackage
Export-ModuleMember Get-BintrayLicense

Export-ModuleMember New-BintrayRepository
Export-ModuleMember New-BintrayPackage
Export-ModuleMember New-BintrayVersion

Export-ModuleMember Remove-BintrayRepository
Export-ModuleMember Remove-BintrayPackage
Export-ModuleMember Remove-BintrayVersion

Export-ModuleMember Set-BintrayReleaseContent
