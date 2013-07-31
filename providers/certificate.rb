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

  # Try to find this certificate in the data bag.
  certbag = search(:certificates, "id:#{cert_id}").first
  if certbag
    # Data bag item found - the CSR was processed, and can be removed
    # from the outbox
    if node.attribute?('csr_outbox')
      if node.set['csr_outbox'].delete(new_resource.name)
        new_resource.updated_by_last_action(true)
      end
    end
  else
    certbag ||= {}
  end

  if certbag['certificate']
    # If we found a certificate databag, consider installing it.

    # verify first that we do have a key for this certificate
    if ::File.size?(new_resource.key)

      # verify that the certificate we've found corresponds to the key we have
      # (if not, maybe someone created the key+cert manually)
      if x509_verify_key_cert_match(::File.read(new_resource.key), certbag['certificate'])
        Chef::Log.info("installing certificate #{new_resource.name} (id #{cert_id})")
        f = resource("file[#{new_resource.certificate}]")
        if new_resource.joincachain && certbag['cacert']
          f.content certbag['certificate'] + certbag['cacert']
        else
          f.content certbag['certificate']
        end
        f.action :create
        
        if new_resource.cacertificate && certbag['cacert']
          f = resource("file[#{new_resource.cacertificate}]")
          f.content certbag['cacert']
          f.action :create
        end
      else
        Chef::Log.warn("not installing certificate #{new_resource.name} (id #{cert_id}), does not match key")
      end
    else
      Chef::Log.warn("found certificate #{new_resource.name} (id #{cert_id}), for which we don't have the key")
    end
  else
    # If we didn't, we need to generate a CSR.
    node.set['csr_outbox'] ||= {}

    # Unless there's already a CSR in the out box, create one with a
    # new key, and issue a self-signed cert.
    if node['csr_outbox'][new_resource.name]
      Chef::Log.warn("skipping CSR generation - CSR is in the outbox")
    else

      if ::File.size?(new_resource.key)
        # If we already have a private key, reuse it
        key = x509_load_key(new_resource.key)

        if node['x509']['key_vault']
          encrypted_key = gpg_encrypt(key.private_key.to_s, node['x509']['key_vault'])
        else
          encrypted_key = nil
        end

        # Generate the new CSR using the existing key
        csr = x509_generate_csr(
          key,
          :common_name => new_resource.cn || new_resource.name,
          :city => node['x509']['city'],
          :state => node['x509']['state'],
          :email => node['x509']['email'],
          :country => node['x509']['country'],
          :department => node['x509']['department'],
          :organization => node['x509']['organization']
        )
        cert = nil
      else
        # Generate and encrypt the private key with the public key of
        # the key vault user.
        key = x509_generate_key(new_resource.bits)

        if node['x509']['key_vault']
          encrypted_key = gpg_encrypt(key.private_key.to_s, node['x509']['key_vault'])
        else
          encrypted_key = nil
        end

        # Generate the CSR, and sign it with a scratch CA to create a
        # temporary certificate.
        csr = x509_generate_csr(key,
          :common_name => new_resource.cn || new_resource.name,
          :city => node['x509']['city'],
          :state => node['x509']['state'],
          :email => node['x509']['email'],
          :country => node['x509']['country'],
          :department => node['x509']['department'],
          :organization => node['x509']['organization']
        )
        cert, ca = x509_issue_self_signed_cert(
          csr,
          new_resource.type,
          :city => node['x509']['city'],
          :state => node['x509']['state'],
          :email => node['x509']['email'],
          :country => node['x509']['country'],
          :department => node['x509']['department'],
          :organization => node['x509']['organization']
        )
      end

      node.set['csr_outbox'][new_resource.name] = {
        :id => cert_id,
        :csr => csr.to_pem,
        :key => encrypted_key,
        :ca => new_resource.ca,
        :date => Time.now.to_s,
        :type => new_resource.type,
        :days => new_resource.days
      }

      # write out the key
      f = resource("file[#{new_resource.key}]")
      f.content key.private_key.to_s
      f.action :create

      # write out the cert if we created a temporary one
      unless cert.nil?
        f = resource("file[#{new_resource.certificate}]")
        f.content cert.to_pem
        f.action :create
      end

      if new_resource.cacertificate && !ca.nil?
        f = resource("file[#{new_resource.cacertificate}]")
        f.content ca.certificate.to_pem
        f.action :create
      end

      new_resource.updated_by_last_action(true)
    end
  end
end

def resource(name)
  run_context.resource_collection.find(name)
end
