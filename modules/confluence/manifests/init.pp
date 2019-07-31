class confluence (

  # Confluence Settings
  $version      = '6.1.1',
  $product      = 'confluence',
  $format       = 'exe',
  $installdir   = "C:\\Atlassian\\Confluence",
  $homedir      = "C:\\Atlassian\\Application-Data\\Confluence",
  $user         = 'Administrator',
  $group        = 'Administrators',
  $manage_user  = true,

  # OS
  $os_arch      = 'x64',

  # JVM Settings
  # jre is bundle with the app installer, so no need to specify the javahome
  $javahome     = "$installdir\\jre",
  $jvm_xms      = '1024m',
  $jvm_xmx      = '1024m',
  $jvm_permgen  = '256m',
  $java_opts    = '',

# Database Settings
  $db                      = 'sqlserver',
  $dbuser                  = 'confluencedbuser',
  $dbpassword              = 'mypassword',
  $dbserver                = '10.224.50.62',
  $dbname                  = 'confluencedb',
  $dbport                  = '1433',
  $dbdriver                = 'net.sourceforge.jtds.jdbc.Driver',
  $dbtype                  = 'mssql',
  $dburl                   = undef,
  $dbschema                = 'confluenceschema',  

  # Misc Settings
  $download_url = 'https://downloads.atlassian.com/software/confluence/downloads/',
  $checksum     = undef,

  # Manage service
  $service_manage = true,
  $service_ensure = running,
  $service_enable = true,
  $service_notify = undef,
  $service_subscribe = undef,

  # Choose whether to use puppet-staging, or puppet-archive
  $deploy_module = 'archive',

  # Manage confluence server
  $manage_service = true,

  # Tomcat
  $tomcat_address                   = undef,
  $tomcat_port                      = 8090,
  $tomcat_max_http_header_size      = '8192',
  $tomcat_min_spare_threads         = '25',
  $tomcat_enable_lookups            = false,
  $tomcat_disable_upload_timeout    = true,
  $tomcat_max_threads               = 200,
  $tomcat_native_ssl                = false,
  $tomcat_key_alias                 = undef,
  # tomcat_keystore_file example folder   "F:\\Atlassian\\Application-Data\\Confluence\\security\\confluence.jks",
  $tomcat_keystore_file             = "F:\\Atlassian\\Application-Data\\Confluence\\security\\confluence.jks",
  $tomcat_keystore_pass             = 'changeit',
  $tomcat_keystore_type             = 'JKS',
  # Please use Confluence-Tomcat-Logs for tomcat_log_dir, e.g C:\\Atlassian\\Confluence-Tomcat-Logs for the folder name
  $tomcat_log_dir                 = undef,
  
  # Tomcat Tunables
  $tomcat_accept_count = 100,
  $tomcat_https_port   = 8443,
  $tomcat_redirect_https_port       = undef,
  # Reverse https proxy setting for tomcat
  $tomcat_proxy = {},
  # Any additional tomcat params for server.xml
  $tomcat_extras = {},
  $context_path  = '',

  # Options for the AJP connector
  $ajp   = {},

) {

# Windows requires escaping characters, mostly for write them to the response.varfile 
  $homedir_escaped = regsubst($confluence::homedir, "\\\\", "\\\\\\", "G")
  $installdir_escaped = regsubst($confluence::installdir, '\\\\', '\\\\\\', 'G')
  if $jira::tomcat_log_dir {
    # tomcat_log_dir can't not be undef 
    $tomcat_log_dir_escaped = regsubst($confluence::tomcat_log_dir, '\\\\', '\\\\\\', 'G')
  }

  # Parameter validations
  validate_re($db, ['^postgresql','^mysql','^sqlserver','^oracle'], 'The Confluence $db parameter must be "postgresql", "mysql", "sqlserver".')
  validate_re($version, '^(?:(\d+)\.)?(?:(\d+)\.)?(\*|\d+)(|[a-z])$')
  validate_absolute_path($installdir)
  validate_absolute_path($homedir)
  validate_bool($manage_user)

  validate_hash($tomcat_proxy)
  validate_hash($tomcat_extras)
  validate_hash($ajp)
  validate_bool($tomcat_native_ssl)
  validate_absolute_path($tomcat_keystore_file)
  validate_re($tomcat_keystore_type, '^(JKS|JCEKS|PKCS12)$')

  $webappdir    = "${installdir}\\atlassian-${product}-${version}-standalone"
  $appinstallerdir  = "${webappdir}"

  if $javahome == undef {
    fail('You need to specify a value for javahome')
  }

  if $tomcat_redirect_https_port {
    validate_integer($tomcat_redirect_https_port)
    unless ($tomcat_native_ssl) {
        fail('You need to set native_ssl to true when using tomcat_redirect_https_port')
    }
  }


  # Archive module checksum_verify = true; this verifies checksum if provided, doesn't if not.
  if $checksum == undef {
    $checksum_verify = false
  } else {
    $checksum_verify = true
  }

  if $dburl {
    $dburl_real = $dburl
  }
  else {
    $dburl_real = $db ? {
      'postgresql' => "jdbc:${db}://${dbserver}:${dbport}/${dbname}",
      'mysql'      => "jdbc:${db}://${dbserver}:${dbport}/${dbname}?useUnicode=true&amp;characterEncoding=UTF8&amp;sessionVariables=storage_engine=InnoDB",
      'oracle'     => "jdbc:${db}:thin:@${dbserver}:${dbport}:${dbname}",
      'sqlserver'  => "jdbc:jtds:${db}://${dbserver}:${dbport}/${dbname}"
    }
  }

  if ! empty($ajp) {
    if $manage_server_xml != 'template' {
      fail('An AJP connector can only be configured with manage_server_xml = template.')
    }
    if ! has_key($ajp, 'port') {
      fail('You need to specify a valid port for the AJP connector.')
    } else {
      validate_re($ajp['port'], '^\d+$')
    }
    if ! has_key($ajp, 'protocol') {
      fail('You need to specify a valid protocol for the AJP connector.')
    } else {
      validate_re($ajp['protocol'], ['^AJP/1.3$', '^org.apache.coyote.ajp'])
    }
  }

  # $merged_confluence_config_properties = merge({'confluence.websudo.is.disabled' => !$enable_secure_admin_sessions}, $confluence_config_properties)

  anchor { 'confluence::start': } ->
  class { '::confluence::install': } ->
  class { '::confluence::config': } ~>
  class { '::confluence::service': } ->
  anchor { 'confluence::end': }
}
