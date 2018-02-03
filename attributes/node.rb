# Cookbook Name:: op5_manage
# Attributes:: node


default['op5_manage']['node'] = {
    'centos'    => { 'template' => 'default-host-template', 'hostgroups' => { 'Linux servers' => true }},
    'redhat'    => { 'template' => 'default-host-template', 'hostgroups' => { 'Linux servers' => true }},
    'suse'      => { 'template' => 'default-host-template', 'hostgroups' => { 'Linux servers' => true }},
    action:     :create
}


# If true, initial downtime for host will be set on server provisioning
default['op5_manage']['node']['initial_downtime']['enabled'] = true

# If false, server is newly provisioned
default['op5_manage']['node']['initial_downtime']['scheduled'] = false

# Duration of initial downtime in hours
default['op5_manage']['node']['initial_downtime']['duration'] = 24
