class jira::service(

  $service_manage        = $jira::service_manage,
  $service_ensure        = $jira::service_ensure,
  $service_enable        = $jira::service_enable,
  $service_notify        = $jira::service_notify,
  $service_subscribe     = $jira::service_subscribe,
  $jira_service_name    = $::getjiraservicename
) {

  # Manage JIRA windows service 
  validate_bool($service_manage)

  if $service_manage {

    validate_string($service_ensure)
    validate_bool($service_enable)

    if $::getjiraservicename != undef and !("" in [$getjiraservicename]){
      service { "${jira_service_name}":
        ensure    => $service_ensure,
        enable    => $service_enable,
        notify    => $service_notify,
        subscribe => $service_subscribe,
        provider  => $service_provider,
      }
    }
  }
}
