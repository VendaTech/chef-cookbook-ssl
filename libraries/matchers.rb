if defined?(ChefSpec)

  def provision_certificate(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :x509_certificate, :create, resource_name
    )
  end

end
