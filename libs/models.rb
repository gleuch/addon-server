class Addon
  include DataMapper::Resource

  property  :id,              Serial
  property  :name,            String
  property  :slug,            String
  property  :description,     Text
  property  :authors,         String
  property  :website,         String
  property  :download_count,  Integer
  property  :firefox_app_id,  String,         :length => 128
  property  :chrome_app_id,   String,         :length => 128
  property  :available,       Boolean
  property  :created_at,      DateTime
  property  :updated_at,      DateTime


  has n,  :versions,    :model => 'AddonVersion',   :order => [:version.desc]
  has n,  :downloads,   :model => 'AddonDownload',  :order => [:download_date.desc]
end

class AddonVersion
  include DataMapper::Resource

  property  :id,              Serial
  property  :addon_id,        Integer
  property  :browser,         String
  property  :version,         String
  property  :notes,           Text
  property  :url_download,    String
  property  :min_browser_version, String
  property  :max_browser_version, String
  property  :download_count,  Integer,        :default => 0
  property  :available,       Boolean
  property  :created_at,      DateTime
  property  :updated_at,      DateTime

  belongs_to :addon
  has n,  :downloads,   :model => 'AddonDownload',  :order => [:download_date.desc]
end


class AddonDownload
  include DataMapper::Resource

  property  :id,                Serial
  property  :stat_hash,         String,       :length => 32
  property  :addon_id,          Integer
  property  :addon_version_id,  Integer
  property  :download_date,     Date
  property  :download_count,    Integer,      :default => 0
  property  :updated_at,        DateTime


  # belongs_to :addons
  # belongs_to :addon_versions
end