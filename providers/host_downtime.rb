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
  host_downtime = create_host_downtime

  op5manage = Op5Manage.new(node['op5_manage']['endpoint'], node.run_state['endpoint_auth'], node['op5_manage']['cache'])


  if Time.new.to_i < host_downtime['end_time']

    # Request host downtimes from cache
    Chef::Log.info "Requesting host downtimes from cache"
    cached_downtime = op5manage.get_host_downtime(new_resource.name)

    if cached_downtime.nil?
      Chef::Log.info "Schedule host downtime #{new_resource.name}"

      #raise RuntimeError, "name: #{new_resource.name}, command: #{new_resource.command.upcase}, host_downtime: #{host_downtime}"
      result = op5manage.schedule_host_downtime(new_resource.name, new_resource.command.upcase, host_downtime)
      if result
        Chef::Log.info "Sucessfully schedule downtime for host #{host_downtime[:host_name]}"
        new_resource.updated_by_last_action(true)
      else
        Chef::Log.error "Couldn't schedule downtime for host #{host_downtime[:host_name]}"
      end
    else
      Chef::Log.info "Host downtime #{new_resource.name} already exists - nothing to do."
    end
  else
    Chef::Log.info "End of host downtime #{new_resource.name} already expired - nothing to do."
  end

end


def create_host_downtime
  host_downtime = Hash.new

  host_downtime['host_name']  = new_resource.host_name                     unless new_resource.host_name.nil?
  host_downtime['start_time'] = Time.parse(new_resource.start_time).to_i   unless new_resource.start_time.nil?
  host_downtime['end_time']   = Time.parse(new_resource.end_time).to_i     unless new_resource.end_time.nil?


  # Flexible downtime
  host_downtime['fixed'] = new_resource.fixed
  host_downtime['duration'] = new_resource.duration
  unless new_resource.fixed
    unless new_resource.duration > 0
      raise RuntimeError, "Duration must be greater zero (0) in flexible downtime."
    end
  end

  host_downtime['trigger_id'] = new_resource.trigger_id

  host_downtime['comment'] = new_resource.comment

  case new_resource.command.upcase
    when 'SCHEDULE_HOST_DOWNTIME'
      true
    when 'SCHEDULE_AND_PROPAGATE_HOST_DOWNTIME'
      true
    when 'SCHEDULE_AND_PROPAGATE_TRIGGERED_HOST_DOWNTIME'
      true
    else
      raise RuntimeError, "Invalid host downtime command #{new_resource.command}\nSupported commands are:\n  SCHEDULE_HOST_DOWNTIME (default)\n  SCHEDULE_AND_PROPAGATE_HOST_DOWNTIME\n  SCHEDULE_AND_PROPAGATE_TRIGGERED_HOST_DOWNTIME"
  end


  return host_downtime
end
