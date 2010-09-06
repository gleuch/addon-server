# List all add-ons
get '/addons' do
  @addons = Addon.all(:available => true, :order => [:updated_at.desc]) rescue nil
end

# List all known downloads for add-on
get '/:slug/downloads' do
  # Check if exists
  @addon = Addon.available.first(:slug => params[:slug]) rescue nil
  raise MissingInfo, "Add-on information could not be found." if @addon.blank?
end


# Generate browser update manifest for add-on
get '/:slug/updates/:browser/info' do
  browser_whitelist(params[:browser])

  # Check if exists
  @addon = Addon.available.first(:slug => params[:slug]) rescue nil
  raise MissingInfo, "Add-on information could not be found." if @addon.blank?

  @versions = @addon.versions.available.all(:browser => params[:browser]) rescue nil
  raise MissingInfo, "Version information for #{@addon.name} for #{params[:browser].capitalize} could not be found." if @versions.blank?

  # view = "info.#{params[:browser]}".to_sym
  view = "info.browser".to_sym
  haml view, :layout => false
end

# Generate browser update manifest for add-on
get '/:slug/updates/:browser' do
  browser_whitelist(params[:browser])

  # Check if exists
  @addon = Addon.available.first(:slug => params[:slug]) rescue nil
  raise MissingInfo, "Add-on information could not be found." if @addon.blank?

  @versions = @addon.versions.available.all(:browser => params[:browser]) rescue nil
  raise MissingInfo, "Version information for #{@addon.name} for #{params[:browser].capitalize} could not be found." if @versions.blank?

  view = "update.#{params[:browser]}".to_sym
  headers('Content-type' => 'text/xml;charset=utf-8') if %w(firefox chrome).include?(params[:browser])
  haml view, :layout => false
end


# Redirect to the URL for the download link for this browser add-on
get '/:slug/downloads/:browser' do
  browser_whitelist(params[:browser])

  # Check if exists
  @addon = Addon.available.first(:slug => params[:slug]) rescue nil
  raise MissingInfo, "Add-on information could not be found." if @addon.blank?
  
  unless params[:version].blank?
    @version = @addon.versions.available.first(:browser => params[:browser], :version => params[:version]) rescue nil
  else
    @version = @addon.versions.available.first(:browser => params[:browser]) rescue nil
  end

  raise MissingInfo, "Version information for #{@addon.name} could not be found." if @version.blank?
  raise MissingInfo, "Download link for #{@addon.name}, version #{@version.version} for #{params[:browser].capitalize} is not specified." if @version.url_download.blank?

  track_download(@addon, @version) # Add to download logger
  redirect @version.url_download, :status => 307 # Is this right code?
end


# Show info for add-on
get '/:slug' do
  pass if %w(login logout signup).include?(params[:slug]) || params[:slug].blank? # Ugh..
  # pass if %w(login logout signup latest popular featured).include?(params[:slug]) || params[:slug].blank? # Ugh..

  # Check if exists
  @addon = Addon.available.first(:slug => params[:slug]) rescue nil
  raise MissingInfo, "Add-on information could not be found." if @addon.blank?
end

get '/' do
  @addons = Addon.all(:available => true, :order => [:updated_at.desc]) rescue nil
  haml :index
end