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



class Op5Cache

  def initialize(endpoint, cache_settings)
    @endpoint = endpoint

    # Caching settings
    @settings = cache_settings.dup

    @settings['enabled']       = false unless @settings.has_key?('enabled')
    @settings['path']    = '.' unless @settings.has_key?('path')
    @settings['max_age']  = 43200 unless @settings.has_key?('max_age')

    now = Time.now.getutc
    @cache = {
        'endpoint_url'    => @endpoint['url'],
        'hosts'           => Array.new,
        'services'        => Array.new,
        'host_downtimes'  => Array.new
    }

    readfile
  end



  def enabled?
    if @settings['enabled'] == true
      true
    else
      false
    end
  end



  def filename
    uri = URI(@endpoint['url'])
    file_name = 'host_cache_' + uri.host + '.json'
  end



  def readfile
    unless @settings['enabled']
      nil
    else
      directory    = File.dirname(@settings['path'])
      filename = @settings['path']
      if Dir.exists?(directory) and File.exist?(filename)
        load = File.read(filename)

        content = JSON.parse(load)

        # Remove cache if endpoint has been changed
        unless @endpoint['url'] == content['endpoint_url']
          File.delete(filename)
        else
          @cache.merge!(content)

          # Remove expired downtimes from cache
          clean_host_downtime

          true
        end
      end
    end
  end



  def writefile
    unless @settings['enabled']
      nil
    else
      directory    = File.dirname(@settings['path'])
      filename     = @settings['path']
      file_content = JSON.pretty_generate(@cache)

      unless Dir.exist?(directory)
        FileUtils.mkdir_p directory
      end

      begin
        file = File.new(filename, 'w')
        file.write(file_content)
      rescue IOError => e
        #some error occur, dir not writable etc.
      ensure
        file.close unless file.nil?
        true
      end
    end
  end



  # -------------------------------
  # Host downtime cache
  # -------------------------------

  def clean_host_downtime
    now = Time.now.to_i

    cleanup = Array.new

    @cache['host_downtimes'].each_with_index do |h, i|
      end_time = h['downtime']['end_time']

      if end_time < now
        cleanup << i
      end
    end

    cleanup.each do |i|
      @cache['host_downtimes'].delete_at(i)
    end
  end



  def get_host_downtime(name)
    downtime_index = @cache['host_downtimes'].index {|h| h['name'] == name }

    if downtime_index.nil?
      nil
    else
      @cache['host_downtimes'][downtime_index]
    end
  end


  def schedule_host_downtime(name, command, host_downtime)
    unless @settings['enabled']
      nil
    else
      now = Time.now.getutc

      downtime = {
          'name'          => name,
          'endpoint_url'  => @endpoint['url'],
          'timestamp'     => now,
          'created'       => now,
          'command'       => command,
          'downtime'      => host_downtime
      }

      downtime_index = @cache['host_downtimes'].index {|h| h['name'] == name }
      if downtime_index.nil?
        @cache['host_downtimes'] << downtime
      else
        @cache['host_downtimes'][downtime_index] = downtime
      end
      writefile
    end
  end



  # -------------------------------
  # Host cache
  # -------------------------------

  def host_in_cache?(hostname)
    hosts = @cache['hosts'].select {|h| h['host_name'] == hostname}

    if hosts.length == 1
      true
    else
      false
    end
  end



  def get_host(hostname)
    unless @settings['enabled']
      nil
    else
      now = Time.now.getutc

      hosts = @cache['hosts'].select {|h| h['host_name'] == hostname}

      if hosts.length == 1
        host = hosts[0]

        if host.is_a?(Hash)
          return host
        end
      end
      # No host, more than one host, host is not a Hash, timestamp to old
      false
    end
  end



  def host_created?(hostname)
    host = get_host(hostname)

    if host.is_a?(Hash) and host['created'] != false
      true
    else
      false
    end
  end



  def host_removed?(hostname)
    host = get_host(hostname)

    if host.is_a?(Hash) and host['created'] == false
      true
    else
      false
    end
  end



  def host_config_valid?(hostname)
    now = Time.now.getutc
    host = get_host(hostname)

    (now - Time.parse(host['config_age'])).to_i <= @settings['max_age']
  end



  def get_host_config(hostname)
    host = get_host(hostname)

    if host.is_a?(Hash)
      return host['config']
    else
      return host
    end
  end



  def create_host(host_config)
    unless @settings['enabled']
      nil
    else
      now = Time.now.getutc

      host = {
          'host_name'     => host_config['host_name'],
          'endpoint_url'  => @endpoint['url'],
          'timestamp'     => now,
          'created'       => now,
          'config_age'    => now,
          'config'        => host_config
      }

      host_index = @cache['hosts'].index {|h| h['host_name'] == host_config['host_name'] }
      if host_index.nil?
        @cache['hosts'] << host
      else
        @cache['hosts'][host_index] = host
      end
      writefile
    end
  end



  def update_host_config(host_config)
    unless @settings['enabled']
      nil
    else
      now = Time.now.getutc
      config_changed = false

      host_index = @cache['hosts'].index {|h| h['host_name'] == host_config['host_name'] }

      # Compare each key step by step
      host_config.each do |key, value|
        if @cache['hosts'][host_index]['config'].has_key?(key)

          # Put arrays in the right order
          if host_config[key].class == Array and @cache['hosts'][host_index]['config'][key].class == Array
            host_config[key] = host_config[key].uniq.sort
            @cache['hosts'][host_index]['config'][key] = @cache['hosts'][host_index]['config'][key].uniq.sort
          end

          # Compare both key values of host object and object of comparison
          unless host_config[key] == @cache['hosts'][host_index]['config'][key]
            # Values not equal!
            @cache['hosts'][host_index]['config'][key] = host_config[key]
          end
        else
          # Key doesn't exist in cache
          @cache['hosts'][host_index]['config'][key] = host_config[key]
        end
      end

      @cache['hosts'][host_index]['config_age'] = now
      @cache['hosts'][host_index]['timestamp'] = now
      writefile
    end
  end



  def remove_host(hostname)
    unless @settings['enabled']
      nil
    else
      now = Time.now.getutc

      host_index = @cache['hosts'].index {|h| h['host_name'] == hostname }

      @cache['hosts'][host_index]['timestamp'] = now
      @cache['hosts'][host_index]['created'] = false


      # Remove depending services
      @cache['services'].each do | cached_service |
        service = cached_service['service']
        service_of_host = service.split(';')

        if service_of_host = hostname
          remove_service(service)
        end
      end

      writefile
    end
  end



  # -------------------------------
  # Service cache
  # -------------------------------

  def service_in_cache?(service)
    services = @cache['services'].select {|h| h['service'] == service}

    if services.length == 1
      true
    else
      false
    end
  end



  def get_service(service)
    unless @settings['enabled']
      nil
    else
      now = Time.now.getutc

      services = @cache['services'].select {|h| h['service'] == service}

      if services.length == 1
        service_obj = services[0]

        if service_obj.is_a?(Hash)
          return service_obj
        end
      end
      # No service, more than one service, service is not a Hash, timestamp to old
      false
    end
  end



  def service_created?(service)
    service_obj = get_service(service)

    if service_obj.is_a?(Hash) and service_obj['created'] != false
      true
    else
      false
    end
  end



  def service_removed?(service)
    service_obj = get_service(service)

    if service_obj.is_a?(Hash) and service_obj['created'] == false
      true
    else
      false
    end
  end



  def service_config_valid?(service)
    now = Time.now.getutc
    service_obj = get_service(service)

    (now - Time.parse(service_obj['config_age'])).to_i <= @settings['max_age']
  end



  def get_service_config(service)
    service_obj = get_service(service)

    if service_obj.is_a?(Hash)
      return service_obj['config']
    else
      return service_obj
    end
  end



  def create_service(service_config)
    unless @settings['enabled']
      nil
    else
      now = Time.now.getutc

      service_obj = {
          'service'     => "#{service_config['host_name']};#{service_config['service_description']}",
          'endpoint_url'  => @endpoint['url'],
          'timestamp'     => now,
          'created'       => now,
          'config_age'    => now,
          'config'        => service_config
      }

      service_index = @cache['services'].index {|h| h['service'] == "#{service_config['host_name']};#{service_config['service_description']}" }
      if service_index.nil?
        @cache['services'] << service_obj
      else
        @cache['services'][service_index] = service_obj
      end
      writefile
    end
  end



  def update_service_config(service_config)
    unless @settings['enabled']
      nil
    else
      now = Time.now.getutc
      config_changed = false

      service_index = @cache['services'].index {|h| h['service'] == "#{service_config['host_name']};#{service_config['service_description']}" }

      # Compare each key step by step
      service_config.each do |key, value|
        if @cache['services'][service_index]['config'].has_key?(key)

          # Put arrays in the right order
          if service_config[key].class == Array and @cache['services'][service_index]['config'][key].class == Array
            service_config[key] = service_config[key].uniq.sort
            @cache['services'][service_index]['config'][key] = @cache['services'][service_index]['config'][key].uniq.sort
          end

          # Compare both key values of service object and object of comparison
          unless service_config[key] == @cache['services'][service_index]['config'][key]
            # Values not equal!
            @cache['services'][service_index]['config'][key] = service_config[key]
          end
        else
          # Key doesn't exist in cache
          @cache['services'][service_index]['config'][key] = service_config[key]
        end
      end

      @cache['services'][service_index]['config_age'] = now
      @cache['services'][service_index]['timestamp'] = now
      writefile
    end
  end



  def remove_service(service)
    unless @settings['enabled']
      nil
    else
      now = Time.now.getutc

      service_index = @cache['services'].index {|h| h['service'] == service }

      @cache['services'][service_index]['timestamp'] = now
      @cache['services'][service_index]['created'] = false

      writefile
    end
  end

end
