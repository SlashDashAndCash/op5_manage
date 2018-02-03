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

  # Create host object
  host_config = create_host_config

  op5manage = Op5Manage.new(node['op5_manage']['endpoint'], node.run_state['endpoint_auth'], node['op5_manage']['cache'])

  # Request current host configuration from cache or server
  Chef::Log.info "Requesting current host configuration from cache or server"
  comp_config = op5manage.get_host_config(new_resource.name)

  # A new host will be created if Chef didn't get a host configuration from server
  unless comp_config.is_a?(Hash) and comp_config['host_name'] == new_resource.name
    Chef::Log.info "Host #{new_resource.name} doesn't exist."
    Chef::Log.info "Creating host #{new_resource.name}"

    result = op5manage.create_host(host_config)
    if result
      Chef::Log.info "Sucessfully created host #{new_resource.name}"
      node.run_state['config_changed'] = true
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.error "Couldn't create host #{new_resource.name}"
    end
  else

    # If Chef recieved a host configuration from the server
    # which differs from the recipe then modify the host on the server.
    unless op5manage.host_config_eql?(host_config, comp_config)
      Chef::Log.info "Configuration of host #{new_resource.name} modified. Updating"
      result = op5manage.update_host(host_config)
      if result
        Chef::Log.info "Sucessfully updated host #{new_resource.name}"
        node.run_state['config_changed'] = true
        new_resource.updated_by_last_action(true)
      else
        Chef::Log.error "Couldn't update host #{new_resource.name}"
      end
    else
      Chef::Log.info "#{new_resource.name} already exists - nothing to do."
    end
  end
end



action :remove do
  op5manage = Op5Manage.new(node['op5_manage']['endpoint'], node.run_state['endpoint_auth'], node['op5_manage']['cache'])

  # Request current host configuration from cache or server
  Chef::Log.info "Requesting current host configuration from cache or server"
  comp_config = op5manage.get_host_config(new_resource.name)

  # Remove host from the server if not already done.
  unless comp_config.is_a?(FalseClass)
    Chef::Log.info "Removing host #{new_resource.name}"

    result = op5manage.remove_host(new_resource.name)
    if result
      Chef::Log.info "Sucessfully removed host #{new_resource}"
      node.run_state['config_changed'] = true
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.error "Couldn't remove host #{new_resource}"
    end
  else
    Chef::Log.info "#{new_resource.name} already removed - nothing to do."
  end
end



def create_host_config
  host_config = Hash.new

  host_config['action_url']                     = new_resource.action_url                   unless new_resource.action_url.nil?
  host_config['active_checks_enabled']          = new_resource.active_checks_enabled        unless new_resource.active_checks_enabled.nil?
  host_config['address']                        = new_resource.address
  host_config['alias']                          = new_resource.alias_name
  host_config['check_command']                  = new_resource.check_command                unless new_resource.check_command.nil?
  host_config['check_command_args']             = new_resource.check_command_args           unless new_resource.check_command_args.nil?
  host_config['check_freshness']                = new_resource.check_freshness              unless new_resource.check_freshness.nil?
  host_config['check_interval']                 = new_resource.check_interval               unless new_resource.check_interval.nil?
  host_config['check_period']                   = new_resource.check_period                 unless new_resource.check_period.nil?
  host_config['children']                       = new_resource.children.select{|key, flag| flag == true }.keys                unless new_resource.children.nil?
  host_config['contact_groups']                 = new_resource.contact_groups.select{|key, flag| flag == true }.keys          unless new_resource.contact_groups.nil?
  host_config['contacts']                       = new_resource.contacts.select{|key, flag| flag == true }.keys                unless new_resource.contacts.nil?
  host_config['custom_variable']                = new_resource.custom_variable              unless new_resource.custom_variable.nil?
  host_config['display_name']                   = new_resource.display_name                 unless new_resource.display_name.nil?
  host_config['event_handler']                  = new_resource.event_handler                unless new_resource.event_handler.nil?
  host_config['event_handler_args']             = new_resource.event_handler_args           unless new_resource.event_handler_args.nil?
  host_config['event_handler_enabled']          = new_resource.event_handler_enabled        unless new_resource.event_handler_enabled.nil?
  host_config['first_notification_delay']       = new_resource.first_notification_delay     unless new_resource.first_notification_delay.nil?
  host_config['flap_detection_enabled']         = new_resource.flap_detection_enabled       unless new_resource.flap_detection_enabled.nil?
  host_config['flap_detection_options']         = new_resource.flap_detection_options.select{|key, flag| flag == true }.keys  unless new_resource.flap_detection_options.nil?
  host_config['freshness_threshold']            = new_resource.freshness_threshold          unless new_resource.freshness_threshold.nil?
  host_config['high_flap_threshold']            = new_resource.high_flap_threshold          unless new_resource.high_flap_threshold.nil?
  host_config['hostgroups']                     = new_resource.hostgroups.select{|key, flag| flag == true }.keys              unless new_resource.hostgroups.nil?
  host_config['icon_image']                     = new_resource.icon_image                   unless new_resource.icon_image.nil?
  host_config['icon_image_alt']                 = new_resource.icon_image_alt               unless new_resource.icon_image_alt.nil?
  host_config['low_flap_threshold']             = new_resource.low_flap_threshold           unless new_resource.low_flap_threshold.nil?
  host_config['max_check_attempts']             = new_resource.max_check_attempts           unless new_resource.max_check_attempts.nil?
  host_config['host_name']                      = new_resource.name
  host_config['notes']                          = new_resource.notes                        unless new_resource.notes.nil?
  host_config['notes_url']                      = new_resource.notes_url                    unless new_resource.notes_url.nil?
  host_config['notification_interval']          = new_resource.notification_interval        unless new_resource.notification_interval.nil?
  host_config['notification_options']           = new_resource.notification_options.select{|key, flag| flag == true }.keys    unless new_resource.notification_options.nil?
  host_config['notification_period']            = new_resource.notification_period          unless new_resource.notification_period.nil?
  host_config['notifications_enabled']          = new_resource.notifications_enabled        unless new_resource.notifications_enabled.nil?
  host_config['obsess']                         = new_resource.obsess                       unless new_resource.obsess.nil?
  host_config['parents']                        = new_resource.parents.select{|key, flag| flag == true }.keys                 unless new_resource.parents.nil?
  host_config['passive_checks_enabled']         = new_resource.passive_checks_enabled       unless new_resource.passive_checks_enabled.nil?
  host_config['process_perf_data']              = new_resource.process_perf_data            unless new_resource.process_perf_data.nil?
  host_config['register']                       = new_resource.register                     unless new_resource.register.nil?
  host_config['retain_nonstatus_information']   = new_resource.retain_nonstatus_information unless new_resource.retain_nonstatus_information.nil?
  host_config['retain_status_information']      = new_resource.retain_status_information    unless new_resource.retain_status_information.nil?
  host_config['retry_interval']                 = new_resource.retry_interval               unless new_resource.retry_interval.nil?
  host_config['stalking_options']               = new_resource.stalking_options.select{|key, flag| flag == true }.keys        unless new_resource.stalking_options.nil?
  host_config['statusmap_image']                = new_resource.statusmap_image              unless new_resource.statusmap_image.nil?
  host_config['template']                       = new_resource.template
  host_config['2d_coords']                      = new_resource.two_d_coords                 unless new_resource.two_d_coords.nil?

  return host_config
end