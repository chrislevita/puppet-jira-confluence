class confluence::config inherits confluence {

File {
    owner => $confluence::user,
    group => $confluence::group,
  }

  # Create External Tomcat log folder
  if $confluence::tomcat_log_dir != undef {
    $dirtree = dirtree("${confluence::tomcat_log_dir}")
    ensure_resource('file', $dirtree, {'ensure' => 'directory'})

    $tomcat_cmd  = "--LogPath \"${tomcat_log_dir}\""
  } else {
    $tomcat_cmd = undef
  }

  # Write cmd: updating Win confluence Service with JAVA memory and tomcat log location 
  file {"${confluence::appinstallerdir}/tomcat8servicecmd.bat":
    content => "${confluence::installdir}\\bin\\tomcat8.exe //US//${::getconfluenceservicename} \
      --JvmMs ${confluence::jvm_xms} \
      --JvmMx ${confluence::jvm_xmx} \
      ${tomcat_cmd}",
  }

 # Update confluence windows service, calling tomcat service update
  exec { 'Update confluence Windows Service':
    command => "C:\\windows\\system32\\cmd.exe /c ${confluence::appinstallerdir}/tomcat8servicecmd.bat",
    subscribe   => File["${confluence::appinstallerdir}/tomcat8servicecmd.bat"],
    logoutput => true,
    refreshonly => true,
  }

  # Creating Windows environment variable JAVA_HOME
  windows_env { 'JAVA_HOME':
    variable  => 'JAVA_HOME',
    value     => "${confluence::javahome}",
    ensure    => present,
    mergemode => clobber,
  }

  # This will add '%JAVA_HOME%' to PATH (windows environment variable), merging it neatly with existing content
  windows_env { 'PATH=%JAVA_HOME%\bin': }

  file { "${confluence::installdir}/confluence/WEB-INF/classes/confluence-init.properties":
    content => template('confluence/confluence-init.properties.erb'),
    mode    => '0755',
    require => Class['confluence::install'],
    notify  => Class['confluence::service'],
  }

  file { "${confluence::installdir}/conf/server.xml":
    content => template('confluence/server.xml.erb'),
    mode    => '0644',
    require => Class['confluence::install'],
    notify  => Class['confluence::service'],
  }

  file { "${confluence::installdir}/conf/logging.properties":
    content => template('confluence/logging.properties.erb'),
    mode    => '0644',
    require => Class['confluence::install'],
    notify  => Class['confluence::service'],
  }

  # file { "${confluence::homedir}/confluence-config.properties":
  #   content => template('confluence/confluence-config.properties.erb'),
  #   mode    => '0644',
  #   require => [ Class['confluence::install'],File[$confluence::homedir] ],
  #   notify  => Class['confluence::service'],
  # }->

}
