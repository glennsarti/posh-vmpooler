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
      
      if ($_.tags -ne $null) {
        # Append tag elements
        $tags = $_.tags
        Get-Member -InputObject $_.tags -MemberType NoteProperty | % { 
          $tagName = $_.Name
          $xmlNode = $xmlDoc.CreateElement('tag')
          $xmlNode.SetAttribute('key',$tagName)
          $xmlNode.SetAttribute('value',$tags."$tagName")
          $xmlVM.AppendChild($xmlNode) | Out-Null
        }
      }
      
      $xmlVM.SetAttribute('FQDN',$_.FQDN)
      $xmlVM.SetAttribute('Started',$_.Started)
      $xmlVM.SetAttribute('Expires',$_.Expires)
      $xmlVM.SetAttribute('MinutesLeft',$_.MinutesLeft)
      $xmlToken.AppendChild($xmlVM) | Out-Null
    }
  }
  Write-Output $xmlDoc
}


function Get-VMPoolerPoolAsXML {
  [xml]$xmlDoc = '<pools xmlns=""></pools>'
  
  Get-VMPoolerPool | % {
    $xmlNode = $xmlDoc.CreateElement('pool')
    $xmlNode.innerText = $_.ToString()
    $xmlDoc.pools.AppendChild($xmlNode) | Out-Null   
  }
  Write-Output $xmlDoc
}

function Start-VMPoolerUI {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$URL = ''

    ,[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
    [PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty
  )
  
  Begin {
  }
  
  Process {
    # if ($URL.EndsWith('/')) { $URL = $URL.SubString(0,$URL.Length - 1)}
    # try {
    #   Get-VMPoolerStatus -URL $URL | Out-Null
    # }
    # catch {
    #   Write-Error "Could not connect to VMPooler at $url"
    #   return
    # }
    
    # $Script:VMPoolerServiceURI = $URL
    
    # if ($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
    #   $Script:VMPoolCredential = $Credential
    # }
    

    # Load XAML from the external file
    Write-Verbose "Loading the window XAML..."
    [xml]$xaml = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath 'poolerui\PoolerUI.xaml'))
    
    # Build the GUI
    Write-Verbose "Parsing the window XAML..."
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $thisWindow = [Windows.Markup.XamlReader]::Load($reader)

    # Wire up the XAML
    Write-Verbose "Adding XAML event handlers..."
    # (Get-WPFControl 'buttonBrowseReportPath' -Window $thisWindow).Add_Click({
    #   # TODO Perhaps create a wizard to enter a server name and automatically create a UNC to the default puppet path? \\<server>\c$\ProgramData....
    #   $dialogWindow = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
    #     SelectedPath = (Get-WPFControl 'textReportPath' -Window $thisWindow).Text;
    #     ShowNewFolderButton = $false;
    #     Description = "Browse for Puppet Report path";
    #   }
      
    #   $result = $dialogWindow.ShowDialog()
      
    #   if ($result.ToString() -eq 'Ok') {
    #     (Get-WPFControl 'textReportPath' -Window $thisWindow).Text = $dialogWindow.SelectedPath
    #   }
    # })
    
    Connect-VMPooler -URL $URL -Credential $Credential | Out-Null
    
    # Write the xml document to the XAML for databinding
    (Get-WPFControl 'xmlPoolList' -Window $thisWindow).Document = (Get-VMPoolerPoolAsXML)
    (Get-WPFControl 'xmlPoolerDetail' -Window $thisWindow).Document = (Get-VMPoolerAllVMsAsXML)
    
    # Show the GUI
    Write-Verbose "Showing the window..."
    [void]($thisWindow.ShowDialog())
    Write-Verbose "Cleanup..."
    $thisWindow.Close()
    $thisWindow = $null    
  }
  
  End {
  }

}