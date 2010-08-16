#
#
#
#
# -------------------------------------------
#


# List all add-ons
get '/addons' do
  @addons = Addon.all(:available => true, :order => [:updated_at.desc]) rescue nil
end

# Show info for add-on
get '/:slug' do
  # Check if exists
  @addon = Addon.first(:slug => params[:slug], :available => true) rescue nil
  raise MissingInfo, "Add-on information could not be found." if @addon.blank?
end


# List all known downloads for add-on
get '/:slug/downloads' do
  # Check if exists
  @addon = Addon.first(:slug => params[:slug], :available => true) rescue nil
  raise MissingInfo, "Add-on information could not be found." if @addon.blank?
end


# Generate browser update manifest for add-on
get '/:slug/updates/:browser' do
  browser_whitelist(params[:browser])

  # Check if exists
  @addon = Addon.first(:slug => params[:slug], :available => true) rescue nil
  raise MissingInfo, "Add-on information could not be found." if @addon.blank?

  @versions = @addon.versions.all(:browser => params[:browser], :available => true) rescue nil
  raise MissingInfo, "Version information for #{@addon.name} for #{params[:browser].capitalize} could not be found." if @versions.blank?

  view = "update.#{params[:browser]}".to_sym
  haml view, :layout => false
end


# Redirect to the URL for the download link for this browser add-on
get '/:slug/downloads/:browser' do
  browser_whitelist(params[:browser])

  # Check if exists
  @addon = Addon.first(:slug => params[:slug], :available => true) rescue nil
  raise MissingInfo, "Add-on information could not be found." if @addon.blank?

  unless params[:version].blank?
    @version = @addon.versions.first(:browser => params[:browser], :version => params[:version], :available => true) rescue nil
  else
    @version = @addon.versions.first(:browser => params[:browser], :available => true) rescue nil
  end

  raise MissingInfo, "Version information for #{@addon.name} could not be found." if @version.blank?
  # raise MissingInfo, "Download link for #{@addon.name}, version #{@version.version} for #{params[:browser].capitalize} is not specified." if @version.download_url.blank?

  track_download(@addon, @version) # Add to download logger
  halt
  redirect @version.download_url, :status => 307
end





get '/admin' do
end


# Addons

get '/admin/new' do
end

post '/admin/create' do
end

get '/admin/:slug/edit' do
  @addon = Addon.first(:slug => params[:slug]) rescue nil
  raise MissingInfo, "Add-on could not be found." if @addon.blank?
end

post '/admin/:slug/update' do
  @addon = Addon.first(:slug => params[:slug]) rescue nil
  raise MissingInfo, "Add-on could not be found." if @addon.blank?
end


# Addon versions

get '/admin/:slug/version/new' do
  @addon = Addon.first(:slug => params[:slug]) rescue nil
  raise MissingInfo, "Add-on could not be found." if @addon.blank?
end

post '/admin/:slug/version/create' do
  @addon = Addon.first(:slug => params[:slug]) rescue nil
  raise MissingInfo, "Add-on could not be found." if @addon.blank?
end

get '/admin/:slug/version/:version/edit' do
  @addon = Addon.first(:slug => params[:slug]) rescue nil
  raise MissingInfo, "Add-on could not be found." if @addon.blank?
end

post '/admin/:slug/version/:version/update' do
  @addon = Addon.first(:slug => params[:slug]) rescue nil
  raise MissingInfo, "Add-on could not be found." if @addon.blank?
end