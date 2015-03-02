
require 'nokogiri'

require_relative 'scraper'

module BirdChecklist
  class Bird < Hash
    include Scraper

    def aab_url
      self['aab_url'] ||= make_aab_url self['common_name']
      self['aab_url']
    end

    def aab_html_doc
      @aab_html_doc_priv ||= Nokogiri::HTML get_html_page(aab_url)
      @aab_html_doc_priv
    end

  end
end

