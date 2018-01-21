# Cookbook Name:: op5_manage
# Recipe:: host_downtime


include_recipe 'op5_manage::vault_handler'

node['op5_manage']['host_downtimes'].each do |name, downtime|
  op5_manage_host_downtime name do
    command     downtime[:command]      if downtime.has_key?('command')
    host_name   downtime[:host_name]    if downtime.has_key?('host_name')
    start_time  downtime[:start_time]   if downtime.has_key?('start_time')
    end_time    downtime[:end_time]     if downtime.has_key?('end_time')
    fixed       downtime[:fixed]        if downtime.has_key?('fixed')
    duration    downtime[:duration]     if downtime.has_key?('duration')
    trigger_id  downtime[:trigger_id]   if downtime.has_key?('trigger_id')
    comment     downtime[:comment]      if downtime.has_key?('comment')

    action :create
  end
end
