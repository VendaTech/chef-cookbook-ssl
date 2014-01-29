include_recipe "x509"

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

test_key = <<EOKEY
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAljRs99O6ZC5HZqOJadxv2yijK+S3JzwYjehK1kRO7CgIa3ul
Mj8VWRIMmRF2kOejxwwyd9MMm7QNLPiwZP2ZfWRI3ScGu2S6iUd1XdgQFZc4gAbo
qqQm8IP8uU01//rk35fDoIrCsKbt7TnSEzMNmxUtYX28se/mqSItped9MSPIl0Ci
pnh3rd50ZoBTVjnETno0ZWyRILhYaPgd71Ofag8C/IW+ebM2945RjX0/+/Qrya+v
F/OL57RfzgvcqNci/gq6EGWc0RtAJMrLTRQ/4ThOaZzIeh9+BG/KZz5wZogV6/Lx
D81JqAH0Hbj1ftv1Ur6WMpE+4htRQCJwSh1ZpQIDAQABAoIBAAEhQdSXbiaExpq6
DjWSp/DBHIEfBlWwOQsQPUfhWaqjHnUYiASZvuJdpWSdYgPzCiNcLyEBoG2nbBXz
hPgthDMSRw4K1h0gw9p2hCaBkpVm/tDPvH5UH8rdY1BNiWN0krYv4RPbF13W06Fe
NvtX/fk1rpK2LG42PMj27dr6o9FzzYI57qqBVRT7lvvNfw1/HIvDCAmzygF9QoSu
TnPDV6+IZvqLHJI24UkrctyCgPsiwwoAIwiLYJd8JwPGl7mY7DQXB3TkKpITaRFQ
TBLpv0fkM8wpolY5LZFd90JPVb4AcSNZgRpCeByycYxneqFAmom/ASie7WguoXfS
pwm3uUECgYEAxGamRd822imdXNQlB7QKF/W/fEXzWJugy1SFHFT1CZI5Y4XcyfKZ
4vIhSg3UyJXDkNTacONCuUkhhymAWRAlaJMZ79srIinOYG8mJAv+iPhWcG05QhEZ
+I77rFxzuoViD0xrdfU6lFejCGHr9S/GAKaiRKNeC5TgZGKd9ZLWoFECgYEAw8kK
D7MBcLIe1nWMLo7jUYpHi5qhWyqZ4kVaAx/tq7eYFV2wKlzNxjwWS4tpYUH5eM7V
vqGGLAFeI/ljyh5UXPFPiE1Ph4JxJfRJD4SuzGMt15CtAIM8rB76SHqlS8YNB0Ar
VdbFZ1ZQQPkPczUAQVe1CIlxf5PUz4z31Ft9QxUCgYEAr4vYvsdfLezYXOq6FoKU
KwpbF2cmtWKVfGiVedduFhn+9bfmuxL+/VzS6HAoawmB/ehjP1fCgf6d20P7FqBZ
73jcTAmoKicX8hYnDz0xS5g9Gsxly2mhvwt+ZHdWcbdbCLWTr6F7tLAIZyuvTj5f
SqGmlJc5LjzpvJBxA9k1waECgYB8+NHkTYYI0pnemO/fNDQj81lR4mVG1T2e8lfP
kMzcBHgeg0wU7mInPGma1SVyAHPmylgjs+T6J/FYkzNAa/W70gjLX1X5kKj66iDM
uAv/yPsVE3Nq1VqgH7HxG+BxKr1cOHiw9UPSf4UAxDo5dsZv7zVOerUpE0sPJNN5
COE/NQKBgBjPk1Zef/t5UU0CaAO51KRH31Ea9E3BoTUBFfsDMX37u4Zt6la1Wpvn
UBeCszVfl5+QZebAtPFzndr05j0s6bmusWtxaTxTgu+qbRuNwQa9DACfsXhWdUyW
BGVduHr2vigOl0ZOX1kgt+j9fMLsKWDqoOy2ucEp0bbZdR9eoTrP
-----END RSA PRIVATE KEY-----
EOKEY

# set owner/group/mode here - provider won't update it
file "/tmp/created.example.com.key" do
  content test_key
  owner "root"
  group "root"
  mode "0600"
end

# set up the csr_outbox attribute so the provider can clear it
node.set['csr_outbox']['created.example.com'] = 'foo'

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
