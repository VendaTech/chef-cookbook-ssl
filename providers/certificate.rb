require 'digest/sha2'

action :create do

  file new_resource.certificate do
    owner new_resource.owner
    group new_resource.group
    mode "0644"
    action :nothing
  end
  file new_resource.key do
    owner new_resource.owner
    group new_resource.group
    mode "0600"
    action :nothing
  end
  if new_resource.cacertificate
    file new_resource.cacertificate do
      owner new_resource.owner
      group new_resource.group
      mode "0644"
      action :nothing
    end
  end

  name_sha = Digest::SHA256.new << new_resource.name
  cert_id = name_sha.to_s

  # try: get databag
  begin
    certbag = data_bag_item('certificates', cert_id)
    if node.attribute?('csr_outbox')
      if node['csr_outbox'].delete(new_resource.name)
        new_resource.updated_by_last_action(true)
      end
    end
  rescue Net::HTTPServerException
    certbag = {}
  end

  if certbag['certificate']
    # If we found a certificate databag, install it.

    if ::File.size?(new_resource.key)
      file new_resource.certificate do
        content certbag['certificate']
        action :create
      end
      if new_resource.cacertificate && certbag['cacert']
        file new_resource.cacertificate do
          content certbag['cacert']
          action :create
        end
      end
    else
      Chef::Log.warn("found certificate #{new_resource.name} (id #{cert_id}), for which we don't have the key")
    end
  else
    # If we didn't, we need to generate a CSR.
    node['csr_outbox'] ||= {}

    # Unless there's already a CSR in the out box, create one with a
    # new key, and issue a self-signed cert.
    if node['csr_outbox'][new_resource.name]
      Chef::Log.warn("skipping CSR generation - CSR is in the outbox")
    else

      if ::File.size?(new_resource.key)
        # If we already have a private key, reuse it
        key = ssl_load_key(new_resource.key)
        encrypted_key = gpg_encrypt(key.private_key.to_s, node['ssl']['key_vault'])

        # Generate the new CSR using the existing key
        csr = ssl_generate_csr(
          key,
          :common_name => new_resource.cn || new_resource.name,
          :city => node['ssl']['city'],
          :state => node['ssl']['state'],
          :email => node['ssl']['email'],
          :country => node['ssl']['country'],
          :department => node['ssl']['department'],
          :organization => node['ssl']['organization']
        )
        cert = nil
      else
        # Generate and encrypt the private key with the public key of
        # the key vault user.
        key = ssl_generate_key(new_resource.bits)
        encrypted_key = gpg_encrypt(key.private_key.to_s, node['ssl']['key_vault'])

        # Generate the CSR, and sign it with a scratch CA to create a
        # temporary certificate.
        csr = ssl_generate_csr(key,
          :common_name => new_resource.cn || new_resource.name,
          :city => node['ssl']['city'],
          :state => node['ssl']['state'],
          :email => node['ssl']['email'],
          :country => node['ssl']['country'],
          :department => node['ssl']['department'],
          :organization => node['ssl']['organization']
        )
        cert, ca = ssl_issue_self_signed_cert(
          csr,
          new_resource.type,
          :city => node['ssl']['city'],
          :state => node['ssl']['state'],
          :email => node['ssl']['email'],
          :country => node['ssl']['country'],
          :department => node['ssl']['department'],
          :organization => node['ssl']['organization']
        )
      end

      node['csr_outbox'][new_resource.name] = {
        :id => cert_id,
        :csr => csr.to_pem,
        :key => encrypted_key,
        :ca => new_resource.ca,
        :date => Time.now.to_s,
        :type => new_resource.type,
        :days => new_resource.days
      }

      # write out the key
      file new_resource.key do
        content key.private_key.to_s
        action :create
      end

      # write out the cert if we created a temporary one
      unless cert.nil?
        file new_resource.certificate do
          content cert.to_pem
          action :create
        end
      end

      if new_resource.cacertificate && !ca.nil?
        file new_resource.cacertificate do
          content ca.certificate.to_pem
          action :create
        end
      end

      new_resource.updated_by_last_action(true)
    end
  end
end
