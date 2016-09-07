Function Get-VMPoolerAllVMsAsXML {
  [xml]$xmlDoc = '<poolerdetail xmlns=""></poolerdetail>'
  Get-VMPoolerToken | Get-VMPoolerTokenDetail | % {
    # Convert the tokens
    $xmlToken = $xmlDoc.CreateElement('token')
    $xmlToken.SetAttribute('name',$_.TokenID)
    $xmlToken.SetAttribute('created',$_.created)
    $xmlToken.SetAttribute('lastuse',$_.last)
    $xmlDoc.poolerdetail.AppendChild($xmlToken) | Out-Null

    # Convert all the VMs
    $_.VMs_all | % { Get-VMPoolerVM -VM $_ } | % {
      $xmlVM = $xmlDoc.CreateElement('vm')
      $xmlVM.SetAttribute('name',$_.VMName)
      $xmlVM.SetAttribute('domain',$_.domain)
      $xmlVM.SetAttribute('template',$_.template)
      $xmlVM.SetAttribute('lifetime',$_.lifetime)
      $xmlVM.SetAttribute('running',$_.running)
      $xmlVM.SetAttribute('state',$_.state)
      if ($_.ip -eq '') {
        $xmlVM.SetAttribute('ip','MISSING!')
      } else {
        $xmlVM.SetAttribute('ip',$_.ip)
      }

      if ($_.tags -ne $null) {
        # Append tag elements
        $tags = $_.tags
        Get-Member -InputObject $_.tags -MemberType NoteProperty | % {
          $tagName = $_.Name
          $xmlNode = $xmlDoc.CreateElement('tag')
          $xmlNode.SetAttribute('key',$tagName)
          $xmlNode.SetAttribute('value',$tags."$tagName") #"
          $xmlVM.AppendChild($xmlNode) | Out-Null
        }
      }

      # Create pretty version of minutes left
      $PrettyMins = ''
      if ($_.MinutesLeft -le 0) {
        $PrettyMins = 'Now'
      } else {
        $ts = New-TimeSpan -Minutes $_.MinutesLeft
        if ($ts.Days -gt 0) {
          $PrettyMins = $PrettyMins + "$($ts.Days)d "
        }
        if ($ts.Hours -gt 0) {
          $PrettyMins = $PrettyMins + "$($ts.Hours)h "
        }
        if ($ts.Minutes -gt 0) {
          $PrettyMins = $PrettyMins + "$($ts.Minutes)m"
        }
      }

      $xmlVM.SetAttribute('FQDN',$_.FQDN)
      $xmlVM.SetAttribute('Started',$_.Started)
      $xmlVM.SetAttribute('Expires',$_.Expires)
      $xmlVM.SetAttribute('MinutesLeft',$_.MinutesLeft)
      $xmlVM.SetAttribute('PrettyMinutesLeft',$PrettyMins)
      $poolIcon = Get-VMPoolerPoolIcon -Poolname ($_.template)
      $xmlVM.SetAttribute('TemplateIcon',$poolIcon)

      $xmlToken.AppendChild($xmlVM) | Out-Null
    }
  }
  Write-Output $xmlDoc
}
