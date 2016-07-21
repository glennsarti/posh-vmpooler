## DANGER - Major hack
Add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    
    public class IDontCarePolicy : ICertificatePolicy {
        public IDontCarePolicy() {}
        public bool CheckValidationResult(
            ServicePoint sPoint, X509Certificate cert,
            WebRequest wRequest, int certProb) {
            return true;
        }
    }
"@


Function Invoke-VMPoolerAPI {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low',DefaultParameterSetName='CredAuth')]
  param (
    [Parameter(Mandatory=$true)]
    [string]$route

    ,[Parameter(Mandatory=$false)]
    [object]$payload = $null

    ,[Parameter(Mandatory=$false)]
    [string]$Method = 'GET'

    ,[Parameter(Mandatory=$true,ParameterSetName='NoAuth')]
    [switch]$NoAuth

    ,[Parameter(Mandatory=$true,ParameterSetName='TokenAuth')]
    [switch]$TokenAuth

    ,[Parameter(Mandatory=$false)]
    [string]$url = ''

    ,[Parameter(Mandatory=$false)]
    [switch]$NoParseResponse
  )

  Process {
    $CacheMode = ($ENV:PoshVMPoolCache -eq 'True')

    if ($URL -eq '') { $URL = $VMPoolerServiceURI }
    if ($URL.EndsWith('/')) { $URL = $URL.SubString(0,$URL.Length - 1)}

    $props = @{
      'URI' = "$url/$route"
      'Method' = $Method
    }
    
    if ($payload -ne $null) {
      if ($Method -eq 'GET') { $props.Method = 'POST' }
      $props.Body = ConvertTo-JSON -InputObject $payload -Depth 10
    }
    
    switch ($PSCmdlet.ParameterSetName) {
      'NoAuth' { } # Do Nothing
      'CredAuth' {
        if ($VMPoolCredential -eq [System.Management.Automation.PSCredential]::Empty) {
          $newCred = Get-Credential -Username ($Env:USERNAME) -Message "Credential for VMPooler"
          if ($newCred -eq $null) { Throw "Missing required credentials for VMPooler"; return }
          $Script:VMPoolCredential = $newCred
        }
        
        $props.Credential = $VMPoolCredential
      }
      'TokenAuth' {
        if ($Script:VMPoolToken -eq $TokenID -eq '') {
          $Script:VMPoolToken = (Get-VMPoolerToken | Select -First 1).TokenID
        }
        $props.Headers = @{ 'X-AUTH-TOKEN' = "$($Script:VMPoolToken)" }
      }
      default { Throw "No idea what $($PSCmdlet.ParameterSetName) is" }
    }

    [System.Net.ServicePointManager]::CertificatePolicy = new-object IDontCarePolicy
    $response = $null
    $CachedFile = ''
    if ($CacheMode) {
      # Make sure the CacheDir exists
      $CacheDir = Join-Path -Path ((Get-Location -PSProvider FileSystem).Path) -ChildPath 'cache'
      if (-not (Test-Path -Path $CacheDir)) { New-Item -Path $CacheDir -ItemType Directory | Out-Null}
      
      # Generate the ID of the request
      $propsString = ($props | ConvertTo-Json -Depth 10)
      $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
      $utf8 = new-object -TypeName System.Text.UTF8Encoding
      $hash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($propsString)))

      $CachedFile = Join-Path -Path $CacheDir -ChildPath "$($hash).txt"

      # Read Cached response if it exists
      if (Test-Path -Path $CachedFile) {
        Write-Verbose "Using cached response from $CachedFile"
        $response = @{ 'Content' = ([System.IO.File]::ReadAllText($CachedFile) ) }
      }
    }
    
    # Do the web request
    if ($response -eq $null) { $response = Invoke-WebRequest @props }
    
    # Cache the response
    if ($CacheMode) {
      if (-not (Test-Path -Path $CachedFile)) {
        [System.IO.File]::WriteAllText($CachedFile, $response.Content)
      }
    }

    $objResponse = ($response.Content | ConvertFrom-JSON)
    
    if ($NoParseResponse)
    {
      return $objResponse
    }
    
    if (-not $objResponse.ok)
    {
      Write-Error "Error while invoking Pooler API"
      $objResponse = $null
    }
    else
    {
      $objResponse.PSObject.Properties.Remove('ok')
    }
    
    Write-Output $objResponse
  }
}