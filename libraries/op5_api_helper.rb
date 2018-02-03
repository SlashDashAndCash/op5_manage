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



class Op5Api

  FORMAT = 'format=json'
  CONTENTTYPE = 'application/json'
  # Encode all these characters in the URI. Mind the space
  ENCODE = '[]{}=!# '

  def initialize(endpoint, endpoint_auth)

    # API endpoint information
    # URL, credentials, proxy
    @endpoint = endpoint.to_hash
    @endpoint_auth = endpoint_auth.to_hash


    uri = URI.parse(@endpoint['url'])

    @endpoint['proxy_addr']  = :ENV unless @endpoint.has_key?('proxy_addr')
    @endpoint['proxy_port']  = nil unless @endpoint.has_key?('proxy_port')
    @endpoint['proxy_user']  = nil unless @endpoint.has_key?('proxy_user')
    @endpoint['proxy_pass']  = nil unless @endpoint.has_key?('proxy_pass')

    @http = Net::HTTP.new(
        uri.host,
        uri.port,
        @endpoint['proxy_addr'],
        @endpoint['proxy_port'],
        @endpoint['proxy_user'],
        @endpoint['proxy_pass']
    )

    @http.use_ssl = true
    if endpoint.has_key?('tls_verify') and endpoint['tls_verify'] == false
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    else
      @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end
  end



  # Look for host keys prepended with an underscore (_)
  # Replace them with a new hash called custom_variable
  # https://demo.op5.com/api/help/config/host#trouble_custom_variables
  #
  def read_custom_variable(obj)
    unless obj.has_key?('custom_variable')
      obj['custom_variable'] = Hash.new
    end

    obj.each do |key, value|
      if key.start_with?('_')
        obj['custom_variable'][key] = value
        obj.delete(key)
      end
    end

    return obj
  end



  # Resolve the hash custom_variable to single host keys
  # prepended with an underscore (_)
  # Empty custom variables will be removed
  # https://demo.op5.com/api/help/config/host#trouble_custom_variables
  #
  def write_custom_variable(obj)
    if obj.has_key?('custom_variable')
      obj['custom_variable'].each do |key, value|
        if key.start_with?('_')
          obj[key] = value
        end
      end
      obj.delete('custom_variable')
    end

    return obj
  end



  # Returns the integer count of matching objects
  # By default the count of total hosts will be returned
  # https://demo.op5.com/api/help/filter/count
  #
  def get_filter_count(query = nil)
    query = '[hosts] all' unless query
    query = URI.encode(query, ENCODE)

    #request_uri = URI.parse("#{@endpoint['url']}/filter/count?#{FORMAT}&query=#{query}")
    #buffer = open(request_uri, :http_basic_authentication => [@endpoint_auth['user'], @endpoint_auth['password']]).read

    uri = URI.parse("#{@endpoint['url']}/filter/count?#{FORMAT}&query=#{query}")
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(@endpoint_auth['user'], @endpoint_auth['password'])
    response = @http.request(request)

    content = JSON.parse(response.body)
    content['count'].to_i
  end



  # Returns the matching objects of the query string
  # By default all host information will be returned
  # https://demo.op5.com/api/help/filter/query
  #
  def get_filter_query(query = '[hosts] all', columns = nil, limit = nil, offset = nil, sort = nil)
    query   = "&query=#{URI.encode(query, ENCODE)}" if query
    columns = "&columns=#{URI.encode(columns, ENCODE)}" if columns
    limit   = "&limit=#{limit.to_i}" if limit
    offset  = "&offset=#{offset.to_i}" if offset
    sort    = "&sort=#{URI.encode(sort, ENCODE)}" if sort

    # For debugging
    #return "#{@endpoint['url']}/filter/query?#{FORMAT}#{query}#{columns}#{limit}#{offset}#{sort}"

    uri = URI.parse("#{@endpoint['url']}/filter/query?#{FORMAT}#{query}#{columns}#{limit}#{offset}#{sort}")
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(@endpoint_auth['user'], @endpoint_auth['password'])
    response = @http.request(request)

    content = JSON.parse(response.body)
  end



  # Schedules downtime for a host
  # https://demo.op5.com/api/help/command/SCHEDULE_HOST_DOWNTIME
  #
  def post_schedule_host_downtime(command, host_downtime)
    ['host_name', 'start_time', 'end_time', 'fixed', 'trigger_id', 'duration', 'comment'].each do |key|
      return false unless host_downtime.has_key?(key)
    end

    uri = URI.parse("#{@endpoint['url']}/command/#{command}")
    request = Net::HTTP::Post.new(uri.path)
    request.basic_auth(@endpoint_auth['user'], @endpoint_auth['password'])
    request['content-type'] = CONTENTTYPE
    request.body = host_downtime.to_json
    response = @http.request(request)
  end



  # Returns the entire configuration of a host object
  # https://demo.op5.com/api/help/config/host
  #
  def get_config_host(hostname = nil)
    hostname_enc = URI.encode(hostname, ENCODE) if hostname

    uri = URI.parse("#{@endpoint['url']}/config/host/#{hostname_enc}?#{FORMAT}")
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(@endpoint_auth['user'], @endpoint_auth['password'])
    response = @http.request(request)

    content = JSON.parse(response.body)

    if content.is_a?(Hash) and content.has_key?('host_name') and content['host_name'] == hostname
      # Handle custom variables
      content = read_custom_variable(content)
      return content
    end
  end



  # Creates a new host
  # host_obj is a hash of properties. See documentation page
  # The properties host_name, alias, address and template are mandatory
  #
  # Please note you have to call 'post_config_change'
  # to save your configuration.
  #
  # https://demo.op5.com/api/help/config/host
  #
  def post_config_host(host_obj)
    ['host_name', 'alias', 'address', 'template'].each do |key|
      return false unless host_obj.has_key?(key)
    end

    # Handle custom variables
    new_host_obj = write_custom_variable(host_obj.dup)

    uri = URI.parse("#{@endpoint['url']}/config/host")
    request = Net::HTTP::Post.new(uri.path)
    request.basic_auth(@endpoint_auth['user'], @endpoint_auth['password'])
    request['content-type'] = CONTENTTYPE
    request.body = new_host_obj.to_json
    response = @http.request(request)
  end



  # Changes the properties of an existing host
  # host_obj is a hash of properties. See documentation page
  #
  # Please note you have to call 'post_config_change'
  # to save your configuration.
  #
  # https://demo.op5.com/api/help/config/host
  #
  def patch_config_host(hostname, host_obj)
    # Handle custom variables
    new_host_obj = write_custom_variable(host_obj.dup)

    uri = URI.parse("#{@endpoint['url']}/config/host/#{hostname}")
    request = Net::HTTP::Patch.new(uri.path)
    request.basic_auth(@endpoint_auth['user'], @endpoint_auth['password'])
    request['content-type'] = CONTENTTYPE
    request.body = new_host_obj.to_json
    response = @http.request(request)
  end



  # Deletes an existing host
  #
  # Please note you have to call 'post_config_change'
  # to save your configuration.
  #
  # https://demo.op5.com/api/help/config/host
  #
  def delete_config_host(hostname)
    uri = URI.parse("#{@endpoint['url']}/config/host/#{hostname}")
    request = Net::HTTP::Delete.new(uri.path)
    request.basic_auth(@endpoint_auth['user'], @endpoint_auth['password'])
    response = @http.request(request)
  end



  # Returns the entire configuration of a service object
  # https://demo.op5.com/api/help/config/service
  #
  def get_config_service(service = nil)
    service_enc = URI.encode(service, ENCODE) if service

    uri = URI.parse("#{@endpoint['url']}/config/service/#{service_enc}?#{FORMAT}")
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(@endpoint_auth['user'], @endpoint_auth['password'])
    response = @http.request(request)

    content = JSON.parse(response.body)
  end



  # Creates a new Service
  # service_config is a hash of properties. See documentation page
  #
  # Please note you have to call 'post_config_change'
  # to save your configuration.
  #
  # https://demo.op5.com/api/help/config/service
  #
  def post_config_service(service_config)
    uri = URI.parse("#{@endpoint['url']}/config/service")
    request = Net::HTTP::Post.new(uri.path)
    request.basic_auth(@endpoint_auth['user'], @endpoint_auth['password'])
    request['content-type'] = CONTENTTYPE
    request.body = service_config.to_json
    response = @http.request(request)
  end



  # Changes the properties of an existing service
  # service_obj is a hash of properties. See documentation page
  #
  # Please note you have to call 'post_config_change'
  # to save your configuration.
  #
  # https://demo.op5.com/api/help/config/service
  #
  def patch_config_service(service, service_obj)
    service_enc = URI.encode(service, ENCODE) if service
    uri = URI.parse("#{@endpoint['url']}/config/service/#{service_enc}")
    request = Net::HTTP::Patch.new(uri.path)
    request.basic_auth(@endpoint_auth['user'], @endpoint_auth['password'])
    request['content-type'] = CONTENTTYPE
    request.body = service_obj.to_json
    response = @http.request(request)
  end



  # Deletes an existing service
  #
  # Please note you have to call 'post_config_change'
  # to save your configuration.
  #
  # https://demo.op5.com/api/help/config/service
  #
  def delete_config_service(service)
    service_enc = URI.encode(service, ENCODE) if service
    uri = URI.parse("#{@endpoint['url']}/config/service/#{service_enc}")
    request = Net::HTTP::Delete.new(uri.path)
    request.basic_auth(@endpoint_auth['user'], @endpoint_auth['password'])
    response = @http.request(request)
  end



  # Returns the unsaved configuration changes
  # https://demo.op5.com/api/help/config#persistent_changes
  #
  def get_config_change
    uri = URI.parse("#{@endpoint['url']}/config/change?#{FORMAT}")
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(@endpoint_auth['user'], @endpoint_auth['password'])
    response = @http.request(request)

    content = JSON.parse(response.body)
  end



  # Undoes all pending changes. No configuration file will be written
  # https://demo.op5.com/api/help/config#persistent_changes
  #
  def delete_config_change
    uri = URI.parse("#{@endpoint['url']}/config/change")
    request = Net::HTTP::Delete.new(uri.request_uri)
    request.basic_auth(@endpoint_auth['user'], @endpoint_auth['password'])
    response = @http.request(request)
  end



  # Saves all pending changes to configuration
  # https://demo.op5.com/api/help/config#persistent_changes
  #
  def post_config_change
    uri = URI.parse("#{@endpoint['url']}/config/change")
    request = Net::HTTP::Post.new(uri.path)
    request.basic_auth(@endpoint_auth['user'], @endpoint_auth['password'])
    response = @http.request(request)
  end

end
