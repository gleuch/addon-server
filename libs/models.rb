class Addon
  include DataMapper::Resource

  ATTR_EDITABLE = [:name, :description, :authors, :website, :firefox_app_id, :chrome_app_id, :safari_app_id, :available]


  property  :id,              Serial
  property  :user_id,         Integer
  property  :name,            String
  property  :slug,            String,         :length => 64
  property  :description,     Text
  property  :authors,         String,         :length => 256
  property  :website,         String,         :length => 256
  property  :download_count,  Integer
  property  :firefox_app_id,  String,         :length => 256
  property  :chrome_app_id,   String,         :length => 256
  property  :safari_app_id,   String,         :length => 256
  property  :safari_dev_id,   String,         :length => 16
  property  :api_key,         String,         :length => 64
  property  :available,       Boolean
  property  :created_at,      DateTime
  property  :updated_at,      DateTime


  def self.available; all(:available => true); end

  # These are temp if called in public views. Logger should incremenet the download counter on this table.
  def downloads_count; AddonDownload.sum(:download_count, :addon_id => self.id).to_i rescue 0; end
  def unique_download_count; AddonDownload.sum(:unique_count, :addon_id => self.id).to_i rescue 0; end

  def browsers
    self.versions.map{|addon| addon.browser}.compact.uniq
  end


  belongs_to  :user,    :model => 'DmUser'
  has n,  :versions,    :model => 'AddonVersion',   :order => [:version.desc]
  has n,  :downloads,   :model => 'AddonDownload',  :order => [:download_date.desc]
end

class AddonVersion
  include DataMapper::Resource

  ATTR_EDITABLE = [:browser, :version, :notes, :url_download, :min_browser_version, :max_browser_version, :available]


  property  :id,              Serial
  property  :addon_id,        Integer
  property  :browser,         String
  property  :version,         String
  property  :bundle,          String
  property  :notes,           Text
  property  :url_download,    String,         :length => 256
  property  :min_browser_version, String
  property  :max_browser_version, String
  property  :download_count,  Integer,        :default => 0
  property  :available,       Boolean
  property  :created_at,      DateTime
  property  :updated_at,      DateTime


  def self.available; all(:available => true); end


  belongs_to :addon
  has n,  :downloads,   :model => 'AddonDownload',  :order => [:download_date.desc]
end


class AddonDownload
  include DataMapper::Resource

  property  :id,                Serial
  property  :download_type,     String
  property  :uuid,              String,       :length => 64
  property  :addon_id,          Integer
  property  :addon_version_id,  Integer
  property  :download_date,     Date
  property  :download_count,    Integer,      :default => 0
  property  :uniq_count,        Integer,      :default => 0
  property  :updated_at,        DateTime


  # belongs_to :addons
  # belongs_to :addon_versions
end