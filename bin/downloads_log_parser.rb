#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'


ROOT = File.expand_path("../#{File.dirname(__FILE__)}")

libs = %w(digest/sha1 configatron dm-core dm-timestamps dm-validations dm-ar-finders dm-aggregates dm-types sinatra-authentication ROOT/libs/models)
libs.each{|lib| require lib.gsub(/ROOT/, ROOT)}

configatron.configure_from_yaml("#{ROOT}/settings.yml", :hash => Sinatra::Application.environment.to_s)

DataMapper.setup(:default, configatron.db_connection.gsub(/ROOT/, ROOT))
DataMapper.auto_upgrade!


####################################################################################################


download_log_filename = "#{ROOT}/log/downloads.log"
tmp_download_log_filename = "#{ROOT}/log/downloads-#{Time.now.to_i.to_s.gsub(/\s/, '_').gsub(/\:/, '-')}.log"

STDERR.puts "\n\n[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] Starting downloads parsing & logging...\n\n"

# Move file so we're working fresh and cat null it...
STDERR.puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] Moving downloads log..."
`cp -f #{download_log_filename} #{tmp_download_log_filename} && cat /dev/null > #{download_log_filename}`
# `cp -f #{download_log_filename} #{tmp_download_log_filename}`
STDERR.puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] Move complete!\n\n"


@downloads, counter = {}, 0

begin
  STDERR.puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] Opening log file: #{tmp_download_log_filename}"

  file = File.open(tmp_download_log_filename, "r")

  STDERR.puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] Beginning parsing..."
  while (line = file.gets)
    begin
      # FORMAT:
      # I, [2010-08-23T00:47:26.729268 #52966]  INFO -- : [2010-08-23 00:47:26]	1	firefox	0.2	127.0.0.1

      next if line =~ /^\#/ # Start of log file or comment.

      snip = line.gsub(/^(.*\:\s)(.*)$/m, '\2').strip
      log = snip.strip.split("\t")

      date = log[0].gsub(/\[(.*)\s(.*)\]/, '\1') rescue ''
      time = log[0].gsub(/\[(.*)\s(.*)\]/, '\2') rescue ''
      addon_id = log[1] rescue ''
      version_id = log[2] rescue ''
      ip = log[3] rescue ''

      next if addon_id.blank? || version_id.blank?
      download_hash = Digest::SHA1.hexdigest("#{addon_id}::#{version_id}") # Unique string

      @downloads[addon_id] ||= {}
      @downloads[addon_id][date] ||= {}
      @downloads[addon_id][date][download_hash] ||= {:version => version_id, :ips => []}
      @downloads[addon_id][date][download_hash][:ips] << ip unless ip.blank?

      counter += 1
    rescue => err
      STDERR.puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] Error: could not parse: #{err}"
    end
  end
  file.close

  STDERR.puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] Parsing complete!"
  STDERR.puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] Parsed #{counter} download records.\n\n"

rescue => err
  STDERR.puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] Exception: #{err}"
end

# STDERR.puts @downloads.inspect
# STDERR.puts "\n\n"


unless @downloads.blank?
  STDERR.puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] Beginning logging..."
  @summaries, counter = {}, 0

  @downloads.each do |addon, days|
    ips = []

    days.each do |day, downloads|
      downloads.each do |hash, download|
        addon_daily_hash = Digest::SHA1.hexdigest("#{day}::#{addon}::#{download[:version]}") # salted by day
        downloads_count, uniqs_count = download[:ips].length, download[:ips].uniq.length

        stat = AddonDownload.first(:uuid => addon_daily_hash) rescue nil

        # TODO : Bulk insert new records!

        stat ||= AddonDownload.new(:uuid => addon_daily_hash, :addon_id => addon, :addon_version_id => download[:version], :download_type => 'daily', :download_date => day)
        stat.download_count += downloads_count
        stat.uniq_count += uniqs_count
        STDERR.puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] COULD NOT SAVE #{addon_daily_hash}!" unless stat.save

        @summaries[addon] ||= {}
        @summaries[addon][day] = {:ips => []}
        @summaries[addon][day][:ips] += download[:ips]

        counter += 1
      end
    end
  end

  STDERR.puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] Logging complete!"
  STDERR.puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] Logged #{counter} download records.\n\n"
else
  STDERR.puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] WARNING: No downloads to log."
end


# Remove tmp file...
`rm #{tmp_download_log_filename}`



exit 0