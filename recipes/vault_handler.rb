# Cookbook Name:: op5_manage
# Recipe:: vault_handler


# Replace op5 endpoint credentials by encrypted Chef Vault data
endpoint = node['op5_manage']['endpoint']

unless Chef::Config[:node_path].include?('kitchen') or endpoint['vault_name'].nil?
  include_recipe 'chef-vault'

  vault = chef_vault_item(endpoint['vault_name'], endpoint['vault_item'])
  node.run_state['endpoint_auth']['user'] = vault['op5_manage']['endpoints'][endpoint['url']]['user']
  node.run_state['endpoint_auth']['password'] = vault['op5_manage']['endpoints'][endpoint['url']]['password']
end
