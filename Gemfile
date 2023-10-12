source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

ruby "3.2.2"
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0', '>= 7.0.8'
# Use Puma as the app server
gem 'puma', '~> 5.6'
gem 'puma-daemon', require: false
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
end

group :test do
  gem 'simplecov', require: false
  gem "webmock"
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.8'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  # Use sqlite3 as the database for Active Record
  gem 'sqlite3', '~> 1.6.6'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'blacklight', '~> 7.34'
group :development, :test do
  gem 'solr_wrapper', '>= 0.3'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'coveralls', require: false
  #gem 'travis', '~> 1.11', '>= 1.11.1'
end

gem 'rsolr', '>= 2.0'
gem 'jquery-rails'
gem 'devise'
gem 'devise-guests', '~> 0.6'
#gem 'blacklight-marc', '~> 6.1'

group :test, :production do
  gem 'pg'
end

group :development do
  #gem 'mysql2', '~> 0.4.10'
  gem 'mysql2', '~> 0.5.3'
end

# bundle exec rake doc:rails generates the API under doc/api.
#gem 'sdoc', '~> 0.4.0', group: :doc
gem 'sdoc', '~> 1.1' #update dependency for json 2.3.1 (below)

gem 'blacklight-gallery', '~> 4.4'

gem 'marc'

gem 'blacklight_range_limit', '~> 7.9', '>= 7.9.1'

gem 'rails_12factor', group: :production

#gem 'nokogiri', '~> 1.10.8'
gem "nokogiri", ">= 1.11.0"

gem 'bourbon'

gem 'newrelic_rpm'

gem "rack", ">= 2.2.3"

gem "json", ">= 2.3.0"

#gem "webpacker", "~> 5.3.0" #removed 8/2/2022

gem "rack-timeout"

gem "addressable", ">= 2.8.0"

gem 'bootstrap', '~> 4.0'
