source 'https://rubygems.org'
ruby '1.9.3'

gem 'rails'                   , '3.2.11'

# views
gem 'jquery-rails'            , '~> 2.2.1'
gem 'haml-rails'              , '~> 0.4'
gem 'redcarpet'               , '~> 2.2.2'
gem 'simple_form'             , '~> 2.1.0'
gem 'remotipart'              , '~> 1.0'
gem 'will_paginate'           , '~> 3.0.4'
gem 'country-select'          , '~> 1.1.1'
gem 'impressionist'           , '~> 1.4.12'
gem 'rails-timeago'           , '~> 2.0'

# models
gem 'pg'                      , '~> 0.15.0'
gem 'bcrypt-ruby'             , '~> 3.0.0'
gem 'aasm'                    , '~> 3.0.16'
gem 'geocoder'                , '~> 1.1.6'
gem 'nest'                    , '~> 1.1.2'
gem 'chronic'                 , '~> 0.9.1'
gem 'active_model_serializers', '~> 0.7.0'

# auth
gem 'cancan'                  , '~> 1.6.9', require: false
gem 'omniauth-facebook'       , '~> 1.4.0'
gem 'omniauth-github'         , '~> 1.0.1'
gem 'omniauth-linkedin'       , '~> 0.1.0'
gem 'omniauth-eventbrite'     , '~> 0.0.3'
gem 'ruby-hmac'               , '~> 0.4.0'

# amazon storage
gem 'paperclip-aws'           , '~> 1.6.7'
gem 'aws-sdk'                 , '~> 1.8.5'  , :require => "aws/s3"


# API Clients
gem 'rest-client'             , '~> 1.6.7'
gem 'eventbrite-client'       , '~> 0.1.4'
gem 'km'                      , '~> 1.1.3'
gem 'airbrake'                , '~> 3.1.9'
gem 'intercom-rails'          , '~> 0.2.14'
gem 'twitter'                 , '~> 4.8.1'
gem 'instagram'               , '~> 0.10.0'
gem 'mandrill-api'            , '~> 1.0.49'


# administration
gem 'activeadmin'             , '~> 0.5.1'  , :git => "git://github.com/gregbell/active_admin.git"
gem 'paper_trail'             , '~> 2.7.1'

# app servers
gem 'unicorn'                 , '~> 4.6.2'
gem 'resque'                  , '~> 1.24.1'
gem 'resque-scheduler'        , '~> 2.2.0', :require => 'resque_scheduler'
gem 'sinatra'                 , '~> 1.3.6'
gem 'typhoeus'                , '~> 0.4.2', require: false
gem 'aws-ses'                 , '~> 0.6.0', :require => 'aws/ses'

# misc
gem 'newrelic_rpm'            , '~> 3.6.0'
gem "email_reply_parser"      , '~> 0.5.3'
gem "redis-rails"
gem "execjs"
gem 'foreman'                 , :require => false
gem 'rails_12factor'          , group: :production


# assets
group :assets do
  gem 'coffee-rails'
  gem 'uglifier'
  gem 'handlebars_assets'
  gem "font-awesome-rails"
  gem 'sass-rails'
  gem 'compass-rails'
  gem 'zurb-foundation', '3.2.5'
  gem 'asset_sync'
  gem 'haml_coffee_assets'
end

group :development, :test do
  gem 'rails3-generators'
  gem "factory_girl_rails" , "~> 4.0"   , :require => false
  gem "hpricot"
  gem 'debugger'
  gem "ruby-prof"
  gem "pry"
  gem 'spork-rails'
  gem 'rspec-rails'      , "~> 2.13"
  gem 'database_cleaner'
  gem 'timecop'
  gem "faker"
  gem 'email_spec'
end

group :development do
  gem "bullet"
  gem "better_errors"
  gem "binding_of_caller"
  gem 'annotate'          , ">=2.5.0"
  gem 'foreman'           , :require => false
  gem 'meta_request'
  gem 'pry-rails'
  gem 'quiet_assets'
  gem 'unicorn-rails'
  gem "letter_opener"
  # gem 'rails-footnotes', '>= 3.7.9'
end

# Gems extracted from data_mapper dependencies
gem 'fastercsv'           , '~> 1.5'
# TODO: check if any is in use
gem 'addressable'         , '~> 2.2.6'
gem 'json'                , '~> 1.6'
gem 'json_pure'           , '~> 1.6'
gem 'multi_json'          , '~> 1.0'
gem 'stringex'            , '~> 1.4'

# TODO: Remove below gems after testing
gem 'reverse_markdown'    , require: false
gem 'ui_datepicker-rails3'
gem 'active_attr'         , '~> 0.7.0'
gem 'redis-namespace'     , '~> 1.2.1'
gem 'sanitize'            , require: false
