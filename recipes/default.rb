#
# Cookbook Name:: ssl
# Recipe:: default
#
# Copyright 2012, Venda Ltd
#
# All rights reserved - Do Not Redistribute
#

include_recipe "gpg"
chef_gem "eassl2" do
  action :nothing
end.run_action(:upgrade)

require 'eassl'
