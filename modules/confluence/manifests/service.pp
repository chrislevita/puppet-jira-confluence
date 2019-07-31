class confluence::service(
  $service_manage        = $confluence::service_manage,
  $service_ensure        = $confluence::service_ensure,
  $service_enable        = $confluence::service_enable,
  $service_notify        = $confluence::service_notify,
  $service_subscribe     = $confluence::service_subscribe,
  $confluence_service_name    = $::getconfluenceservicename
)  {

  # Manage confluence windows service 
  validate_bool($service_manage)

  if $service_manage {

    validate_string($service_ensure)
    validate_bool($service_enable)

    if $::getconfluenceservicename != undef and !("" in [$getconfluenceservicename]){
      service { "${confluence_service_name}":
        ensure    => $service_ensure,
        enable    => $service_enable,
        notify    => $service_notify,
        subscribe => $service_subscribe,
        provider  => $service_provider,
      }
    }
  }
}
