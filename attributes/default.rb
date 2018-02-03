# Cookbook Name:: op5_manage
# Attributes:: default

# Endpoint
#
# url:          URL of the op5 server e.g. https://demo.op5.com/api [String]
# user:         Username to access the API. [String]
#               Append $LDAP to change authentication method.
#               Append $Default to use default method.
# password:     Password to access the API. [String]
#
# vault_name:   Use Chef Vault to overwrite user and password.
#               Set to vault name or nil to not use vaults. See README.ms [symbol, nil]
# vault_item:   The item within the vault containing the endpoint credentials. [String]
#
# tls_verify:   If tls_verify is given and set to false, TLS server
#               certificate validation is disabled. Use with caution! [TrueClass, FalseClass]
# proxy_addr:   If not given, the ENVVAR http_proxy will be used. [String, nil]
#               Set to nil (no proxy) or to valid FQDN to overwrite.
# proxy_port:   Proxy port number. Only used if proxy_addr is given. [Interger, nil]
# proxy_user:   For proxy authentication. [String, nil]
# proxy_pass:   For proxy authentication. [String, nil]
# change_delay: Seconds to wait after a configuration change. [Integer]
#               Set 0 to disable


default['op5_manage']['endpoint'] = {
    'url'          => 'https://op5.mydomain.tld/api',
    'vault_name'   => :op5_manage,
    'vault_item'   => 'endpoints',
    'tls_verify'   => true,
    'proxy_addr'   => nil,
    'change_delay' => 0
}

node.run_state['endpoint_auth'] = {
    'user'        => 'Username$LDAP',
    'password'    => 'Pa$$w0rd'
}

# Cache
#
# enabled:      Use caching [TrueClass, FalseClass]
# path:         Cache file [String]
# max_age:      Seconds before configuration will be
#               fetched from server again. [Interger]
#               Default: seven days

default['op5_manage']['cache'] = {
    'enabled'       => true,
    'path'          => '/var/lib/op5_manage/cache.json',
    'max_age'       => 604800
}
