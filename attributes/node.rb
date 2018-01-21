# Cookbook Name:: op5_manage
# Attributes:: node


default['op5_manage']['node'] = {
    action:           :create
}


# If true, initial downtime for host will be set on server provisioning
default['op5_manage']['initial_downtime']['enabled'] = true

# If false, server is newly provisioned
default['op5_manage']['initial_downtime']['scheduled'] = false

# Duration of initial downtime in hours
default['op5_manage']['initial_downtime']['duration'] = 336     # Two weeks
