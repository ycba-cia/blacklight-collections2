require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BlacklightCollections2
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.serve_static_assets = true

    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'local_env.yml')
      YAML.load(File.open(env_file)).each do |key, value|
        ENV[key.to_s] = value
      end if File.exist?(env_file)
    end

    #config.assets.paths << Rails.root.join("app", "assets", "fonts")

    #ERJ per: https://guides.rubyonrails.org/v4.0/asset_pipeline.html
    #
    #config.assets.initialize_on_precompile = false
    #
    #Rails.application.config.active_record.sqlite3.represent_boolean_as_integer = true
    #
    config.active_record.legacy_connection_handling = false

    #Rails.autoloaders.log! #Used as ruby3 upgrade diagnostic

  end
end
