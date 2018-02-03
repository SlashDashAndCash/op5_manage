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



actions :create, :remove
default_action :create

# host_name is part of resource name (host_name;service_description)
# service_description is part of resource name (host_name;service_description)

attribute :action_url,                    :kind_of => String, :default => nil
attribute :active_checks_enabled,         :kind_of => [ TrueClass, FalseClass ], :default => nil
attribute :check_command,                 :kind_of => String, :required => true
attribute :check_command_args,            :kind_of => String, :default => nil
attribute :check_freshness,               :kind_of => [ TrueClass, FalseClass ], :default => nil
attribute :check_interval,                :kind_of => Integer, :default => nil
attribute :check_period,                  :kind_of => String, :default => nil
attribute :contact_groups,                :kind_of => Hash,  :default => nil
attribute :contacts,                      :kind_of => Hash,  :default => nil
attribute :display_name,                  :kind_of => String, :default => nil
attribute :event_handler,                 :kind_of => String, :default => nil
attribute :event_handler_args,            :kind_of => String, :default => nil
attribute :event_handler_enabled,         :kind_of => [ TrueClass, FalseClass ], :default => nil
attribute :file_id,                       :kind_of => String, :default => nil
attribute :first_notification_delay,      :kind_of => Integer, :default => nil
attribute :flap_detection_enabled,        :kind_of => [ TrueClass, FalseClass ], :default => nil
attribute :flap_detection_options,        :kind_of => Hash,  :default => nil
attribute :freshness_threshold,           :kind_of => Integer, :default => nil
attribute :high_flap_threshold,           :kind_of => Integer, :default => nil
#Hostgroups are unsupported yet
#attribute :hostgroup_name,                :kind_of => String, :default => nil
attribute :icon_image,                    :kind_of => String, :default => nil
attribute :icon_image_alt,                :kind_of => String, :default => nil
attribute :low_flap_threshold,            :kind_of => Integer, :default => nil
attribute :max_check_attempts,            :kind_of => Integer, :default => nil
attribute :notes,                         :kind_of => String, :default => nil
attribute :notes_url,                     :kind_of => String, :default => nil
attribute :notification_interval,         :kind_of => Integer, :default => nil
attribute :notification_options,          :kind_of => Hash,  :default => nil
attribute :notification_period,           :kind_of => String, :default => nil
attribute :notifications_enabled,         :kind_of => [ TrueClass, FalseClass ], :default => nil
attribute :obsess,                        :kind_of => [ TrueClass, FalseClass ], :default => nil
attribute :parallelize_check,             :kind_of => [ TrueClass, FalseClass ], :default => nil
attribute :passive_checks_enabled,        :kind_of => [ TrueClass, FalseClass ], :default => nil
attribute :process_perf_data,             :kind_of => [ TrueClass, FalseClass ], :default => nil
attribute :register,                      :kind_of => [ TrueClass, FalseClass ], :default => nil
attribute :retain_nonstatus_information,  :kind_of => [ TrueClass, FalseClass ], :default => nil
attribute :retain_status_information,     :kind_of => [ TrueClass, FalseClass ], :default => nil
attribute :servicegroups,                 :kind_of => Hash,  :default => nil
attribute :retry_interval,                :kind_of => Integer, :default => nil
attribute :stalking_options,              :kind_of => Hash,  :default => nil
attribute :template,                      :kind_of => String, :default => nil
