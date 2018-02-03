#
# Copyright 2016 Jakob Pfeiffer (<pgp-jkp@pfeiffer.ws>)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#



use_inline_resources if defined?(use_inline_resources)

action :create do

  # Create service object
  service_config = create_service_config

  op5manage = Op5Manage.new(node['op5_manage']['endpoint'], node.run_state['endpoint_auth'], node['op5_manage']['cache'])

  # Request current service configuration from cache or server
  Chef::Log.info "Requesting current service configuration from cache or server"
  comp_config = op5manage.get_service_config(new_resource.name)

  # A new service will be created if Chef didn't get a service configuration from server
  unless comp_config.is_a?(Hash) and "#{comp_config['host_name']};#{comp_config['service_description']}" == new_resource.name
    Chef::Log.info "Service #{new_resource.name} doesn't exist."
    Chef::Log.info "Creating service #{new_resource.name}"

    result = op5manage.create_service(service_config)
    if result
      Chef::Log.info "Sucessfully created service #{new_resource.name}"
      node.run_state['config_changed'] = true
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.error "Couldn't create service #{new_resource.name}"
    end
  else

    # If Chef recieved a service configuration from the server
    # which differs from the recipe then modify the service on the server.
    unless op5manage.service_config_eql?(service_config, comp_config)
      Chef::Log.info "Configuration of service #{new_resource.name} modified. Updating"
      result = op5manage.update_service(service_config)
      if result
        Chef::Log.info "Sucessfully updated service #{new_resource.name}"
        node.run_state['config_changed'] = true
        new_resource.updated_by_last_action(true)
      else
        Chef::Log.error "Couldn't update service #{new_resource.name}"
      end
    else
      Chef::Log.info "#{new_resource.name} already exists - nothing to do."
    end
  end
end



action :remove do
  op5manage = Op5Manage.new(node['op5_manage']['endpoint'], node.run_state['endpoint_auth'], node['op5_manage']['cache'])

  # Request current service configuration from cache or server
  Chef::Log.info "Requesting current service configuration from cache or server"
  comp_config = op5manage.get_service_config(new_resource.name)

  # Remove service from the server if not already done.
  unless comp_config.is_a?(FalseClass)
    Chef::Log.info "Removing service #{new_resource.name}"

    result = op5manage.remove_service(new_resource.name)
    if result
      Chef::Log.info "Sucessfully removed service #{new_resource}"
      node.run_state['config_changed'] = true
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.error "Couldn't remove service #{new_resource}"
    end
  else
    Chef::Log.info "#{new_resource.name} already removed - nothing to do."
  end
end



def create_service_config
  service_config = Hash.new

  service_config['action_url']                     = new_resource.action_url                   unless new_resource.action_url.nil?
  service_config['active_checks_enabled']          = new_resource.active_checks_enabled        unless new_resource.active_checks_enabled.nil?
  service_config['check_command']                  = new_resource.check_command
  service_config['check_command_args']             = new_resource.check_command_args           unless new_resource.check_command_args.nil?
  service_config['check_freshness']                = new_resource.check_freshness              unless new_resource.check_freshness.nil?
  service_config['check_interval']                 = new_resource.check_interval               unless new_resource.check_interval.nil?
  service_config['check_period']                   = new_resource.check_period                 unless new_resource.check_period.nil?
  service_config['contact_groups']                 = new_resource.contact_groups.select{|key, flag| flag == true }.keys               unless new_resource.contact_groups.nil?
  service_config['contacts']                       = new_resource.contacts.select{|key, flag| flag == true }.keys                     unless new_resource.contacts.nil?
  service_config['display_name']                   = new_resource.display_name                 unless new_resource.display_name.nil?
  service_config['event_handler']                  = new_resource.event_handler                unless new_resource.event_handler.nil?
  service_config['event_handler_args']             = new_resource.event_handler_args           unless new_resource.event_handler_args.nil?
  service_config['event_handler_enabled']          = new_resource.event_handler_enabled        unless new_resource.event_handler_enabled.nil?
  service_config['first_notification_delay']       = new_resource.first_notification_delay     unless new_resource.first_notification_delay.nil?
  service_config['flap_detection_enabled']         = new_resource.flap_detection_enabled       unless new_resource.flap_detection_enabled.nil?
  service_config['flap_detection_options']         = new_resource.flap_detection_options.select{|key, flag| flag == true }.keys       unless new_resource.flap_detection_options.nil?
  service_config['freshness_threshold']            = new_resource.freshness_threshold          unless new_resource.freshness_threshold.nil?
  service_config['high_flap_threshold']            = new_resource.high_flap_threshold          unless new_resource.high_flap_threshold.nil?
  #Hostgroups are unsupported yet
  #service_config['hostgroup_name']                 = new_resource.hostgroup_name               unless new_resource.hostgroup_name.nil?
  service_config['icon_image']                     = new_resource.icon_image                   unless new_resource.icon_image.nil?
  service_config['icon_image_alt']                 = new_resource.icon_image_alt               unless new_resource.icon_image_alt.nil?
  service_config['low_flap_threshold']             = new_resource.low_flap_threshold           unless new_resource.low_flap_threshold.nil?
  service_config['max_check_attempts']             = new_resource.max_check_attempts           unless new_resource.max_check_attempts.nil?
  service_config['host_name']                      = new_resource.name.split(';')[0]
  service_config['notes']                          = new_resource.notes                        unless new_resource.notes.nil?
  service_config['notes_url']                      = new_resource.notes_url                    unless new_resource.notes_url.nil?
  service_config['notification_interval']          = new_resource.notification_interval        unless new_resource.notification_interval.nil?
  service_config['notification_options']           = new_resource.notification_options.select{|key, flag| flag == true }.keys         unless new_resource.notification_options.nil?
  service_config['notification_period']            = new_resource.notification_period          unless new_resource.notification_period.nil?
  service_config['notifications_enabled']          = new_resource.notifications_enabled        unless new_resource.notifications_enabled.nil?
  service_config['obsess']                         = new_resource.obsess                       unless new_resource.obsess.nil?
  service_config['parallelize_check']              = new_resource.parallelize_check            unless new_resource.parallelize_check.nil?
  service_config['passive_checks_enabled']         = new_resource.passive_checks_enabled       unless new_resource.passive_checks_enabled.nil?
  service_config['process_perf_data']              = new_resource.process_perf_data            unless new_resource.process_perf_data.nil?
  service_config['register']                       = new_resource.register                     unless new_resource.register.nil?
  service_config['retain_nonstatus_information']   = new_resource.retain_nonstatus_information unless new_resource.retain_nonstatus_information.nil?
  service_config['retain_status_information']      = new_resource.retain_status_information    unless new_resource.retain_status_information.nil?
  service_config['retry_interval']                 = new_resource.retry_interval               unless new_resource.retry_interval.nil?
  service_config['servicegroups']                  = new_resource.servicegroups.select{|key, flag| flag == true }.keys                unless new_resource.servicegroups.nil?
  service_config['service_description']            = new_resource.name.split(';')[-1]
  service_config['stalking_options']               = new_resource.stalking_options.select{|key, flag| flag == true }.keys             unless new_resource.stalking_options.nil?
  service_config['template']                       = new_resource.template                     unless new_resource.template.nil?

  return service_config
end