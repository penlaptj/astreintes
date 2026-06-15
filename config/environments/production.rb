require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings.
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Store uploaded files on the local file system.
  config.active_storage.service = :local

  # Reverse proxy SSL termination + HSTS.
  config.assume_ssl = true
  config.force_ssl  = true

  # Skip http-to-https redirect for the default health check endpoint.
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Jobs en arrière-plan via Solid Queue (base "queue" dédiée). Traités par le
  # service `worker` (docker-compose) ou par Puma si SOLID_QUEUE_IN_PUMA=true.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # Enable locale fallbacks for I18n.
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Hôtes autorisés (protection contre l'injection d'en-tête Host).
  # APP_HOST peut être une liste séparée par des virgules :
  #   APP_HOST=astreintes.unova.fr,www.astreintes.unova.fr
  app_hosts = ENV.fetch("APP_HOST", "").split(",").map(&:strip).reject(&:empty?)
  config.hosts = app_hosts if app_hosts.any?

  # On laisse passer le health check sans contrôle d'hôte (pour les load balancers).
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # SMTP
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV.fetch("MAILER_HOST", "mail"),
    port:    ENV.fetch("MAILER_PORT", 1025).to_i
  }
  config.action_mailer.default_url_options = {
    host:     ENV.fetch("APP_HOST", "localhost").split(",").first.strip,
    protocol: "https"
  }
end
