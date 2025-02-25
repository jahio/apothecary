require "kemal"
require "db"
require "pg"
require "jennifer"
require "jwt"
require "dotenv"
require "yaml"
require "./config/*"
require "./models/*"
require "./controllers/*"
require "./middleware/*"
require "./utils/*"

module PharmacyInventoryAPI
  VERSION = "0.1.0"

  # Load environment variables
  Dotenv.load

  # Initialize database with UUID support
  Config.setup_database

  # Configure middleware
  before_all do |env|
    env.response.content_type = "application/json"
  end

  # Add CORS headers
  before_all do |env|
    env.response.headers["Access-Control-Allow-Origin"] = ENV["ALLOWED_ORIGINS"]? || "*"
    env.response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, PATCH, DELETE, OPTIONS"
    env.response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization, X-Requested-With"
  end

  # Handle OPTIONS requests for CORS
  options "/*" do |env|
    env.response.status_code = 204
    env.response.close
  end

  # Add scheduler for refreshing materialized views
  spawn do
    loop do
      begin
        # Refresh materialized views every hour
        Config.refresh_materialized_views
      rescue e
        Logger.error("Error refreshing materialized views: #{e.message}")
      end
      sleep 1.hour
    end
  end

  # Auth routes
  post "/api/auth/register" do |env|
    AuthController.register(env)
  end

  post "/api/auth/login" do |env|
    AuthController.login(env)
  end

  # Pharmacy API routes - protected by JWT
  get "/api/pharmacies" do |env|
    AuthMiddleware.authenticate(env)
    SearchController.list_pharmacies(env)
  end

  # Event routes - require pharmacy API key
  post "/api/events/receipt" do |env|
    AuthMiddleware.authenticate(env)
    EventController.record_receipt(env)
  end

  post "/api/events/reserve" do |env|
    AuthMiddleware.authenticate(env)
    EventController.record_reservation(env)
  end

  post "/api/events/pickup" do |env|
    AuthMiddleware.authenticate(env)
    EventController.record_pickup(env)
  end

  # Search routes - public
  get "/api/medications" do |env|
    SearchController.list_medications(env)
  end

  get "/api/medications/:id" do |env|
    SearchController.get_medication(env)
  end

  get "/api/search" do |env|
    SearchController.search_availability(env)
  end

  # System maintenance routes - admin only
  post "/api/system/refresh-views" do |env|
    AuthMiddleware.admin_only(env)
    Config.refresh_materialized_views
    {"success": true, "message": "Materialized views refreshed"}.to_json
  end

  # Error handling
  error 400 do |env|
    env.response.content_type = "application/json"
    {"error": "Bad request", "message": env.response.status_message}.to_json
  end

  error 401 do |env|
    env.response.content_type = "application/json"
    {"error": "Unauthorized", "message": "Authentication required"}.to_json
  end

  error 403 do |env|
    env.response.content_type = "application/json"
    {"error": "Forbidden", "message": "You don't have permission to access this resource"}.to_json
  end

  error 404 do |env|
    env.response.content_type = "application/json"
    {"error": "Not Found", "message": "The requested resource could not be found"}.to_json
  end

  error 500 do |env|
    env.response.content_type = "application/json"
    {"error": "Internal Server Error", "message": "Something went wrong"}.to_json
  end

  # Start server
  server_port = ENV["PORT"]?.try(&.to_i) || 3000
  server_host = ENV["HOST"]? || "0.0.0.0"
  
  Logger.info("Starting server at http://#{server_host}:#{server_port}")
  Kemal.run(server_port)
end