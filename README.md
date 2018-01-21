# op5_manage

- Create, modify or remove hosts and services. Either from all your Chef nodes or from a single host.
- Schedule down times for host objects.
- Sophisticated caching is used to perform as less Api requests as possible.

All operations are performed using the restful op5 Api
https://www.op5.com/explore-op5-monitor/features/op5-monitor-api/

## Supported Platforms

- CentOS 6, 7
- Red Hat Enterprise Linux 6, 7
- SuSE Linux Enterprise Server 11, 12


## Configuration

### op5 endpoints

An endpoint is all the information to connect to an op5 Api server. All of them are configured by attributes in the
 default.rb file. In addition sensitive credentials like username and password may stored in a Chef Vault. Only vaults
 of type client are supported.

#### Creating an endpoint vault

On your Chef build environment write your credentials to a JSON file.
```json
{
  "op5_manage": {
    "endpoints": {
      "https://server.domain.tld/api": {
        "user": "Username",
        "password": "Pa$$w0rd"
      },
      "https://other.endpoint.local/api": {
          "user": "Username",
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
-A user1,user2 -S 'run_list:recipe\[op5_manage\:\:*\]'
-M client -J ~/op5_endpoints.json
```

Changing the content of this vault item is easy.
```
knife vault edit op5_manage endpoints
```

Configure attributes to use your vault instead of username and password. See attributes file default.rb for more
 information.

#### Order of run list

The op5_manage cookbook should be the last in run list.

## Usage

### Add a Chef node to op5 monitoring

The node.rb recipe is used to manage the current node. This is the common use case so you just have to add the default
 recipe to your run list. Without any configuration, host is created in op5 with a host group depending on your os.
 Use attributes to modify host parameters. Either in a recipe or in a role or environment (with JSON).

```ruby
default['op5_manage']['node'] = {
    'hostgroups_add'    => [ 'hg_app_https_8443' ],
    'custom_variable'   => {
        '_API_PING_TXT' => 'OK',
        '_API_PING_URL' => '/artifactory/api/system/ping'
    },
    'services' => {
        'HTTPS URL API Ping' => {
            'template'            => 'alarm-template_business_processes',
            'check_command'       => 'check_https_url_string',
            'check_command_args'  => '"$_API_PING_URL$"!"$_API_PING_TXT$"',
            'notes_url'           => 'https://intranet.mydomain.tld/Monitoring#Checks-HTTPSURL',
            'action_url'          => 'https://$HOSTADDRESS$$_API_PING_URL$'
        }
    }
}
```

```json
{
  "op5_manage": {
    "node": {
      "hostgroups_add": [ "hg_app_https_8443" ],
      "custom_variable": {
        "_API_PING_TXT": "OK",
        "_API_PING_URL": "/artifactory/api/system/ping"
      },
      "services": {
        "HTTPS URL API Ping": {
          "template":           "alarm-template_business_processes",
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
 - hg_app_https_8443
 - hg_middleware_tomcat_8080
 - hg_app_java

All hostgroups are listed here:
https://demo.op5.com/monitor/index.php/listview/?q=%5Bhostgroups%5D%20all


### Schedule host downtimes

The host_downtime.rb schedules various kinds of host downtimes. Please refer to op5 Api documentation for details.
https://demo.op5.com/api/help/command/SCHEDULE_HOST_DOWNTIME
https://demo.op5.com/api/help/command/SCHEDULE_AND_PROPAGATE_HOST_DOWNTIME
https://demo.op5.com/api/help/command/SCHEDULE_AND_PROPAGATE_TRIGGERED_HOST_DOWNTIME

Downtimes are defined by attributes.

```ruby
default['op5_manage']['host_downtimes'] = {
  'maintenance_artiprod-21.mydomain.tld' => {
    'command'     => 'SCHEDULE_HOST_DOWNTIME',
    'host_name'   => 'artiprod-21.mydomain.tld',
    'start_time'  => '23.10.2017 14:20',
    'end_time'    => '2017-10-23 14:24',
    'fixed'       => true,
    'duration'    => 0,
    'trigger_id'  => 0,
    'comment'     => 'Maintenance downtime for artiprod-21.mydomain.tld'
  }
}
```

```json
{
  "op5_manage": {
    "host_downtimes": {
      "maintenance_artiprod-21.mydomain.tld": {
        "command": "SCHEDULE_HOST_DOWNTIME",
        "host_name": "artiprod-21.mydomain.tld",
        "start_time": "23.10.2017 23:00",
        "end_time": "2017-10-23 23:10",
        "fixed": false,
        "duration": 5,
        "trigger_id": 0,
        "comment": "Maintenance downtime for artiprod-21.mydomain.tld"
      }
    }
  }
}
```

### Initial downtimes

Initial downtime recipe can be used to schedule a host downtime for newly provisioned servers. To prevent recipe from
 scheduling downtimes for existing servers, you can run knife command to set attribute.

```
knife exec -E "nodes.transform('name:dbsvrpip01-04.mydomain.tld') {|n| n.normal_attrs['op5_manage']['initial_downtime']['scheduled']=true  rescue nil }"
knife exec -E "nodes.transform('name:dbsvrpip01-04.mydomain.tld') {|n| n.normal_attrs['op5_manage'].delete('initial_downtime') rescue nil }"

knife exec -E "nodes.transform(:all) {|n| n.normal_attrs['op5_manage']['initial_downtime']['scheduled']=true  rescue nil }"
```


## Troubleshoting

- I recommend to use [chef_hostname](https://supermarket.chef.io/cookbooks/chef_hostname) in your run list to
 avoid inconsistent state of hostname and node['fqdn'] after provisioning.
- There is an open bug on caching host_downtimes. To work around you should never change the properties of
 an existing downtime. Also you must remove all downtimes in Chef before deleting the host on op5 server.
- If you are looking for an issue it's a good advice to rename the cache file (/var/lib/op5_manage/cache.json)
 or temporary disable caching (node['op5_manage']['cache']['enabled'])


## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['op5_manage']['']</tt></td>
    <td>String</td>
    <td></td>
    <td><tt></tt></td>
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
    <td>See service.rb attributes file</td>
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
    <td>See host.rb attributes file</td>
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