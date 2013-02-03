require 'simplecov'
SimpleCov.start do
  add_filter 'spec/'
end

serial_filename = File.expand_path('fixtures/ca/serial.txt',  File.dirname(__FILE__))

RSpec.configure do |c|
  c.mock_with 'flexmock'
  c.after(:each) do
    system("echo 0008 > #{serial_filename}") # avoid mocked File methods.
  end
end

require 'rspec'
require 'eassl'

$LOAD_PATH << File.expand_path('../lib', File.dirname(__FILE__))
require 'chef-ssl/client' # must load before commander

require 'commander'
require 'commander/delegates'

include Commander::UI
include Commander::UI::AskForClass
include Commander::Delegates

HighLine.colorize_strings

def new_command_runner(*args)
  setup_runner unless $runner_setup
  args << '--trace'
  Commander::Runner.instance.instance_variable_set :@args, args
  Commander::Runner.instance.instance_variable_set :@options, []
  Commander::Runner.instance.instance_variable_set :@__active_command, nil
  Commander::Runner.instance.instance_variable_set :@__command_name_from_args, nil
  Commander::Runner.instance
end

def setup_runner
  Commander::Runner.instance_variable_set :"@singleton", Commander::Runner.new([])
  load File.expand_path('../lib/chef-ssl/command.rb', File.dirname(__FILE__))
  $runner_setup = true
end

require 'stringio'

def capture(*streams)
  output = nil
  begin
    result = StringIO.new
    output = $terminal.instance_variable_get :@output
    $terminal.instance_variable_set :@output, result
    yield
  ensure
    $terminal.instance_variable_set :@output, output
  end
  result.string
end

module Commander
  class Command

    # monkeypatch to not lose the method Proc, and to clear down
    # proxy_options after call.

    def call args = []
      object = @when_called[0]
      meth = @when_called[1] || :call
      options = proxy_option_struct
      case object
      when Proc  ; object.call(args, options)
      when Class ; meth != :call ? object.new.send(meth, args, options) : object.new(args, options)
      else         object.send(meth, args, options) if object
      end
      @proxy_options = []
    end

  end
end
