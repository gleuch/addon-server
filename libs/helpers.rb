helpers do
  def dev?; (Sinatra::Application.environment.to_s != 'production'); end

  def download_logger; DOWNLOAD_LOGGER; end # Download logging

  def track_download(addon = @addon, version = @version)
    str = []
    str << "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}]"
    str << @addon.id
    str << @version.id
    str << request.env['REMOTE_ADDR']

    download_logger.info( str.join("\t") )
  rescue
  end


  def partial(name, options = {})
    item_name, counter_name = name.to_sym, "#{name}_counter".to_sym
    options = {:cache => true, :cache_expiry => 300}.merge(options)

    if collection = options.delete(:collection)
      collection.enum_for(:each_with_index).collect{|item, index| partial(name, options.merge(:locals => { item_name => item, counter_name => index + 1 }))}.join
    elsif object = options.delete(:object)
      partial(name, options.merge(:locals => {item_name => object, counter_name => nil}))
    else
      path, file = name.gsub(/^(.*\/)([A-Z0-9_\-\.]+)$/i, '\1'), name.gsub(/^(.*\/)([A-Z0-9_\-\.]+)$/i, '\2')
      # unless options[:cache].blank?
      #   cache "_#{name}", :expiry => (options[:cache_expiry].blank? ? 300 : options[:cache_expiry]), :compress => false do
      #     haml "_#{name}".to_sym, options.merge(:layout => false)
      #   end
      # else
        haml "#{path}_#{file}".to_sym, options.merge(:layout => false)
      # end
    end
  end

  # Modified from Rails ActiveSupport::CoreExtensions::Array::Grouping
  def in_groups_of(item, number, fill_with = nil)
    if fill_with == false
      collection = item
    else
      padding = (number - item.size % number) % number
      collection = item.dup.concat([fill_with] * padding)
    end

    if block_given?
      collection.each_slice(number) { |slice| yield(slice) }
    else
      returning [] do |groups|
        collection.each_slice(number) { |group| groups << group }
      end
    end
  end

  def flash; @_flash ||= {}; end

  def redirect(uri, *args)
    session[:_flash] = flash unless flash.empty?
    status 302
    response['Location'] = uri
    halt(*args)
  end


  def browser_whitelist(browser = nil)
    raise NotFound, "The add-on server does not support the browser you requested (#{browser || '?'})." if browser.blank? || !BROWSERS.include?(browser.downcase)
  end


  # FIREFOX helpers
  # ---------------------------------

  # Min Firefox version
  def firefox_min_browser(vers = nil)
    !vers.blank? ? vers : '1.5'
  end
  # Max Firefox version
  def firefox_max_browser(vers = nil)
    !vers.blank? ? vers : '4.0b2'
  end



  def check_login_or_api_key(slug, key = false)
    @addon = Addon.first(:slug => params[:slug]) rescue nil
    raise MissingInfo, "Add-on could not be found." if @addon.blank?
    return true if !key.blank? && key == @addon.api_key
    login_required # Otherwise...
  end


  def get_browser_by_user_agent
    ua = request.env['HTTP_USER_AGENT']
    return 'camino' if ua =~ /Camino/
    return 'firefox' if ua =~ /Firefox/
    return 'chrome' if ua =~ /Chrome/
    return 'safari' if ua =~ /AppleWebKit/
    return 'opera' if ua =~ /Opera/
    return 'ie' if ua =~ /MSIE/
    return nil
  end


  def browser_display_title(browser)
    return case browser
      when 'firefox'; 'Firefox'
      when 'chrome'; 'Chrome'
      when 'safari'; 'Safari'
      when 'camino'; 'Camino'
      when 'opera'; 'Opera'
      when 'ie'; 'Internet Explorer'
      else; 'Unknown'
    end
  end


  def display_browser_downloads(addon)
    ua, browsers, str = get_browser_by_user_agent, addon.browsers, ''

    latest_version = addon.versions.first(:order => [:version.desc]).version rescue nil
    return if latest_version.blank?

    has_version = addon.versions.first(:version => latest_version, :browser => ua) rescue nil

    str << "<section class='version browser featured #{ua}'>"
    if browsers.include?(ua) && !has_version.blank?
      str << "<h6><a href='/#{addon.slug}/downloads/#{has_version.browser}'>Download Now</a></h6>"
      str << "<p>Version #{has_version.version}</p>"
    else
      str << "<p>The latest version is not available for your browser (#{browser_display_title(ua)}).</p>"
    end
    str << "</section>"

    other_versions = addon.versions.all(:version => latest_version, :browser.not => ua, :order => [:browser.asc]) rescue nil
    unless other_versions.blank?
      str << "<section class='version browser all'>"
      str << "Also available for:"
      str << "<dl class='c'>"
      other_versions.each{|version| str << "<dd class='#{version.browser} download left'><a href='/#{addon.slug}/downloads/#{version.browser}'>#{browser_display_title(version.browser)}</a></dd>"}
      str << "</dl>"
      str << "</section>"
    end

    str
  end
end