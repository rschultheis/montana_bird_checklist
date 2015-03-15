require 'curb'
require 'nokogiri'
require 'fileutils'

require_relative 'constants'


module BirdChecklist
  module Scraper

    include Locations

    # return a Nokogiri::HTML doc ready for xpath queries
    # cache for efficiency
    def get_html_page url, use_cache=true
      cache_file = File.join html_cache_dir, "#{url.gsub(/\W+/,'_')}.cached_html"
      html = if use_cache and File.exist? cache_file
        IO.read cache_file
      else
        puts "Getting: #{url}"
        response = Curl.get(url)
        puts "Reponse code: #{response.status}"
        html = response.body_str
        File.open(cache_file, 'w') {|f| f.write html}
        html
      end
      html
    end

    def aab_slug bird_common_name
      bird_common_name.gsub(/\s+/,'_').gsub("'",'').downcase
    end

    # turn a birds common name into a url to the all about birds page
    def make_aab_url bird_common_name
      "http://www.allaboutbirds.org/guide/#{aab_slug(bird_common_name)}/id"
    end

    def get_web_image url, use_cache=true
      cache_file = File.join image_cache_dir, url.gsub(/\W+/,'_').sub(/_([^_]+)$/, '.\1')
      img = if use_cache and File.exist? cache_file
              cache_file
            else
              begin
                %x|wget -O #{cache_file} #{url}|
                cache_file
              rescue Exception => e
                puts "ERROR: #{e.to_s}"
                nil
              end
            end

    end

    private

    def html_cache_dir
      @html_cache_dir_made ||= begin
                           FileUtils.mkdir_p HtmlPageCacheDir
                           HtmlPageCacheDir
                         end
      @html_cache_dir_made
    end

    def image_cache_dir
      @image_cache_dir_made ||= begin
                           FileUtils.mkdir_p ImageCacheDir
                           ImageCacheDir
                         end
      @image_cache_dir_made
    end


  end
end

# testing...
if __FILE__==$0
  include BirdChecklist::Scraper

  page = get_html_page make_aab_url("Brant"), false
  page = get_html_page make_aab_url("Common Raven"), false
  page = get_html_page make_aab_url("Clark's Nutcracker"), false
  page = get_html_page make_aab_url("Greater White-fronted Goose"), false

end
