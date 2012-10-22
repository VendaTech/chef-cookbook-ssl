begin
  require 'eassl'
rescue LoadError => e
  Chef::Log.warn("SSL library dependency 'eassl' not loaded: #{e}")
end

def ssl_generate_key(bits)
  return EaSSL::Key.new(:bits => bits)
end

def ssl_load_key(path)
  return EaSSL::Key.load(path)
end

def ssl_generate_csr(key, name)
  ea_name = EaSSL::CertificateName.new(name)
  ea_csr  = EaSSL::SigningRequest.new(:name => ea_name, :key => key)
  ea_csr
end

def ssl_issue_self_signed_cert(csr, type, name)
  # generate some randomness so that temporary CAs are unique, since
  # all the serial numbers are the same. some browsers will reject all
  # but the first with the same common name and serial, even if the
  # certificate is different.
  rand = Base64.urlsafe_encode64(OpenSSL::Random.pseudo_bytes(12))
  name[:common_name] = "Temporary CA #{rand}"
  ca = EaSSL::CertificateAuthority.new(:name => name)
  cert = EaSSL::Certificate.new(
    :type => type,
    :signing_request => csr,
    :ca_certificate => ca.certificate
  )
  cert.sign(ca.key)
  return cert, ca
end
