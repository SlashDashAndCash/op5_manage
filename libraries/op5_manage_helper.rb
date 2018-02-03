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



class Op5Manage

  def initialize(endpoint, endpoint_auth, cache_settings)
    @api = Op5Api.new(endpoint, endpoint_auth)
    @cache = Op5Cache.new(endpoint, cache_settings)
  end

  def finish
    @api.finish
  end



  # -------------------------------
  # Commands
  # -------------------------------

  def get_host_downtime(host_downtime_name)
    @cache.get_host_downtime(host_downtime_name)
  end



  def schedule_host_downtime(name, command, host_downtime)
    response = @api.post_schedule_host_downtime(command, host_downtime)

    if response.code.to_i == 200 or response.code.to_i == 201
      @cache.schedule_host_downtime(name, command, host_downtime)
      return true
    else
      raise RuntimeError, "Couldn't schedule host downtime\nCode: #{response.code.to_i}\nBody: #{response.body.to_s}"
    end
  end



  # -------------------------------
  # Manage hosts
  # -------------------------------

  def get_host_config(hostname)
    if @cache.enabled?
      if @cache.host_created?(hostname)
        if @cache.host_config_valid?(hostname)
          # Get host config from cache
          return @cache.get_host_config(hostname)
        end
      elsif @cache.host_removed?(hostname)
        # Host not created. Removed
        return false
      end
    end


    host_config = @api.get_config_host(hostname)


    if host_config.is_a?(Hash) and host_config.has_key?('host_name') and host_config['host_name'] == hostname

      # Move embedded services in host config to services cache
      # Solution for bug ITB-19274 (comparison of Hash with Hash failed)
      if host_config.has_key?('services')
        host_services = host_config['services']
        host_config.delete('services')
      else
        host_services = Array.new
      end

      if @cache.enabled?
        if @cache.host_created?(hostname)
          @cache.update_host_config(host_config)
        else
          @cache.create_host(host_config)
        end

        host_services.each do |service_config|

          service = hostname + ';' + service_config['service_description']
          service_config['host_name'] = hostname

          if @cache.service_in_cache?(service)
            @cache.update_service_config(service_config)
          else
            @cache.create_service(service_config)
          end
        end

      end
    else
      return false
    end

    return host_config
  end



  def create_host(host_config)
    response = @api.post_config_host(host_config)

    if response.code.to_i == 201
      @cache.create_host(host_config)
      return true
    else
      raise RuntimeError, "Couldn't create host\nCode: #{response.code.to_i}\nBody: #{response.body.to_s}"
    end
  end



  def update_host(host_config)
    response = @api.patch_config_host(host_config['host_name'], host_config)

    if response.code.to_i == 200
      @cache.update_host_config(host_config)
      return true
    else
      raise RuntimeError, "Couldn't update host\nCode: #{response.code.to_i}\nBody: #{response.body.to_s}"
    end
  end



  def remove_host(hostname)
    response = @api.delete_config_host(hostname)

    if response.code.to_i == 200
      @cache.remove_host(hostname)
      return true
    else
      raise RuntimeError, "Couldn't remove host\nCode: #{response.code.to_i}\nBody: #{response.body.to_s}"
    end
  end



  # Compares two host objects
  # host_config is a hash you defined
  # comp_config is a hash representing the host on the op5 server
  # If not given, comp_config will be requested from the server.
  #
  def host_config_eql?(host_config, comp_config = nil)
    unless comp_config.class == Hash
      comp_config = get_host_config(host_config['host_name'])

      return false if comp_config.is_a?(FalseClass)
    end

    return false unless comp_config['host_name'] == host_config['host_name']

    # Compare each key step by step
    host_config.each do |key, value|
      if comp_config.has_key?(key)

        # Put arrays in the right order
        if host_config[key].class == Array and comp_config[key].class == Array
          host_config[key] = host_config[key].uniq.sort
          comp_config[key] = comp_config[key].uniq.sort
        end

        # Compare both key values of host object and object of comparison
        if host_config[key].is_a?(Hash)
          # Compare a hash
          host_config[key].each do |hkey, hvalue|
            return false if host_config[key][hkey] != comp_config[key][hkey]
          end
        else
          # Compare any other class
          return false if host_config[key] != comp_config[key]
        end

      else
        # Key doesn't exist in comp_config. Not equal!
        return false
      end
    end

    # host_config and comp_config equal.
    return true
  end



  # -------------------------------
  # Manage services
  # -------------------------------

  def get_service_config(service)
    if @cache.enabled?
      if @cache.service_created?(service)
        if @cache.service_config_valid?(service)
          # Get service config from cache
          return @cache.get_service_config(service)
        end
      elsif @cache.service_removed?(service)
        # Service not created. Removed
        return false
      end
    end


    service_config = @api.get_config_service(service)


    if service_config.is_a?(Hash) and service_config.has_key?('host_name') and service_config.has_key?('service_description')
      if "#{service_config['host_name']};#{service_config['service_description']}" == service
        if @cache.enabled?
          if @cache.service_created?(service)
            @cache.update_service_config(service_config)
          else
            @cache.create_service(service_config)
          end
        end
      else
        return false
      end

      return service_config
    else
      return false
    end
  end



  def create_service(service_config)
    response = @api.post_config_service(service_config)

    if response.code.to_i == 201
      @cache.create_service(service_config)
      return true
    else
      raise RuntimeError, "Couldn't create service\nCode: #{response.code.to_i}\nBody: #{response.body.to_s}"
    end
  end



  def update_service(service_config)
    response = @api.patch_config_service("#{service_config['host_name']};#{service_config['service_description']}", service_config)

    if response.code.to_i == 200
      @cache.update_service_config(service_config)
      return true
    else
      raise RuntimeError, "Couldn't update service\nCode: #{response.code.to_i}\nBody: #{response.body.to_s}"
    end
  end



  def remove_service(service)
    response = @api.delete_config_service(service)

    if response.code.to_i == 200
      @cache.remove_service(service)
      return true
    else
      raise RuntimeError, "Couldn't remove service\nCode: #{response.code.to_i}\nBody: #{response.body.to_s}"
    end
  end



  # Compares two service objects
  # service_config is a hash you defined
  # comp_config is a hash representing the service on the op5 server
  # If not given, comp_config will be requested from the server.
  #
  def service_config_eql?(service_config, comp_config = nil)
    unless comp_config.class == Hash
      comp_config = get_service_config("#{service_config['host_name']};#{service_config['service_description']}")

      return false if comp_config.is_a?(FalseClass)
    end

    return false unless "#{comp_config['host_name']};#{comp_config['service_description']}" == "#{service_config['host_name']};#{service_config['service_description']}"

    # Compare each key step by step
    service_config.each do |key, value|
      if comp_config.has_key?(key)

        # Put arrays in the right order
        if service_config[key].class == Array and comp_config[key].class == Array
          service_config[key] = service_config[key].uniq.sort
          comp_config[key] = comp_config[key].uniq.sort
        end

        # Compare both key values of host object and object of comparison
        if service_config[key].is_a?(Hash)
          # Compare a hash
          service_config[key].each do |hkey, hvalue|
            return false if service_config[key][hkey] != comp_config[key][hkey]
          end
        else
          # Compare any other class
          return false if service_config[key] != comp_config[key]
        end

      else
        # Key doesn't exist in comp_config. Not equal!
        return false
      end
    end

    # service_config and comp_config equal.
    return true
  end



  # -------------------------------
  # Configuration changes
  # -------------------------------

  def config_change(action)

    case action
      when 'save'
        response = @api.post_config_change
      when 'remove'
        response = @api.delete_config_change
      else
        raise "Unknown action #{action}"
    end

    body = response.body.to_s
    if response.code.to_i == 200 or body.include?('nothing to do') or body.include?('Changes reverted')
      return true
    else
      raise RuntimeError, "Couldn't #{action} configuration change\nCode: #{response.code.to_i}\nBody: #{response.body.to_s}"
    end
  end

end
