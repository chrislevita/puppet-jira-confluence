# -----------------------------------------------------------------------------
# == Class: jira
#
# This module is used to install Jira.
#
# See README.md for more details
#
class jira (

  # Jira Settings
  $version      = '7.2.6',
  $product      = 'jira',
  $format       = 'exe',
  $installdir   = "C:\\Atlassian\\JIRA",
  $homedir      = "F:\\Atlassian\\Application-Data\\JIRA",
  $user         = 'Administrator',
  $group        = 'Administrators',

  # OS
  $os_arch      = 'x64',

  # Advanced configuration options
  $enable_secure_admin_sessions = false,
  $jira_config_properties       = {'jira.websudo.timeout' => '10'},

  # Data Center
  $datacenter   = false,
  $shared_homedir = undef,

  # Database Settings
  $db                      = 'sqlserver',
  $dbuser                  = 'jiradbuser',
  $dbpassword              = 'mypassword',
  $dbserver                = undef,
  $dbname                  = 'jiradb',
  $dbport                  = '1433',
  $dbdriver                = 'net.sourceforge.jtds.jdbc.Driver',
  $dbtype                  = 'mssql',
  $dburl                   = undef,
  $dbschema                = 'jiraschema',  

  # Configure database settings if you are pooling connections
  $enable_connection_pooling     = false,
  $pool_min_size                 = 20,
  $pool_max_size                 = 40,
  $pool_max_wait                 = 30000,
  $validation_query              = undef,
  $min_evictable_idle_time       = 60000,
  $time_between_eviction_runs    = undef,
  $pool_max_idle                 = 20,
  $pool_remove_abandoned         = true,
  $pool_remove_abandoned_timeout = 300,
  $pool_test_while_idle          = true,
  $pool_test_on_borrow           = false,

  # JVM Settings
  # jre is bundle with the APP installer, so no need to specify the javahome
  $javahome     = "$installdir\\jre",
  $jvm_xms      = '1024',
  $jvm_xmx      = '1024',
  $jvm_permgen  = '256',
  $jvm_optional = '-XX:-HeapDumpOnOutOfMemoryError',
  $java_opts    = '',
  $catalina_opts    = '',

  # Misc Settings
  $download_url          = 'https://downloads.atlassian.com/software/jira/downloads/',
  $checksum              = undef,
  $disable_notifications = false,

  # Choose whether to use puppet-staging, or puppet-archive
  $deploy_module = 'archive',

  # Manage service
  $service_manage = true,
  $service_ensure = running,
  $service_enable = true,
  $service_notify = undef,
  $service_subscribe = undef,
 
  # Command to stop jira in preparation to updgrade. This is configurable
  # incase the jira service is managed outside of puppet.
  $stop_jira = 'service jira stop && sleep 15',

  # Tomcat
  $tomcat_address                   = undef,
  $tomcat_port                      = 8080,
  $tomcat_shutdown_port             = 8005,
  $tomcat_max_http_header_size      = '8192',
  $tomcat_min_spare_threads         = '25',
  $tomcat_connection_timeout        = '20000',
  $tomcat_enable_lookups            = false,
  $tomcat_native_ssl                = false,
  $tomcat_https_port                = 8443,
  $tomcat_redirect_https_port       = undef,
  $tomcat_protocol                  = 'HTTP/1.1',
  $tomcat_use_body_encoding_for_uri = true,
  $tomcat_disable_upload_timeout    = true,
  $tomcat_key_alias                 = undef,
  $tomcat_keystore_file             = "F:\\Atlassian\\Application-Data\\Confluence\\security\\jira.jks",
  $tomcat_keystore_pass             = 'changeit',
  $tomcat_keystore_type             = 'JKS',
  $tomcat_accesslog_format          = '%a %{jira.request.id}r %{jira.request.username}r %t &quot;%m %U%q %H&quot; %s %b %D &quot;%{Referer}i&quot; &quot;%{User-Agent}i&quot; &quot;%{jira.request.assession.id}r&quot;',
    # Please use Jira-Tomcat-Logs for tomcat_log_dir, e.g C:\\Atlassian\\JIRA-Tomcat-Logs for the folder name
  $tomcat_log_dir                   = undef,


  # Tomcat Tunables
  $tomcat_max_threads  = '150',
  $tomcat_accept_count = '100',

  # Reverse https proxy
  $proxy = {},
  # Options for the AJP connector
  $ajp   = {},
  # Context path (usualy used in combination with a reverse proxy)
  $contextpath = '',

  # Resources for context.xml
  $resources = {},
) 
{
  # Windows requires escaping characters, mostly for write them to the response.varfile 
  $homedir_escaped = regsubst($jira::homedir, "\\\\", "\\\\\\", "G")
  $installdir_escaped = regsubst($jira::installdir, '\\\\', '\\\\\\', 'G')
  if $jira::tomcat_log_dir {
    # tomcat_log_dir can't not be undef 
    $tomcat_log_dir_escaped = regsubst($jira::tomcat_log_dir, '\\\\', '\\\\\\', 'G')
  }

  # Parameter validations
  validate_re($db, ['^postgresql','^mysql','^sqlserver','^oracle'], 'The JIRA $db parameter must be "postgresql", "mysql", "sqlserver".')
  validate_hash($proxy)
  validate_re($contextpath, ['^$', '^/.*'])
  validate_hash($resources)
  validate_hash($ajp)
  validate_bool($tomcat_native_ssl)
  validate_absolute_path($tomcat_keystore_file)
  validate_re($tomcat_keystore_type, '^(JKS|JCEKS|PKCS12)$')
      
  if $datacenter and !$shared_homedir {
    fail("\$shared_homedir must be set when \$datacenter is true")
  }

  if $tomcat_redirect_https_port {
    validate_integer($tomcat_redirect_https_port)
    unless ($tomcat_native_ssl) {
        fail('You need to set native_ssl to true when using tomcat_redirect_https_port')
    }
  }

  # The default Jira product starting with version 7 is 'jira-software'
  if ((versioncmp($version, '7.0.0') > 0) and ($product == 'jira')) {
    $product_name = 'jira-software'
    $package_name = 'JIRA Software'
  } else {
    $product_name = $product
    $package_name = 'JIRA'
  }

  if defined('$::jira_version') {
    # If the running version of JIRA is less than the expected version of JIRA
    # Shut it down in preparation for upgrade.
    if versioncmp($version, $::jira_version) > 0 {
      notify { 'Attempting to upgrade JIRA': }
      exec { $stop_jira: before => Anchor['jira::start'] }
    }
  }

  $appinstallerdir = "${installdir}\\atlassian-${product_name}-${version}-standalone"
  if $format == zip {
    $webappdir = "${appinstallerdir}\\atlassian-${product_name}-${version}-standalone"
  } else {
    $webappdir = $appinstallerdir
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

  $merged_jira_config_properties = merge({'jira.websudo.is.disabled' => !$enable_secure_admin_sessions}, $jira_config_properties)

  if $javahome == undef {
    fail('You need to specify a value for javahome')
  }

  anchor { 'jira::start': }    ->
  class { '::jira::install': } ->
  class { '::jira::config': }  ->
  class { '::jira::service': } ->
  anchor { 'jira::end': }
}
