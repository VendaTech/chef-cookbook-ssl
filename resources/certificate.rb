actions :create

def initialize(*args)
  super
  @action = :create
end

attribute :name, :kind_of => String, :name_attribute => true
attribute :cn,   :kind_of => String
attribute :ca,   :kind_of => String, :required => true
attribute :type, :kind_of => String, :default => 'server', :equal_to => ['server', 'client']
attribute :bits, :kind_of => Fixnum, :default => 2048, :equal_to => [1024, 2048, 4096, 8192]
attribute :days, :kind_of => Fixnum, :default => (365 * 5)

attribute :owner, :kind_of => String, :default => 'root'
attribute :group, :kind_of => String, :default => 'root'

attribute :cacertificate, :kind_of => String
attribute :certificate,   :kind_of => String, :required => true
attribute :key,           :kind_of => String, :required => true

attribute :joincachain,   :equal_to => [true, false], :default => false
