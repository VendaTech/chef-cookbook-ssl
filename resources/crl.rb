actions :create

def initialize(*args)
  super
  @action = :create
end

attribute :ca, :kind_of => String, :name_attribute => true
attribute :path, :kind_of => String, :required => true

attribute :owner, :kind_of => String, :default => 'root'
attribute :group, :kind_of => String, :default => 'root'
attribute :mode, :kind_of => String, :default => '0644'
