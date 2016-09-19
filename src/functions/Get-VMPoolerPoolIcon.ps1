function Get-VMPoolerPoolIcon($PoolName)
{
  $imagesRoot = Join-Path -Path $PSScriptRoot -ChildPath 'poolerui\images'

  # Last match wins
  $osIcon = ''
  @(
    "^debian-;file:///${imagesRoot}\debian.png",
    "^centos-;file:///${imagesRoot}\centos.ico",
    "^cisco-;file:///${imagesRoot}\cisco.png",
    "^ubuntu-;file:///${imagesRoot}\ubuntu.png",    
    "^redhat-;file:///${imagesRoot}\redhat.png",    
    "^fedora-;file:///${imagesRoot}\fedora.png",    
    "^oracle-;file:///${imagesRoot}\oracle.gif",    
    "^opensuse-;file:///${imagesRoot}\opensuse.png",    
    "^osx-;file:///${imagesRoot}\apple.png",    
    "^solaris-;file:///${imagesRoot}\solaris.png",    
    "^sles-;file:///${imagesRoot}\sles.ico",
    "^scientific-;file:///${imagesRoot}\scientific.png",    
    "^win-;file:///${imagesRoot}\windows.png",    
    "^win-20;file:///${imagesRoot}\windows-20.png",    
    "^win-10;file:///${imagesRoot}\windows-10.png"   
  ) | % {
    $os = $_.Split(';')
    if ($PoolName -match $os[0]) { $osIcon = $os[1] }
  }

  Write-Output $osIcon
}
