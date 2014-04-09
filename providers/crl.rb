action :create do
  item = x509_get_crl(new_resource.ca)
  if not new_resource.filename.nil?
    crl_file = new_resource.filename
  else
    crl_file = "/etc/ssl/certs/#{item['hash']}.r0"
  end
  Chef::Log.info("MDH: filename: #{crl_file}")
  new_resource.filename = crl_file
  file crl_file do
    content item['crl']
    action :create
    owner new_resource.owner
    group new_resource.group
    mode new_resource.mode
  end
  new_resource.updated_by_last_action(true)
end
