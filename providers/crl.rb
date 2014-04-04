
action :create do
  # search for CRL in one of its issued certificate databags
  items = search('certificate_revocation_list', "ca:#{new_resource.ca}") do |item|
    file new_resource.path do
      content item['crl']
      action :create
      owner new_resource.owner
      group new_resource.group
      mode new_resource.mode
    end
    new_resource.updated_by_last_action(true)
  end
end
