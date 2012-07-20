actions :create

def initialize(*args)
  super
  @action = :create
end

attribute :ca, :kind_of => String, :name_attribute => true
attribute :cacertificate, :kind_of => String, :required => true

attribute :owner, :kind_of => String, :default => 'root'
attribute :group, :kind_of => String, :default => 'root'
