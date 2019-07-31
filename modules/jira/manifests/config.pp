class jira::config inherits jira {

  File {
    owner => $jira::user,
    group => $jira::group,
  }

  # Create External Tomcat log folder
  if $jira::tomcat_log_dir != undef {
    $dirtree2 = dirtree("${jira::tomcat_log_dir}")
    ensure_resource('file', $dirtree2, {'ensure' => 'directory'})

    $tomcat_cmd  = "--LogPath \"${tomcat_log_dir}\""
  } else {
    $tomcat_cmd = undef
  }

  # Write cmd: updating Win JIRA Service with JAVA memory and tomcat log location 
  file {"${jira::appinstallerdir}/tomcat8servicecmd.bat":
    content => "${jira::installdir}\\bin\\tomcat8.exe //US//${::getjiraservicename} \
      --JvmMs ${jira::jvm_xms} \
      --JvmMx ${jira::jvm_xmx} \
      ${tomcat_cmd}",
  }

 # Update JIRA windows service, calling tomcat service update
  exec { 'Update JIRA Windows Service':
    command => "C:\\windows\\system32\\cmd.exe /c ${jira::appinstallerdir}/tomcat8servicecmd.bat",
    subscribe   => File["${jira::appinstallerdir}/tomcat8servicecmd.bat"],
    logoutput => true,
    refreshonly => true,
  }

  # Creating Windows environment variable JAVA_HOME
  windows_env { 'JAVA_HOME':
    variable  => 'JAVA_HOME',
    value     => "${jira::javahome}",
    ensure    => present,
    mergemode => clobber,
  }

  # This will add '%JAVA_HOME%' to PATH (windows environment variable), merging it neatly with existing content
  windows_env { 'PATH=%JAVA_HOME%\bin': }

  if $jira::validation_query == undef {
    $validation_query = $jira::db ? {
      'sqlserver'  => 'select 1',
    }
  }
  
  if $jira::time_between_eviction_runs == undef {
    $time_between_eviction_runs = $jira::db ? {
      'sqlserver'  => '300000',
    }
  }

  file { "${jira::installdir}/conf/server.xml":
    content => template('jira/server.xml.erb'),
    mode    => '0644',
    require => Class['jira::install'],
    notify  => Class['jira::service'],
  }->

  file { "${jira::installdir}/conf/context.xml":
    content => template('jira/context.xml.erb'),
    mode    => '0644',
    require => Class['jira::install'],
    notify  => Class['jira::service'],
  }->

  file { "${jira::installdir}/conf/logging.properties":
    content => template('jira/logging.properties.erb'),
    mode    => '0644',
    require => Class['jira::install'],
    notify  => Class['jira::service'],
  }

  file { "${jira::homedir}/jira-config.properties":
    content => template('jira/jira-config.properties.erb'),
    mode    => '0644',
    require => [ Class['jira::install'],File[$jira::homedir] ],
    notify  => Class['jira::service'],
  }->

  file { "${jira::homedir}/dbconfig.xml":
    content => template("jira/dbconfig.${jira::db}.xml.erb"),
    mode    => '0644',
    require => [ Class['jira::install'],File[$jira::homedir] ],
    notify  => Class['jira::service'],
  }

}
