#
#
#
#
# -------------------------------------------
#



get '/developer' do
  login_required
  @addons = Addon.all(:user_id => current_user.id) rescue nil
  haml :'developer/index'
end


get '/developer/new' do
  login_required

  @addon = Addon.new
  haml :'developer/edit'
end

post '/developer/create' do
  @addon = Addon.new
  @addon.attributes = params[:addon].reject{|k,v| !Addon::ATTR_EDITABLE.include?(k.to_s)}

  @addon.slug = @addon.name.sluggerize
  @addon.api_key = Digest::SHA1.hexdigest(@addon.name)

  if @addon.save
    redirect '/' and return
  else
    haml :'developer/edit'
  end
end

get '/developer/:slug/edit' do
  @addon = Addon.first(:slug => params[:slug], :user_id => current_user.id) rescue nil
  raise MissingInfo, "Add-on could not be found." if @addon.blank?
  haml :'developer/edit'
end

post '/developer/:slug/update' do
  @addon = Addon.first(:slug => params[:slug], :user_id => current_user.id) rescue nil
  raise MissingInfo, "Add-on could not be found." if @addon.blank?

  # Cautious to ensure they don't override other opts.
  @addon.attributes = params[:addon].reject{|k,v| !Addon::ATTR_EDITABLE.include?(k.to_s)}

  if @addon.save
    redirect '/' and return
  else
    haml :'developer/edit'
  end
end

# Addons
get '/developer/:slug' do
  login_required

  @addon = Addon.first(:slug => params[:slug], :user_id => current_user.id) rescue nil
  raise MissingInfo, "Add-on could not be found." if @addon.blank?
  @versions = @addon.versions.all(:order => [:version.desc, :browser.asc]) rescue nil

  haml :'developer/show'
end



# Addon versions

get '/developer/:slug/version/new' do
  check_login_or_api_key(params[:slug], params[:auth_key])

end

post '/developer/:slug/version/create' do
  check_login_or_api_key(params[:slug], params[:auth_key])

end

get '/developer/:slug/version/:version/edit' do
  check_login_or_api_key(params[:slug], params[:auth_key])

end

post '/developer/:slug/version/:version/update' do
  check_login_or_api_key(params[:slug], params[:auth_key])

end





# Admin options

get '/admin' do
end

get '/admin/:slug/approve' do
end

get '/admin/:slug/remove' do
end

get '/admin/:slug/feature' do
end





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
  redirect @version.url_download, :status => 307
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