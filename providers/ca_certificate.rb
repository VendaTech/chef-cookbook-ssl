require 'digest/sha2'

action :create do
  node.set['cacerts'] ||= {}

  # search for CA in one of its issued certificate databags
  cacert = nil
  items = search('certificates', "ca:#{new_resource.ca}") do |item|
    if item['ca'] == new_resource.ca && !item['cacert'].nil?
      cacert = item['cacert']
      break
    end
  end

  if !node['cacerts'].has_key?(new_resource.ca) || node['cacerts'][new_resource.ca] != cacert
    # install the CA certificate where requested, and add it to the node
    if cacert
      file new_resource.cacertificate do
        content cacert
        action :create
        owner new_resource.owner
        group new_resource.group
      end
      node.set['cacerts'][new_resource.ca] = cacert
      new_resource.updated_by_last_action(true)
    end
  end
end
