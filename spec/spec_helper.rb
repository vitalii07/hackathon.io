require 'rubygems'
require 'spork'
#require 'spork/ext/ruby-debug' # comment to disable debugger

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  require File.dirname(__FILE__) + '/../config/environment'
  require 'rspec/rails'
  require 'factory_girl_rails'

  Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

  RSpec.configure do |config|
    config.fixture_path                               = "#{::Rails.root}/spec/fixtures"
    config.use_transactional_fixtures                 = false
    config.infer_base_class_for_anonymous_controllers = false
    config.order                                      = "random"

    config.include MailerMacros
    config.include FactoryGirl::Syntax::Methods
    config.extend  Controllers::Macros         , :type => :controller
    config.include Controllers::SessionHelpers , :type => :controller
    config.include AuthHelpers                 , :type => :controller

    config.before(:suite) do
      DatabaseCleaner.clean_with(:truncation)
    end

    config.before(:each) do
      DatabaseCleaner.strategy = :transaction
      reset_email
    end

    config.before(:each) do
      DatabaseCleaner.start
    end

    config.after(:each) do
      DatabaseCleaner.clean
    end
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.
  # paths =  Dir[Rails.root.join("spec/support/**/*.rb")]
  paths = Dir[Rails.root + "app/**/*.rb"]
  paths += Dir[Rails.root + "lib/**/*.rb"]
  paths.uniq.each { |f| load f }

  # require 'factory_girl'
  # FactoryGirl.definition_file_paths = [ File.join(Rails.root, 'spec', 'factories') ]
  # FactoryGirl.find_definitions
end
