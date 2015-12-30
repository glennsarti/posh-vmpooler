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


Function Invoke-VMPoolerAPI($url,$route,$payload = $null,[switch]$NoAuth) {
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
    $props.Credential = $VMPoolCredential
  }
  
  [System.Net.ServicePointManager]::CertificatePolicy = new-object IDontCarePolicy 
  $response = Invoke-WebRequest @props -Verbose
  
  $response.Content | ConvertFrom-JSON
}