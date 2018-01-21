name              'op5_manage'
maintainer        'Jakob Pfeiffer'
maintainer_email  'pgp-jkp@pfeiffer.ws'
license           'Apache 2.0'
source_url        'https://github.com/SlashDashAndCash/op5_manage.git'
description       'Manage op5 hosts and services'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

version '0.8.1'

# Weired release numbers for supermarket
supports 'centos', '>= 6.0.0'
supports 'redhat', '>= 6.0.0'
supports 'suse',   '>= 11.0.0'

depends 'chef-vault'

