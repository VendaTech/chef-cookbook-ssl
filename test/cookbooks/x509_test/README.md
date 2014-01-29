Description
===========

This is the test cookbook for "x509".

Requirements
============

Must be deployed with the chef-zero provisioned, to support the
searches this cookbooks does.

Usage
=====

Intended to be used with test-kitchen 1.0+.

You'll need a .kitchen.local.yml which provides the driver, any
driver_config required, and the plaforms. As an example:

  ---
  driver:
    name: docker
    socket: tcp://192.168.42.43:4243
  
  driver_config:
    require_chef_omnibus: false
  
  platforms:
  - name: centos5
    driver_config:
      image: devsrv03.of-1.uk.venda.com:5000/venda-centos5
      platform: centos
  - name: centos6
    driver_config:
      image: devsrv03.of-1.uk.venda.com:5000/venda-centos6
      platform: centos
  
