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