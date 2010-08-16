helpers do
  def dev?; (Sinatra::Application.environment.to_s != 'production'); end

  def download_logger; DOWNLOAD_LOGGER; end # Download logging

  def track_download(addon = @addon, version = @version)
    str = []
    str << "[#{Time.now.to_s}]"
    str << @addon.id
    str << @version.browser
    str << @version.version
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
    !vers.blank? ? vers : '4.0.0.*'
  end

end