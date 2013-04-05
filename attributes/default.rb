# When set, the generated key will be GPG encrypted to this recipient,
# and the encrypted copy stored in node data. eg:
# default['x509']['key_vault'] = 'keyvault@example.com'
#
default['x509']['key_vault'] = nil

default['x509']['country'] = 'GB'
default['x509']['state'] = 'London'
default['x509']['city'] = 'London'
default['x509']['organization'] = 'Example Ltd'
default['x509']['department'] = 'Certificate Automation'
default['x509']['email'] = 'x509-auto@example.com'
