class confluence::install {

  if ! defined(File[$confluence::installdir]) {
    file { $confluence::installdir:
      ensure => 'directory',
      owner => $confluence::user,
      group => $confluence::group,
    }
  }

  if ! defined(File[$confluence::webappdir]) {
    file { $confluence::webappdir:
      ensure => 'directory',
      owner  => $confluence::user,
      group  => $confluence::group,
    }
  }

  $installdirtreearray = dirtree($confluence::installdir)
  ensure_resource('file', $installdirtreearray, {'ensure' => 'directory'})

  # Response file for app unattended installation
  file { "${confluence::appinstallerdir}\\response.varfile":
    content => template("confluence/response.varfile.erb"),
    mode    => '0644',
    require => [ File[$confluence::appinstallerdir] ],
  }  

  $file = "atlassian-${confluence::product}-${confluence::version}-${confluence::os_arch}.${confluence::format}"
  
Download App 
  case $confluence::deploy_module {
    'archive': {
      archive { "${confluence::appinstallerdir}/${file}":
        ensure          => present,
        source          => "${confluence::download_url}/${file}",
        creates         => "${confluence::webappdir}/conf",
        cleanup         => true,
        checksum_verify => false,
        checksum_type   => 'md5',
        checksum        => $confluence::checksum,
        before          => File[$confluence::homedir],
        require         => [
          File[$confluence::installdir],
          # File[$confluence::webappdir],
        ],
      }
    }
    default: {
      fail('deploy_module parameter must equal "archive" or staging""')
    }
  }  

  if ! defined(File[$confluence::homedir]) {
   file { $confluence::homedir:
      ensure => 'directory',
      owner  => $confluence::user,
      group  => $confluence::group,
    }
  }

    $homedirtreearray = dirtree($confluence::homedir)
    notice($homedirtreearray)
    ensure_resource('file', $homedirtreearray, {'ensure' => 'directory'})
  
# Install confluence Package
 package { "${confluence::product} ${confluence::version}":
    ensure          => "${confluence::version}",
    # allow_virtual   => false, 
    provider        => 'windows',
    source          => "${confluence::appinstallerdir}\\${file}",
    require         => File[$confluence::homedir],
    install_options => ['-q', '-varfile', "${confluence::appinstallerdir}\\response.varfile"]
  } 
}
