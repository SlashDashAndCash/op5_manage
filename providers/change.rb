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


action :initiate do
  Chef::Log.info "Initiating configuration change"

  if node['op5_manage']['cache']['enabled'] and ::Dir.exist?(::File.dirname(node['op5_manage']['cache']['path']))

    if ::File.exist?(node['op5_manage']['cache']['path'] + '.rollback')
      Chef::Log.warn "Something went wrong at last configuration change. Rolling back server configuration."

      op5manage = Op5Manage.new(node['op5_manage']['endpoint'], node.run_state['endpoint_auth'], node['op5_manage']['cache'])

      result = op5manage.config_change('remove')
      if result
        Chef::Log.warn "Rolling back cache file."
        FileUtils.mv(node['op5_manage']['cache']['path'] + '.rollback', node['op5_manage']['cache']['path'])
      end
    end

    if ::File.exist?(node['op5_manage']['cache']['path'])
      FileUtils.cp(node['op5_manage']['cache']['path'], node['op5_manage']['cache']['path'] + '.rollback')
    end
  end

  node.run_state['config_changed'] = false
  new_resource.updated_by_last_action(true)
end


action :save do
  if node.run_state['config_changed'] == true
    Chef::Log.info "Saving configuration change"

    op5manage = Op5Manage.new(node['op5_manage']['endpoint'], node.run_state['endpoint_auth'], node['op5_manage']['cache'])

    result = op5manage.config_change('save')
    if result
      Chef::Log.info "Sucessfully saved configuration changes"

      # Workaround to avoid performance issues
      if node['op5_manage']['endpoint'].attribute?('change_delay')
        change_delay = node['op5_manage']['endpoint']['change_delay']
      else
        change_delay = 0
      end
      Chef::Log.info "Wait #{change_delay} seconds after config change"
      sleep(change_delay)

      new_resource.updated_by_last_action(true)
    else
      Chef::Log.error "Couldn't save configuration changes"
      return false
    end

  else
    Chef::Log.info "Config unchanged. Nothing to do."
  end

  if node['op5_manage']['cache']['enabled'] and ::Dir.exist?(::File.dirname(node['op5_manage']['cache']['path']))
    if ::File.exist?(node['op5_manage']['cache']['path'] + '.rollback')
      Chef::Log.info "Deleting backup cache file."
      FileUtils.rm_f(node['op5_manage']['cache']['path'] + '.rollback')
    end
  end
end


action :remove do
  Chef::Log.info "Removing configuration change"

  op5manage = Op5Manage.new(node['op5_manage']['endpoint'], node.run_state['endpoint_auth'], node['op5_manage']['cache'])

  result = op5manage.config_change('remove')
  if result
    Chef::Log.info "Sucessfully removed configuration changes"

    if node['op5_manage']['cache']['enabled'] and ::Dir.exist?(::File.dirname(node['op5_manage']['cache']['path']))
      if ::File.exist?(node['op5_manage']['cache']['path'] + '.rollback')
        Chef::Log.info "Rolling back cache file"
        FileUtils.mv(node['op5_manage']['cache']['path'] + '.rollback', node['op5_manage']['cache']['path'])
      end
    end

    new_resource.updated_by_last_action(true)
  else
    Chef::Log.error "Couldn't remove configuration changes"
  end
end
