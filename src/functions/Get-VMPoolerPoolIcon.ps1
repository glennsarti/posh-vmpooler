function Get-VMPoolerPoolIcon($PoolName)
{
  # Last match wins
  $osIcon = ''
  @(
    '^debian-;http://icons.iconarchive.com/icons/tatice/operating-systems/16/Debian-icon.png',
    '^centos-;https://www.centos.org/favicon.ico',
    '^cisco-;http://natisbad.org/RH0/img/cisco-icon.png',
    '^ubuntu-;http://icons.iconarchive.com/icons/martz90/circle/16/ubuntu-icon.png',
    '^redhat-;http://www.megaicons.net/static/img/icons_sizes/291/735/16/apps-redhat-icon.png',
    '^fedora-;https://getfedora.org/static/images/fedora_infinity_140x140.png',
    '^oracle-;http://www.idevelopment.info/images/mini_oracle_html_logo.gif',
    '^opensuse-;https://www.opensuse.org/assets/images/favicon.png',
    '^osx-;http://vignette4.wikia.nocookie.net/wowwiki/images/a/a2/Apple-icon-16x16.png/revision/latest?cb=20080327031709',
    '^solaris-;https://www.iconattitude.com/icons/open_icon_library/apps/png/16/distributions-solaris.png',
    '^sles-;http://blog.seader.us/favicon.ico',
    '^scientific-;http://ftp.lip6.fr/pub/linux/distributions/scientific/graphics/version-3/icons/icon.png',
    '^win;http://icons.iconarchive.com/icons/dakirby309/simply-styled/16/OS-Windows-icon.png',
    '^win-20;http://www.easyhost.com/site/media/hw/icon-windows-small2.png',
    '^win-10;http://www.tobiidynavox.com/wp-content/uploads/2015/10/Icon_windows8_16x16.png'
  ) | % {
    $os = $_.Split(';')
    if ($PoolName -match $os[0]) { $osIcon = $os[1] }
  }

  Write-Output $osIcon
}
