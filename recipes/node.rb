# Cookbook Name:: op5_manage
# Recipe:: node


include_recipe 'op5_manage::vault_handler'


# Set platform depending template and hostgroups.
# Hostgroups defined by user have the higher precedence.
if node['op5_manage']['node'].attribute?(node['platform'])
  node.default['op5_manage']['node']['template'] = node['op5_manage']['node'][node['platform']]['template']
  hostgroups = node['op5_manage']['node'][node['platform']]['hostgroups'].dup
  hostgroups.merge!( node['op5_manage']['node']['hostgroups'].dup )
  node.default['op5_manage']['node']['hostgroups'] = hostgroups
else
  message  = "No settings for platform \"#{node['platform']}\" found. Please provide attributes like:\n"
  message += "{ \"op5_manage\": { \"node\": { \"#{node['platform']}\": { \"template\": \"mytemplate\", \"hostgroups\": [ \"myhostgroup\" ] } } } }"
  raise message
end


op5_manage_change 'config' do
  action :initiate
end


host = node['op5_manage']['node']

op5_manage_host node['fqdn'] do

  action_url			              host['action_url']
  active_checks_enabled			    host['active_checks_enabled']
  address                       node['ipaddress']
  alias_name			              node['hostname']
  check_command			            host['check_command']
  check_command_args			      host['check_command_args']
  check_freshness			          host['check_freshness']
  check_interval			          host['check_interval']
  check_period			            host['check_period']
  children			                host['children']
  contact_groups                host['contact_groups']
  contacts			                host['contacts']
  custom_variable			          host['custom_variable']
  display_name			            host['display_name']
  event_handler			            host['event_handler']
  event_handler_args			      host['event_handler_args']
  event_handler_enabled			    host['event_handler_enabled']
  first_notification_delay			host['first_notification_delay']
  flap_detection_enabled			  host['flap_detection_enabled']
  flap_detection_options			  host['flap_detection_options']
  freshness_threshold			      host['freshness_threshold']
  high_flap_threshold			      host['high_flap_threshold']
  hostgroups                    host['hostgroups']
  icon_image			              host['icon_image']
  icon_image_alt			          host['icon_image_alt']
  low_flap_threshold			      host['low_flap_threshold']
  max_check_attempts			      host['max_check_attempts']
  notes			                    host['notes']
  notes_url			                host['notes_url']
  notification_interval			    host['notification_interval']
  notification_options			    host['notification_options']
  notification_period			      host['notification_period']
  notifications_enabled			    host['notifications_enabled']
  obsess			                  host['obsess']
  parents			                  host['parents']
  passive_checks_enabled			  host['passive_checks_enabled']
  process_perf_data			        host['process_perf_data']
  register			                host['register']
  retain_nonstatus_information	host['retain_nonstatus_information']
  retain_status_information			host['retain_status_information']
  retry_interval			          host['retry_interval']
  stalking_options			        host['stalking_options']
  statusmap_image			          host['statusmap_image']
  template                      host['template']
  two_d_coords			            host['two_d_coords']  # 2d_coords

  action                        host['action']
end



# Create extra services
if node['op5_manage']['node'].has_key?('services')
  node['op5_manage']['node']['services'].each do |name, service|
    op5_manage_service "#{node['fqdn']};#{name}" do
      action_url                    service['action_url']
      active_checks_enabled		      service['active_checks_enabled']
      check_command                 service['check_command']
      check_command_args            service['check_command_args']
      check_freshness		            service['check_freshness']
      check_interval		            service['check_interval']
      check_period		              service['check_period']
      contact_groups		            service['contact_groups']
      contacts		                  service['contacts']
      display_name		              service['display_name']
      event_handler		              service['event_handler']
      event_handler_args		        service['event_handler_args']
      event_handler_enabled		      service['event_handler_enabled']
      file_id		                    service['file_id']
      first_notification_delay		  service['first_notification_delay']
      flap_detection_enabled		    service['flap_detection_enabled']
      flap_detection_options		    service['flap_detection_options']
      freshness_threshold		        service['freshness_threshold']
      high_flap_threshold		        service['high_flap_threshold']
      #Hostgroups are unsupported yet
      #hostgroup_name		            service['hostgroup_name']
      icon_image		                service['icon_image']
      icon_image_alt		            service['icon_image_alt']
      low_flap_threshold		        service['low_flap_threshold']
      max_check_attempts		        service['max_check_attempts']
      notes		                      service['notes']
      notes_url                     service['notes_url']
      notification_interval		      service['notification_interval']
      notification_options		      service['notification_options']
      notification_period		        service['notification_period']
      notifications_enabled		      service['notifications_enabled']
      obsess		                    service['obsess']
      parallelize_check		          service['parallelize_check']
      passive_checks_enabled		    service['passive_checks_enabled']
      process_perf_data		          service['process_perf_data']
      register		                  service['register']
      retain_nonstatus_information  service['retain_nonstatus_information']
      retain_status_information		  service['retain_status_information']
      retry_interval		            service['retry_interval']
      servicegroups		              service['servicegroups']
      stalking_options		          service['stalking_options']
      template                      service['template']

      action                        service['action']
    end
  end
end


op5_manage_change 'config' do
  action :save
end


# Some times a downtime right after creating the host is not visible in op5 cluster.
# We will wait 30 seconds to work around.
ruby_block 'wait_for_host' do
  block do
    sleep(30)
  end
  only_if     { node['op5_manage']['node']['action'].to_s == 'create'       }
  only_if     { node['op5_manage']['node']['initial_downtime']['enabled']   }
  not_if      { node['op5_manage']['node']['initial_downtime']['scheduled'] }
  only_if     { node['op5_manage']['endpoint']['change_delay'] < 30         }
end

# Schedule initial downtime after host provisioning
op5_manage_host_downtime "#{node['hostname']}_initial_downtime" do
  host_name   node['fqdn']
  start_time  Time.new.to_s
  end_time    (Time.new + (node['op5_manage']['node']['initial_downtime']['duration'] * 60 * 60)).to_s
  comment     'Initial downtime after server provisioning (scheduled by Chef)'
  only_if     { node['op5_manage']['node']['action'].to_s == 'create'       }
  only_if     { node['op5_manage']['node']['initial_downtime']['enabled']   }
  not_if      { node['op5_manage']['node']['initial_downtime']['scheduled'] }
  notifies    :run, 'ruby_block[initial_downtime_scheduled]', :immediate
end

ruby_block 'initial_downtime_scheduled' do
  block do
    node.normal['op5_manage']['node']['initial_downtime']['scheduled'] = true
  end
  action :nothing
end
