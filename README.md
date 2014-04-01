Description
===========

Cookbook to manage deployment of X509 certificates across an
infrastructure.

Keys and CSRs are generated according to "x509_certificate" resources
during a chef-client run on the hosts which will use them, with the
CSRs pushed to the Chef server. Later, certificates are signed by the
appropriate CAs and pushed to Chef. A subsequent run deploys the
signed certificate.

Temporary certificates are issued to enable services to start while
the CSRs are waiting to be processed.

Generated keys are encrypted to a key-vault key, and pushed to Chef
for backup.

Requirements
============

Chef Server

"vt-gpg" Cookbook

"eassl2", "gpgme" gems

GnuPG 2.x

Attributes
==========

GPG is used to encrypt generated keys for archival purposes.

`node['x509']['key_vault']` - the email address of the GPG/PGP recipient.

When set to nil (the default), keys will not be archived.

DN components to use when creating certificate names:

 * `node['x509']['country']`
 * `node['x509']['state']`
 * `node['x509']['city']`
 * `node['x509']['organization']`
 * `node['x509']['department']`
 * `node['x509']['email']`

Usage
=====

    include_recipe "x509"

Webserver SSL certificate:

    x509_certificate "www.example.com" do
      ca "MyCA"
      key "/etc/ssl/www.example.com.key"
      certificate "/etc/ssl/www.example.com.cert"
    end

Webserver SSL certificate specifying key size and validity period:

    x509_certificate "www.example.com" do
      ca "MyCA"
      key "/etc/ssl/www.example.com.key"
      certificate "/etc/ssl/www.example.com.cert"
      bits 1024
      days 365
    end

REST API Server Certificate, with CA Certificate:

    x509_certificate "service.example.com" do
      ca "Service-CA"
      key "/etc/ssl/service.example.com.key"
      certificate "/etc/ssl/service.example.com.cert"
      cacertificate "/etc/ssl/service_cacert"
    end

REST API Client Certificate:

    x509_certificate "service-#{node['fqdn']}" do
      cn node['fqdn']
      ca "Service-CA"
      type "client"
      key "/etc/service/client_key.pem"
      certificate "/etc/service/client_cert.pem"
    end

CA Certificate only, for verification:

    x509_ca_certificate "My-CA" do
      cacertificate "/etc/myca.pem"
    end

Signing Client
==============

A client is provided which allows a user to search Chef for
outstanding CSRs, sign them, and create data bag items containing the
new certificates.

The client is available in this repository, in the `client-gem`
directory, and may be packaged as a gem for installation.

A number of gems are required, and a Gemfile is provided for Bundler's
use.

It also needs access to a Chef admin client key, which may be your own
client, and to your ~/.chef/knife.rb which configures the server, key
path and client name.

There are a number of  modes of operation:

 * Find CSRs to be signed by a specific CA, and sign them with that CA.

 * Issue an adhoc certificate to a specific DN.

 * Create a new CA.

 * Find all CSRs awaiting action.

 * Find a specific CSR and provide its signed cert - intended for externally-signed CSRs,
   such as the public SSL certificate providers.

See the chef-ssl program's embedded help text for options:

    $ chef-ssl
    chef-ssl

    Chef-automated SSL certificate signing tool

    Commands:
      autosign             Search for CSRs and sign them with the given CA
      gencrl               Generate a Certificate Revocation List from revoked certificates
      help                 Display global or [command] help documentation.
      issue                Issue an ad hoc certificate
      makeca               Creates a new CA
      revoke               Revoke a certificate for the given HOSTNAME
      search               Searches for outstanding CSRs
      sign                 Search for the given CSR by name and provide a signed certificate

    Global Options:
      -h, --help           Display help documentation
      -v, --version        Display version information
      -t, --trace          Display backtrace when an error occurs


Workflow
========

Regular use via the chef cookbooks:

1) Use the `x509_certificate` resource in a recipe, and run chef-client
on the node.  The first converge of the resource does the following:

 * Creates a new key, with no passphrase.
 * Generates and installs a certificate, signed by an ephemeral CA.
 * Creates a CSR, which is placed in `node[:csr_outbox]`.

2) Use the `chef-ssl` tool to find and process pending CSRs.  The
signed certificate is placed into a databag item.

3) Run chef-client on the node again.  This converge does the
following:

 * Retrieves the certificate databag item.
 * Removes the corresponding entry from `node[:csr\_outbox]`.
 * Installs the signed certificate from the databag.

4) If the certificate needs to be revoked for say 'foo.bar.com', revoking it is a two step process:
 * Revoke the certificate: `chef-ssl revoke foo.bar.com`
 * Generate the CRL: `chef-ssl gencrl --ca-path ./cadir --ca-config ./cadir/conf/ca.conf`

Occasionally certificates need to be issued outside of the chef cookbook use, for example, for load balancers:

1) Issue the certificate
 * `chef-ssl issue --ca-path ./cadir --dn /CN=foo.bar --type client --save --host "foo.bar"`
 * the CSR and Certificate are stored in the certificates data bag. The key and certificate are printed to stdout.

Revoking Certificates
=====================

A few notes about revoking certificates. This is a two step process on purpose. Some background:

 * There is no API in openssl to revoke certificates. It is done using the "openssl ca -revoke" command line.
 * To revoke a certificate you need the CA passphrase. Storing this insecurely is a horrible idea. 
 * The author had a requirement to support marking certificates as 'revoked' using tools other than chef-ssl (ie: python) but maintaining the workflow.

So the two steps are:

1) Using `chef-ssl revoke`, move the certificate from the "certificates" data bag to the "revoked\_certificates" data bag, adding "revoked: false", "serial" set with the certificate's serial number (in decimal) and "revoked\_date" with the current date/time. Other recipes, if required, can pull the list of revoked certificates and store them locally to reject new incoming connections as needed (ie: OpenVPN etc which supports a directory of decimal serial numbers as of v2.3, etc). This movement of the certificate data bag item can be easily emulated by other languages as well. 

2) Using `chef-ssl gencrl`, really revoke the certificates that are marked "revoked: false" using the openssl command, set "revoked: true" and add "revoked\_date\_v2" with the current date/time. Once that is done for any number of certificates, generate the CRL file using the `openssl ca -gencrl` command. Note that this command will generate the CRL for all revoked certificates including those revoked outside of the chef-ssl tool. For convenience the CRL file is uploaded to the `certificate_revocation_list` data bag.

The main limitation is that certificates generated using the "chef-ssl issue" command may not be stored in the data bag(s) and thus must be revoked manually using the `openssl ca -revoke` command. The `chef-ssl gencrl` will include them in the updated CRL. As of v1.2 of the chef-ssl tool, the "chef-ssl issue" command support saving the issued certificate in the certificates databag by specifying the "--save" option.


FAQ
===

Q) Can I get my CSR signed by a commercial Certificate Authority?

A) Yes - use the `chef-ssl sign` command to retrieve the CSR, and to
supply the text of the signed certificate.

Q) My certificate is about to expire - how can I generate a new CSR?

A) Remove the databag item for the certificate.  The next time
chef-client is run on the node, a new CSR will be placed in
node[:csr_outbox].  The existing key and certificate will not be
touched.

Q) How does chef-ssl interact with an existing openssl directory structure?

A) It doesn't unfortunately. OpenSSL installations typically, but not always, have a `/public`, `/private` and `/conf` directories and the config file in the `/conf` directory specifies the name of the CA key and certificate files, the EaSSL2 library used by chef-ssl does not support this. It expects one directory with three files in it, `cakey.pem`, `cacert.pem` and `serial.txt`. To deal with this, in your openssl root directory create a `/chef` directory, and link the CA's cert, key and serial file as required. For example:

```
my_ca
+--public
|  +--my_ca_cert.pem
+--private
|  +--my_ca_key.pem
+--conf
|  +--my_ca_config.conf
|  +--serial
|  +--index
+--chef
|  +--cakey.pem   -> ../private/my_ca_key.pem
|  +--cacert.pem  -> ../public/my_ca_cert.pem
|  +--serial.txt  -> ../conf/serial
```


TESTING
=======

There are rspec tests in the spec directory, which use the rspec-chef
library bundled with the cookbook. These can be run directly:

  $ bundle
  $ bundle exec rspec spec/**/*_spec.rb


TODO
====


Licence and Author
==================

Author:: Chris Andrews (<candrews@venda.com>)
Author:: Zac Stevens (<zts@cryptocracy.com>)

Copyright 2011-2012 Venda Ltd

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
