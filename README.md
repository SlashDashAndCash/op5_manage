# op5_manage

- Create, modify or remove hosts and services.
- Schedule downtimes for host objects.
- Sophisticated caching to perform as less Api requests as possible.
- Chef Vault support for securing op5 credentials.

All operations are performed using the [restful op5 Api](https://www.op5.com/explore-op5-monitor/features/op5-monitor-api/)

## Supported Platforms

- CentOS 6, 7
- Red Hat Enterprise Linux 6, 7
- SuSE Linux Enterprise Server 11, 12

Other versions and platforms should work as well but are untested.

## Usage

### Adding a host in fife minutes example

The easiest way to create a host with Chef is to use the op5_manage_host resource in your own cookbook.

1. Install [ChefDK](https://downloads.chef.io/chefdk) on a Unix like machine with network access to your op5 server.
2. Issue the commands below to build a new environment for Chef Solo with a sample cookbook "monitor".

```
mkdir -p /tmp/test_op5/cookbooks
cd /tmp/test_op5
echo "cookbook_path File.expand_path('/tmp/test_op5/cookbooks', __FILE__)" > ./solo.rb
cd cookbooks
chef generate cookbook monitor
echo -e "\ndepends 'op5_manage'\n" >> ./monitor/metadata.rb
echo -e "source 'https://supermarket.chef.io'\n\nmetadata" > ./monitor/Berksfile
cd ./monitor
berks vendor ../


vim ./recipes/default.rb
```

3. Overwrite ./recipes/default.rb with the recipe below and customize url, username and password.

```ruby
# Endpoint configuration

node.default['op5_manage']['endpoint'].merge! (
  {
    'url'          => 'https://192.168.211.10/api',
    'tls_verify'   => false,
    'vault_name'   => nil
  }
)

node.run_state['endpoint_auth'] = {
    'user'        => 'administrator',
    'password'    => 'Adm!nPa$$w0rd'
}

node.default['op5_manage']['cache']['path'] = '/tmp/test_op5/cache.json'



# Monitoring

op5_manage_change 'config' do action :initiate end

op5_manage_host 'webserver.local' do
  alias_name       'webserver'
  address          '10.23.42.20'
  template         'default-host-template'
  hostgroups       { 'Linux servers' => true, 'Web servers https' => true }
  action           :create
end

op5_manage_service 'webserver.local;MySQL port' do
  check_command       'check_tcp'
  check_command_args  '3306'
  template            'default-service'
end

op5_manage_change 'config' do action :save end


ruby_block 'wait for host' do
  block do
    sleep(15)
  end
end

op5_manage_host_downtime 'maintenance_webserver' do
  command      "SCHEDULE_HOST_DOWNTIME"
  host_name    "webserver.local"
  start_time   "2018-01-28 09:00:00"
  end_time     "2018-01-28 11:00:00"
  comment      "webserver upgrade"
end
```

4. Thats it. Now execute Chef Solo.

`chef-solo -c ../../solo.rb -o 'recipe[monitor]'`


### Configuration

#### op5 endpoints

An endpoint is all the needed information to connect to an op5 Api server. All of them are configured by attributes in the
 default.rb attribute file. In addition sensitive credentials like username and password may stored in a Chef Vault.

#### Creating an endpoint vault

On your Chef build environment write your credentials in a JSON file (e.g. `~/op5_endpoints.json`).

```json
{
  "op5_manage": {
    "endpoints": {
      "https://server.domain.tld/api": {
        "user": "Username",
        "password": "Pa$$w0rd"
      },
      "https://other.endpoint.local/api": {
          "user": "Username$LDAP",
          "password": "Pa$$w0rd"
      }
    }
  }
}
```

Create the vault and import the data from file. The vault is named "op5_manage" and the item containing the credentials
is named "endpoints".

```
knife vault create op5_manage endpoints \
-A user1,user2 -S 'run_list:recipe\[op5_manage\] OR run_list:recipe\[op5_manage\:\:*\]' \
-M client -J ~/op5_endpoints.json
```

Changing the content of a vault item is easy.

```
knife vault edit op5_manage endpoints
```

Configure attributes to use your vault instead of username and password. See attributes file default.rb for more
 information.


#### Configure the endpoint

It's good practice to configure the endpoint url in your environments.

```json
{
  "name": "prod",
  "description": "Production Environment",
  "cookbook_versions": {
  },
  "json_class": "Chef::Environment",
  "chef_type": "environment",
  "default_attributes": {
    "op5_manage": {
      "endpoint": {
        "url": "https://server.domain.tld/api"
      }
    }
  },
  "override_attributes": {
  }
}
```

This will point to the corresponding endpoint credentials in your vault item.


### Order of run list

- The op5_manage cookbook should be the last in run list.
- host recipe must be executed before service recipe.
- host recipe must be executed before host_downtime recipe and configuration must be saved.

### Add a Chef node to op5 monitoring

The node recipe is used to manage a node itself in op5. This is the common use case so you just have to add the default
 recipe into your run list. Without any configuration, a host is created in op5 with a host group depending on your os.

```json
{
  "run_list": [
    "recipe[op5_manage]"
  ]
}
```

Use attributes to modify host parameters. Either in a recipe or in a role or environment (with JSON).

```ruby
node.default['op5_manage']['node'].merge! (
  {
    'hostgroups'              => { 'Web servers https' => true },
    'custom_variable'         => {
      '_API_PING_TXT'         => 'OK',
      '_API_PING_URL'         => '/artifactory/api/system/ping'
    },
    'services' => {
      'HTTPS URL API Ping'    => {
        'template'            => 'default-service',
        'check_command'       => 'check_https_url_string',
        'check_command_args'  => '"$_API_PING_URL$"!"$_API_PING_TXT$"',
        'notes_url'           => 'https://intranet.mydomain.tld/Monitoring#Checks-HTTPSURL',
        'action_url'          => 'https://$HOSTADDRESS$$_API_PING_URL$'
      }
    }
  }
)

include_recipe 'op5_manage'
```

```json
{
  "op5_manage": {
    "node": {
      "hostgroups":             { "Web servers https": true },
      "custom_variable": {
        "_API_PING_TXT":        "OK",
        "_API_PING_URL":        "/artifactory/api/system/ping"
      },
      "services": {
        "HTTPS URL API Ping": {
          "template":           "default-service",
          "check_command":      "check_https_url_string",
          "check_command_args": "\"$_API_PING_URL$\"!\"$_API_PING_TXT$\"",
          "notes_url":          "https://intranet.mydomain.tld/Monitoring#Checks-HTTPS",
          "action_url":         "https://$HOSTADDRESS$$_API_PING_URL$"
        }
      }
    }
  }
}
```

#### Host groups

Typical host groups include

- unix-servers
- Windows servers
- Generic hosts

All hostgroups are listed here:

https://demo.op5.com/monitor/index.php/listview/?q=%5Bhostgroups%5D%20all


### Manage other hosts from a Chef node

The host recipe is used to manage hosts which are unable to run Chef client, like routers or printers. 

```json
{
  "run_list": [
    "recipe[op5_manage::host]"
  ]
}
```

Use attributes to `:create` or `:remove` hosts. Either in a recipe or in a role (with JSON).

```ruby
node.default['op5_manage']['hosts'].merge! (
  {
    'op5cheftest-02.mydomain.tld' => {
      'alias_name'    => 'op5cheftest-02',
      'address'       => '192.168.211.27',
      'template'      => 'default-host-template',
      'hostgroups'    => { 'Generic hosts' => false, 'Linux servers' => true, 'Web servers https' => true },
      'check_period'  => 'workhours',
      'retain_info'   => true
    },
    'op5cheftest-03.mydomain.tld' => {
      'alias_name'    => 'op5cheftest-03',
      'address'       => '192.168.211.21',
      'template'      => 'default-host-template',
      'hostgroups'    => { 'Generic hosts' => true, 'Linux servers' => true },
      'action'        => 'remove'
    }
  }
)

include_recipe 'op5_manage::host'
```

```json
{
  "op5_manage": {
    "hosts": {
      "op5cheftest-02.mydomain.tld": {
        "alias_name":   "op5cheftest-02",
        "address":      "192.168.211.27",
        "template":     "default-host-template",
        "hostgroups":   { "Generic hosts": false, "Linux servers": true, "Web servers https": false },
        "check_period": "workhours",
        "retain_info":  true
      },
      "op5cheftest-03.mydomain.tld": {
        "alias_name":   "op5cheftest-03",
        "address":      "192.168.211.21",
        "template":     "default-host-template",
        "hostgroups":   { "Generic hosts": true, "Linux servers": true },
        "action":       "remove"
      }
    }
  }
}
```


### Manage services of other hosts from a Chef node

The service recipe is used to manage services on hosts which are unable to run Chef client, like routers or printers. 

```json
{
  "run_list": [
    "recipe[op5_manage::service]"
  ]
}
```

Use attributes to `:create` or `:remove` services. Either in a recipe or in a role (with JSON).

```ruby
node.default['op5_manage']['services'].merge! (
  {
    'op5cheftest-02.mydomain.tld;Test service 04' => {
      'check_command'  => 'check_ssh_5',
      'template'       => 'default-service',
      'display_name'   => 'Interval 15m - Notify 15m+2m'
    },
    'op5cheftest-02.mydomain.tld;Test service 05' => {
      'check_command'  => 'check_ssh_5',
      'action'         => 'remove'
    }
  }
)

include_recipe 'op5_manage::service'
```

```json
{
  "op5_manage": {
    "services": {
      "op5cheftest-02.mydomain.tld;Test service 04": {
        "check_command":  "check_ssh_5",
        "template":       "default-service",
        "display_name":   "Interval 15m - Notify 15m+2m"
      },
      "op5cheftest-02.mydomain.tld;Test service 05": {
        "check_command":  "check_ssh_5",
        "action":         "remove"
      }
    }
  }
}
```


### Schedule host downtimes

The host_downtime recipe schedules various kinds of host downtimes. Please refer to op5 Api documentation for details.

- https://demo.op5.com/api/help/command/SCHEDULE_HOST_DOWNTIME
- https://demo.op5.com/api/help/command/SCHEDULE_AND_PROPAGATE_HOST_DOWNTIME
- https://demo.op5.com/api/help/command/SCHEDULE_AND_PROPAGATE_TRIGGERED_HOST_DOWNTIME

```json
{
  "run_list": [
    "recipe[op5_manage::host_downtime]"
  ]
}
```

Downtimes are defined by attributes.

```ruby
node.default['op5_manage']['host_downtimes'].merge! (
  {
    'maintenance_op5cheftest-02.mydomain.tld' => {
      'command'     => 'SCHEDULE_HOST_DOWNTIME',
      'host_name'   => 'op5cheftest-02.mydomain.tld',
      'start_time'  => '31.01.2018 23:00',
      'end_time'    => '2018-01-31 23:10',
      'fixed'       => true,
      'duration'    => 0,
      'trigger_id'  => 0,
      'comment'     => 'Maintenance downtime for op5cheftest-02.mydomain.tld'
    }
  }
)

include_recipe 'op5_manage::host_downtime'
```

```json
{
  "op5_manage": {
    "host_downtimes": {
      "maintenance_op5cheftest-01.mydomain.tld": {
        "command":      "SCHEDULE_HOST_DOWNTIME",
        "host_name":    "artiprod-21.mydomain.tld",
        "start_time":   "31.01.2018 23:00",
        "end_time":     "2018-01-31 23:10",
        "fixed":        true,
        "duration":     5,
        "trigger_id":   0,
        "comment":      "Maintenance downtime for op5cheftest-01.mydomain.tld"
      }
    }
  }
}
```

#### Initial downtimes

Initial downtime is part of the node recipe and can be used to schedule a host downtime for newly provisioned servers.
 To prevent it from scheduling downtimes for already existing servers, you can run this knife command to set the attribute.

```
knife exec -E "nodes.transform('name:dbsvrpip01-04.mydomain.tld') {|n| n.normal_attrs['op5_manage']['node']['initial_downtime']['scheduled']=true  rescue nil }"
knife exec -E "nodes.transform('name:dbsvrpip01-04.mydomain.tld') {|n| n.normal_attrs['op5_manage']['node'].delete('initial_downtime') rescue nil }"

knife exec -E "nodes.transform(:all) {|n| n.normal_attrs['op5_manage']['node']['initial_downtime']['scheduled']=true  rescue nil }"
```


## Troubleshoting

- I recommend to use [chef_hostname](https://supermarket.chef.io/cookbooks/chef_hostname) in your run list to
 avoid inconsistent state of hostname and node['fqdn'] after provisioning.
- If you want do remove a host, you must also remove all depending services. 
- There is an open bug on caching host_downtimes. To work around you should never change the properties of
 an existing downtime but create a new one.
- Time and time zone must be the same on Chef node and op5 server in order to schedule downtimes.
- Some times a downtime right after creating the host is not visible in op5 cluster. The only workaround I know is to
 `sleep(30)` between host and downtime resource.
- Be very careful with names. In fact names of hosts, services and downtimes should avoid any special character
 expect space, dash and underscore.
- If you are looking for an issue it's a good advice to delete the cache file (/var/lib/op5_manage/cache.json)
 or temporary disable caching (`node['op5_manage']['cache']['enabled'] = false`)


## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['endpoint']['url']</tt></td>
    <td>String</td>
    <td>URL of the op5 server</td>
    <td><tt>https://demo.op5.com/api</tt></td>
  </tr>
  <tr>
    <td><tt>['endpoint']['vault_name']</tt></td>
    <td>Symbol</td>
    <td>Use Chef Vault to overwrite user and password.<br/>Set to vault name or nil to not use vaults.</td>
    <td><tt>:op5_manage</tt></td>
  </tr>
  <tr>
    <td><tt>['endpoint']['vault_item']</tt></td>
    <td>String</td>
    <td>The item within the vault containing the endpoint credentials.</td>
    <td><tt>endpoints</tt></td>
  </tr>
  <tr>
    <td><tt>['endpoint']['tls_verify']</tt></td>
    <td>Bool</td>
    <td>If tls_verify is given and set to false, TLS server certificate validation is disabled. Use with caution!</td>
    <td><tt>true</tt></td>
  </tr>
  <tr>
    <td><tt>['endpoint']['proxy_addr']</tt></td>
    <td>String, Nil</td>
    <td>If not given, the ENVVAR http_proxy will be used.<br/>Set to nil (no proxy) or to valid FQDN to overwrite.</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>['endpoint']['proxy_port']</tt></td>
    <td>Integer, Nil</td>
    <td>Proxy port number. Only used if proxy_addr is given.</td>
    <td>Not given</td>
  </tr>
  <tr>
    <td><tt>['endpoint']['proxy_user']</tt></td>
    <td>String, Nil</td>
    <td>Proxy authentication</td>
    <td>Not given</td>
  </tr>
  <tr>
    <td><tt>['endpoint']['proxy_pass']</tt></td>
    <td>String, Nil</td>
    <td>Proxy authentication</td>
    <td>Not given</td>
  </tr>
  <tr>
    <td><tt>['endpoint']['change_delay']</tt></td>
    <td>Integer</td>
    <td>Seconds to wait after a configuration change.</td>
    <td>0</td>
  </tr>
  <tr>
    <td><tt>['endpoint_auth']['user']</tt></td>
    <td>String</td>
    <td>Username to access the API<br/>This may be overwriten by Chef Vault</td>
    <td><tt>op5chef-test$LDAP</tt></td>
  </tr>
  <tr>
  <td><tt>['endpoint_auth']['password']</tt></td>
    <td>String</td>
    <td>Password to access the API<br/>This may be overwriten by Chef Vault</td>
    <td><tt>*********</tt></td>
  </tr>
  <tr>
    <td><tt>['op5_manage']['cache']['enabled']</tt></td>
    <td>Bool</td>
    <td>Use caching</td>
    <td><tt>true</tt></td>
  </tr>
  <tr>
    <td><tt>['op5_manage']['cache']['path']</tt></td>
    <td>String</td>
    <td>Cache file</td>
    <td><tt>/var/lib/op5_manage/cache.json</tt></td>
  </tr>
  <tr>
    <td><tt>['op5_manage']['cache']['max_age']</tt></td>
    <td>String</td>
    <td>Seconds before configuration will be fetched from server again.</td>
    <td><tt>604800</tt></td>
  </tr>
  <tr>
    <td><tt>['op5_manage']['node']</tt></td>
    <td>Hash</td>
    <td>Manage local host</td>
    <td><tt></tt></td>
  </tr>
  <tr>
    <td><tt>['op5_manage']['hosts']</tt></td>
    <td>Hash</td>
    <td>Manage multiple services. See <a href="https://demo.op5.com/api/help/config/host">op5 Api host manual</a> for Api methods</td>
    <td>See host.rb attributes file</td>
  </tr>
  <tr>
    <td><tt>['op5_manage']['services']</tt></td>
    <td>Hash</td>
    <td>Manage multiple services. See <a href="https://demo.op5.com/api/help/config/host">op5 Api host manual</a> for Api methods</td>
    <td>See service.rb attributes file</td>
  </tr>
  <tr>
    <td><tt>['op5_manage']['host_downtimes']</tt></td>
    <td>Hash</td>
    <td>Schedule various kinds of host downtimes.</td>
    <td>See host_downtime.rb attributes file</td>
  </tr>
</table>


## License and Authors

Copyright 2016 Jakob Pfeiffer (<pgp-jkp@pfeiffer.ws>)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

