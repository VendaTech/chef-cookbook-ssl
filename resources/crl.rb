actions :create

def initialize(*args)
  super
  @action = :create
end

attribute :ca, :kind_of => String, :name_attribute => true
attribute :filename, :kind_of => String, :default => nil
attribute :owner, :kind_of => String, :default => 'root'
attribute :group, :kind_of => String, :default => 'root'
attribute :mode, :kind_of => String, :default => '0644'

attr_accessor :filename
