SETTINGS = YAML::load(
  ERB.new(
    File.read(
      File.join(File.dirname(__FILE__), '..', 'settings.yml')
    )
  ).result
)[Rails.env]



::AppConfig = ApplicationConfiguration.new("#{Rails.root}/config/app_config.yml",
                                           "#{Rails.root}/config/app_config/#{Rails.env}.yml")
