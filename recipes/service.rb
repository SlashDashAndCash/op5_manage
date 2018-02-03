# Cookbook Name:: op5_manage
# Recipe:: service


include_recipe 'op5_manage::vault_handler'


op5_manage_change 'config' do
  action :initiate
end


node['op5_manage']['services'].each do |name, service|
  op5_manage_service name do
    action_url                      service[:action_url]                      if service.has_key?('action_url')
    active_checks_enabled           service[:active_checks_enabled]           if service.has_key?('active_checks_enabled')
    check_command                   service[:check_command]                   if service.has_key?('check_command')
    check_command_args              service[:check_command_args]              if service.has_key?('check_command_args')
    check_freshness                 service[:check_freshness]                 if service.has_key?('check_freshness')
    check_interval                  service[:check_interval]                  if service.has_key?('check_interval')
    check_period                    service[:check_period]                    if service.has_key?('check_period')
    contact_groups                  service[:contact_groups]                  if service.has_key?('contact_groups')
    contacts                        service[:contacts]                        if service.has_key?('contacts')
    display_name                    service[:display_name]                    if service.has_key?('display_name')
    event_handler                   service[:event_handler]                   if service.has_key?('event_handler')
    event_handler_args              service[:event_handler_args]              if service.has_key?('event_handler_args')
    event_handler_enabled           service[:event_handler_enabled]           if service.has_key?('event_handler_enabled')
    file_id                         service[:file_id]                         if service.has_key?('file_id')
    first_notification_delay        service[:first_notification_delay]        if service.has_key?('first_notification_delay')
    flap_detection_enabled          service[:flap_detection_enabled]          if service.has_key?('flap_detection_enabled')
    flap_detection_options          service[:flap_detection_options]          if service.has_key?('flap_detection_options')
    freshness_threshold             service[:freshness_threshold]             if service.has_key?('freshness_threshold')
    high_flap_threshold             service[:high_flap_threshold]             if service.has_key?('high_flap_threshold')
    #Hostgroups are unsupported yet
    #hostgroup_name                 service[:hostgroup_name]                  if service.has_key?('hostgroup_name')
    icon_image                      service[:icon_image]                      if service.has_key?('icon_image')
    icon_image_alt                  service[:icon_image_alt]                  if service.has_key?('icon_image_alt')
    low_flap_threshold              service[:low_flap_threshold]              if service.has_key?('low_flap_threshold')
    max_check_attempts              service[:max_check_attempts]              if service.has_key?('max_check_attempts')
    notes                           service[:notes]                           if service.has_key?('notes')
    notes_url                       service[:notes_url]                       if service.has_key?('notes_url')
    notification_interval           service[:notification_interval]           if service.has_key?('notification_interval')
    notification_options            service[:notification_options]            if service.has_key?('notification_options')
    notification_period             service[:notification_period]             if service.has_key?('notification_period')
    notifications_enabled           service[:notifications_enabled]           if service.has_key?('notifications_enabled')
    obsess                          service[:obsess]                          if service.has_key?('obsess')
    parallelize_check               service[:parallelize_check]               if service.has_key?('parallelize_check')
    passive_checks_enabled          service[:passive_checks_enabled]          if service.has_key?('passive_checks_enabled')
    process_perf_data               service[:process_perf_data]               if service.has_key?('process_perf_data')
    register                        service[:register]                        if service.has_key?('register')
    retain_nonstatus_information    service[:retain_nonstatus_information]    if service.has_key?('retain_nonstatus_information')
    retain_status_information       service[:retain_status_information]       if service.has_key?('retain_status_information')
    servicegroups                   service[:servicegroups]                   if service.has_key?('servicegroups')
    retry_interval                  service[:retry_interval]                  if service.has_key?('retry_interval')
    stalking_options                service[:stalking_options]                if service.has_key?('stalking_options')
    template                        service[:template]                        if service.has_key?('template')

    action                          service[:action]                          if service.has_key?('action')
  end
end


op5_manage_change 'config' do
  action :save
end
