#
# Cookbook Name:: x509
# Recipe:: default
#
# Copyright 2011-2012 Venda Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# We only need vt-gpg if we're using the keyvault
if node['x509']['key_vault']
  include_recipe "vt-gpg"
end

chef_gem "eassl2" do
  action :nothing
end.run_action(:upgrade)

require 'eassl'
