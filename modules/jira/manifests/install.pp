class jira::install {

  if ! defined(File[$jira::installdir]) {
    file { $jira::installdir:
      ensure => 'directory',
      owner => $jira::user,
      group => $jira::group,
    }
  }

  $installdirtreearray = dirtree($jira::installdir)
  ensure_resource('file', $installdirtreearray, {'ensure' => 'directory'})

  # Response file for app unattended installation
  file { "${jira::appinstallerdir}\\response.varfile":
    content => template("jira/response.varfile.erb"),
    mode    => '0644',
    require => [ File[$jira::appinstallerdir] ],
  }  

  # Examples of product tarballs from Atlassian
  # Core                - atlassian-jira-core-7.0.3
  # Software (pre-7)    - atlassian-jira-6.4.12
  # Software (7 to 7.1.8 ) - atlassian-jira-software-7.0.4-jira-7.0.4
  # Software (7.1.9 and up) - atlassian-jira-software-7.1.9

  if (versioncmp($jira::version, '7.1.9') < 0) {
    if ((versioncmp($jira::version, '7.0.0') < 0) or ($jira::product_name == 'jira-core')) {
      $file = "atlassian-${jira::product_name}-${jira::version}-${jira::os_arch}.${jira::format}"
    } else {
      $file = "atlassian-${jira::product_name}-${jira::version}-jira-${jira::version}-${jira::os_arch}.${jira::format}"
    }
  } else {
    $file = "atlassian-${jira::product_name}-${jira::version}-${jira::os_arch}.${jira::format}"
  }

  if ! defined(File[$jira::appinstallerdir]) {
    file { $jira::appinstallerdir:
      ensure => 'directory',
      owner => $jira::user,
      group => $jira::group,
    }
  }

  if ! defined(File[$jira::webappdir]) {
    file { $jira::webappdir:
      ensure => 'directory',
      owner => $jira::user,
      group => $jira::group,
    }
  }

# Download App 
  case $jira::deploy_module {
    'archive': {
      archive { "${jira::appinstallerdir}/${file}":
        ensure          => present,
        source          => "${jira::download_url}/${file}",
        creates         => "${jira::webappdir}/conf",
        cleanup         => true,
        checksum_verify => false,
        checksum_type   => 'md5',
        checksum        => $jira::checksum,
        before          => File[$jira::homedir],
        require         => [
          File[$jira::installdir],
          # File[$jira::webappdir],
        ],
      }
    }
    default: {
      fail('deploy_module parameter must equal "archive" or staging""')
    }
  }  

  if ! defined(File[$jira::homedir]) {

   file { $jira::homedir:
      ensure => 'directory',
      owner  => $jira::user,
      group  => $jira::group,
    }
  }

    $homedirtreearray = dirtree($jira::homedir)
    notice($homedirtreearray)
    ensure_resource('file', $homedirtreearray, {'ensure' => 'directory'})
  
# Install JIRA Package
 package { "${jira::package_name} ${jira::version}":
    ensure          => "${jira::version}",
    # allow_virtual   => false, 
    provider        => 'windows',
    source          => "${jira::appinstallerdir}\\${file}",
    require         => File[$jira::homedir],
    install_options => ['-q', '-varfile', "${jira::appinstallerdir}\\response.varfile"]
  } 
}
