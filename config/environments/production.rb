# frozen_string_literal: true

Sufia::Engine.configure do
  config.logout_url = "https://webaccess.psu.edu/cgi-bin/logout?#{Rails.application.config.virtual_host}"
  config.login_url = "https://webaccess.psu.edu/?cosign-#{Rails.application.config.service_instance}&#{Rails.application.config.virtual_host}dashboard"
end

ScholarSphere::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # set up resque in production only
  config.active_job.queue_adapter = :resque

  # Set cookies as secure, force all connections over SSL
  config.force_ssl = true

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both thread web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = 'X-Sendfile'

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  config.log_level = :warn

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_files = false

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Choose the compressors to use
  # config.assets.js_compressor  = :uglifier
  # config.assets.css_compressor = :yui

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs.
  config.assets.digest = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  config.assets.precompile += %w(generic_files.js dashboard.js video.js audio.min.js jquery.zclip.min.js ZeroClipboard.swf bootstrap-tooltip.js bootstrap-popover.js video-js.css generic_files.css jquery-ui-1.8.1.custom.css jquery-ui-1.8.23.custom.css bootstrap.min.css batch.js reset_body.css scholarsphere-bootstrap.css bootstrap-modal.js jquery.validate.js swfobject.js ie8-and-down.css ie9-and-down.css)
  config.assets.precompile += %w(*.jpg *.png *.gif *.ico *.svg)
end
