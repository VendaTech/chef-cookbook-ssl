#
# Cookbook Name:: x509
# Recipe:: localca
#
# Copyright 2012 Venda Ltd
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

node.set['cacerts'] ||= {}

certs_dir = '/etc/pki/tls/certs' # XXX platform dependent

search('certificates') do |item|

  if !item['cacert'].nil?
    cert = OpenSSL::X509::Certificate.new(item['cacert'])
    hash = sprintf("%x", cert.subject.hash)
    hash_path = File.join(certs_dir, "#{hash}.0")

    if !node['cacerts'].has_key?(hash_path) || node['cacerts'][hash_path] != item['cacert']

      file hash_path do
        content item['cacert']
        action :create
        owner "root"
        group "root"
        mode 0644
      end

      node.set['cacerts'][hash_path] = item['cacert']
    end
  end
end
