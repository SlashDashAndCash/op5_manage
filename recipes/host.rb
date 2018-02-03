# Cookbook Name:: op5_manage
# Recipe:: host


include_recipe 'op5_manage::vault_handler'


op5_manage_change 'config' do
  action :initiate
end


node['op5_manage']['hosts'].each do |name, host|
  op5_manage_host name do
    action_url                      host[:action_url]                     if host.has_key?('action_url')
    active_checks_enabled           host[:active_checks_enabled]          if host.has_key?('active_checks_enabled')
    address                         host[:address]                        if host.has_key?('address')
    # alias
    alias_name                      host[:alias_name]                     if host.has_key?('alias_name')
    check_command                   host[:check_command]                  if host.has_key?('check_command')
    check_command_args              host[:check_command_args]             if host.has_key?('check_command_args')
    check_freshness                 host[:check_freshness]                if host.has_key?('check_freshness')
    check_interval                  host[:check_interval]                 if host.has_key?('check_interval')
    check_period                    host[:check_period]                   if host.has_key?('check_period')
    children                        host[:children]                       if host.has_key?('children')
    contact_groups                  host[:contact_groups]                 if host.has_key?('contact_groups')
    contacts                        host[:contacts]                       if host.has_key?('contacts')
    custom_variable                 host[:custom_variable]                if host.has_key?('custom_variable')
    display_name                    host[:display_name]                   if host.has_key?('display_name')
    event_handler                   host[:event_handler]                  if host.has_key?('event_handler')
    event_handler_args              host[:event_handler_args]             if host.has_key?('event_handler_args')
    event_handler_enabled           host[:event_handler_enabled]          if host.has_key?('event_handler_enabled')
    first_notification_delay        host[:first_notification_delay]       if host.has_key?('first_notification_delay')
    flap_detection_enabled          host[:flap_detection_enabled]         if host.has_key?('flap_detection_enabled')
    flap_detection_options          host[:flap_detection_options]         if host.has_key?('flap_detection_options')
    freshness_threshold             host[:freshness_threshold]            if host.has_key?('freshness_threshold')
    high_flap_threshold             host[:high_flap_threshold]            if host.has_key?('high_flap_threshold')
    hostgroups                      host[:hostgroups]                     if host.has_key?('hostgroups')
    icon_image                      host[:icon_image]                     if host.has_key?('icon_image')
    icon_image_alt                  host[:icon_image_alt]                 if host.has_key?('icon_image_alt')
    low_flap_threshold              host[:low_flap_threshold]             if host.has_key?('low_flap_threshold')
    max_check_attempts              host[:max_check_attempts]             if host.has_key?('max_check_attempts')
    notes                           host[:notes]                          if host.has_key?('notes')
    notes_url                       host[:notes_url]                      if host.has_key?('notes_url')
    notification_interval           host[:notification_interval]          if host.has_key?('notification_interval')
    notification_options            host[:notification_options]           if host.has_key?('notification_options')
    notification_period             host[:notification_period]            if host.has_key?('notification_period')
    notifications_enabled           host[:notifications_enabled]          if host.has_key?('notifications_enabled')
    obsess                          host[:obsess]                         if host.has_key?('obsess')
    parents                         host[:parents]                        if host.has_key?('parents')
    passive_checks_enabled          host[:passive_checks_enabled]         if host.has_key?('passive_checks_enabled')
    process_perf_data               host[:process_perf_data]              if host.has_key?('process_perf_data')
    register                        host[:register]                       if host.has_key?('register')
    retain_nonstatus_information    host[:retain_nonstatus_information]   if host.has_key?('retain_nonstatus_information')
    retain_status_information       host[:retain_status_information]      if host.has_key?('retain_status_information')
    retry_interval                  host[:retry_interval]                 if host.has_key?('retry_interval')
    stalking_options                host[:stalking_options]               if host.has_key?('stalking_options')
    statusmap_image                 host[:statusmap_image]                if host.has_key?('statusmap_image')
    template                        host[:template]                       if host.has_key?('template')
    # 2d_coords
    two_d_coords                    host[:two_d_coords]                   if host.has_key?('two_d_coords')
    action                          host[:action]                         if host.has_key?('action')
  end
end

op5_manage_change 'config' do
  action :save
end
