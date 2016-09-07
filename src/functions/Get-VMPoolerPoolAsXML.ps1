function Get-VMPoolerPoolAsXML {
  [xml]$xmlDoc = '<pools xmlns=""></pools>'

  Get-VMPoolerPool | % {
    $poolName = $_.ToString()
    $xmlNode = $xmlDoc.CreateElement('pool')
    $xmlNode.innerText = $poolName

    # Get OS Icon
    $osIcon =  Get-VMPoolerPoolIcon -poolname $poolName
    if ($osIcon -ne '') { $xmlNode.SetAttribute('osicon',$osIcon) }

    $xmlDoc.pools.AppendChild($xmlNode) | Out-Null
  }
  Write-Output $xmlDoc
}
