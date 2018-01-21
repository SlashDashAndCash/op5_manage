# 0.1.3

 - Initial release of basic

# 0.2.0

 - New method host_config_eql? in op5_api_helper
 - Added idempotence to host actions :create and :remove
 - Ability to change the configuration of an already existing host

# 0.3.0

 - Creates, modifies and removes services. Services can only be bound to hosts but not to hostgroups.

# 0.4.0

 - Added node.rb recipe to manage host by host itself from their local machine.

# 0.5.0

 - Use Chef Vault to encrypt op5 endpoint credentials.

# 0.5.1

 - Replaced node.set by node default. Some documentation.

# 0.5.2

 - New helper recipe vault_handler.rb
 - New users for op5 test and prod
 - Test user password included in cookbook now for kitchen

# 0.5.3

 - Default action :create for hosts and services

# 0.5.4

 - Nodes can create extra services now
 - custom_variables renamed to custom_variable

# 0.5.5

 - README.md completed
 - Ready for production

# 0.5.6

 - Support for RHEL nodes
 
# 0.5.7

 - Fix RHEL support

# 0.5.8

 - Changed endpoint settings from node.run_state to default attribute
 - Moved endpoint authentication credentials to new node.run_state

# 0.5.9

 - Minor fixes
 - Documentation

# 0.6.0

 - Added order of run list and typical host groups to README

# 0.6.1

 - Workaround for bug ITB-19274 (comparison of Hash with Hash failed)
 - Replaced deprecated Fixnum by Interger
 - Better exception of Test Kitchen from vault_handling

# 0.6.2

 - Bugfix: removed is_volatile from node recipe

# 0.7.0

 - Final fix for embedded services in host config (ITB-19274)
 - New data structure in vault for better integration in shared items
 - Cache file now defaults to /var/lib/op5_manage/cache.json

# 0.8.0

 - New resource to schedule host downtimes
 - Recipe to schedule initial downtime right after server provisioning
 - Moved host attributes from attributes file to .kitchen.yml file
 - Services are managed by attributes instead of recipe now.

# 0.8.1

 - README.md
