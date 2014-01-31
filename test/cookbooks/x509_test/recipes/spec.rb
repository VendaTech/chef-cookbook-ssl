# certificate which doesn"t exist on the server

x509_certificate "new.example.com" do
  ca "test"
  type "server"
  certificate "/tmp/new.example.com.cert"
  cacertificate "/tmp/new.example.com.cacert"
  key "/tmp/new.example.com.key"
end

# certificate which does exist on the server
# and for which we have the key

x509_certificate "created.example.com" do
  ca "test"
  type "server"
  certificate "/tmp/created.example.com.cert"
  cacertificate "/tmp/created.example.com.cacert"
  key "/tmp/created.example.com.key"
end

# certificate which does exist on the server
# but for which we don't have the key

x509_certificate "nokey.example.com" do
  ca "test"
  type "server"
  certificate "/tmp/nokey.example.com.cert"
  cacertificate "/tmp/nokey.example.com.cacert"
  key "/tmp/nokey.example.com.key"
end
