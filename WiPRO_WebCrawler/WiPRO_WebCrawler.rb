#!/usr/bin/env ruby
# TAJaroszewski
# frozen_string_literal: true

require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'optparse'
require 'json'
require 'uri'
require 'uri/http'

# ToDo:
# Links depth (currently one)
# debug mode
# other statics?
# different abstraction
# threads

@spider_list = Hash.new {|h,k| h[k]=[]}
@spider_images_list = Hash.new {|h,k| h[k]=[]}
@spider_images = []
@spider_local_table = []
@spider_depth = 0
@output_file = "./crawler.json"
@output_file_images = "./crawler_images.json"
options = {}
options[:duplicates] = 1

IMAGE_REGEX = '/\.jpeg|\.jpg|\.bmp|\.gif|\.png|\.svn/'
USER_AGENT = "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0"

OptionParser.new do |opts|
  opts.banner = 'Usage: WiPRO_WebCrawler.rb [options]'

  opts.on('-n', '--name NAME', 'Site name; eg. wiprodigital.com') { |v| options[:site_name] = v }
  opts.on('-d', '--duplicats', 'Don\'t show duplicates in output') { |v| options[:duplicates] = 0 }
end.parse!

BASE_DOMAIN = options[:site_name]

url = "http://#{BASE_DOMAIN}" unless BASE_DOMAIN.start_with?('http')
uri = URI.parse(url)
base_site_url = uri.host.downcase
base_site_url = base_site_url.start_with?('www.') ? base_site_url[4..-1] : base_site_url
base_site_url = "http://#{base_site_url}"

def page_links(site_url)
	@spider_depth = 0
	
	if @spider_depth <= 3

		begin

			mechanize = Mechanize.new
			mechanize.user_agent = USER_AGENT
			page = mechanize.get(site_url)
			@spider_local_table = []
			@spider_local_images = []

			page.links_with(href: /^http?.*#{BASE_DOMAIN}?.*/).each do |link|
	  			@spider_local_table << link.href.sub(/\/$/, '')
	  		end

	  	  	page.images_with(:src => /#{IMAGE_REGEX}/).each do |image|
	  			@spider_local_images << image.url.to_s
	  		end

	  		@spider_depth += 1

	  	rescue
	  		p "Error with #{site_url}"
	  		nil
	  	end

  	end

  	# Remove duplicates from array and write it array
  	@spider_list[site_url] << @spider_local_table.uniq unless @spider_local_table.empty?
  	@spider_images_list[site_url] << @spider_local_images unless @spider_local_images.empty?

end

def save_output(list, file)

	File.delete(file) if File.exist?(file)
	
	begin
		File.open(file,"w+") do |f|
	  		f.write(list.to_json)
		end
	rescue
		retry
	end
end

page_links(base_site_url)

crawler_list = @spider_list.uniq

crawler_list.each do |key, value|

	value[0].uniq.each do |site|
		p "Checking #{site}"

		crawl_site = URI(site)
		s = page_links(crawl_site)
	end

end

#sh: cat crawler_images.json | jq .
#sh: cat crawler.json | jq .

save_output(@spider_list, @output_file)
save_output(@spider_images_list, @output_file_images)

#print @spider_list.to_json
#print @spider_images_list.to_json

