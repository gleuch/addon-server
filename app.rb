require 'rubygems'
require 'sinatra'

# Configure! ---------------------------------------

libs = %w(haml configatron logger dm-core dm-timestamps dm-validations dm-ar-finders dm-aggregates dm-types libs/models libs/actions libs/helpers libs/libs)
libs << 'sinatra-authentication'
libs.each{|lib| require lib}

configure do |config|
  ROOT = File.expand_path(File.dirname(__FILE__))

  BROWSERS = %w(chrome firefox safari)

  configatron.configure_from_yaml("#{ROOT}/settings.yml", :hash => Sinatra::Application.environment.to_s)

  DataMapper.setup(:default, configatron.db_connection.gsub(/ROOT/, ROOT))
  DataMapper.auto_upgrade!

  DOWNLOAD_LOGGER = Logger.new("log/downloads.log") # Downloads log

  MissingInfo = Class.new(StandardError) 
end



before do
  @_flash, session[:_flash] = session[:_flash], nil if session[:_flash]
end



# 404 (file not found) errors
not_found do
  @error ||= 'Sorry, but the page you were looking for could not be found.'
  haml :fail, :status => 404
end
error MissingInfo do
  @error ||= request.env['sinatra.error'].message
  @error ||= 'Sorry, but the add-on you were looking for could not be found.'
  haml :fail, :status => 404
end

# 500 (unspecific) errors
error do
  @error ||= request.env['sinatra.error'].message
  @error ||= "You have encountered an undocumented error."
  haml :fail, :status => 500
end








configure :development do
  # set :raise_errors, Proc.new { false }
  # set :show_exceptions, false

  class Sinatra::Reloader < Rack::Reloader
     def safe_load(file, mtime, stderr = $stderr)
       if file == __FILE__
         ::Sinatra::Application.reset!
         stderr.puts "#{self.class}: reseting routes"
       end
       super
     end
  end 
  use Sinatra::Reloader
end
