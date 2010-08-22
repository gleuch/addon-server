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
  pass if %w(login logout signup).include?(params[:slug])

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





get '/developer' do
  login_required
  @addons = Addon.all(:user_id => current_user.id) rescue nil
  haml :'developer/index'
end


# Addons

get '/developer/new' do
  login_required

  @addon = Addon.new
  haml :'developer/edit'
end

post '/developer/create' do
  @addon = Addon.new
  @addon.attributes = params[:addon].reject{|k,v| !Addon::ATTR_EDITABLE.include?(k.to_s)}

  @addon.slug = @addon.title.sluggerize
  @addon.api_key = Digest::SHA1.hexdigest(@addon.title)

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