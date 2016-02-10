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


Function Invoke-VMPoolerAPI([string]$url = '',$route,$payload = $null,[switch]$NoAuth,[switch]$NoParseResponse) {
  if ($URL -eq '') { $URL = $VMPoolerServiceURI }
  if ($URL.EndsWith('/')) { $URL = $URL.SubString(0,$URL.Length - 1)}

  $props = @{
    'URI' = "$url/$route"
    'Method' = 'GET'
    #'Headers' = @{ 'X-AUTH-TOKEN' = $VMPoolToken}
    #'DisableKeepAlive' = $true
  }
  
  if ($payload -ne $null) {
    $props.Method = 'POST'
    $props.Body = ConvertTo-JSON -InputObject $payload -Depth 10
  }
  
  if (-not $NoAuth) {
    if ($VMPoolCredential -eq [System.Management.Automation.PSCredential]::Empty) {
      $newCred = Get-Credential -Username ($Env:USERNAME) -Message "Credential for VMPooler"
      if ($newCred -eq $null) { Throw "Missing required credentials for VMPooler"; return }
      $Script:VMPoolCredential = $newCred
    }
    
    $props.Credential = $VMPoolCredential
  }
    
  [System.Net.ServicePointManager]::CertificatePolicy = new-object IDontCarePolicy 
  $response = Invoke-WebRequest @props -Verbose

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