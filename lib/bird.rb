
require 'nokogiri'

require_relative 'scraper'
require_relative 'constants'

module BirdChecklist

  # A bird is really just a hash.  Keys and values.
  class Bird < Hash
    include Scraper
    include Taxonomies

    def aab_url
      self['aab_url'] ||= make_aab_url self['common_name']
      self['aab_url']
    end

    def aab_html_doc
      @aab_html_doc_priv ||= Nokogiri::HTML get_html_page(aab_url)
      @aab_html_doc_priv
    end

    def elcode
      self['elcode'] ||= CommonNameToElCode[self.common_name].to_s
    end

    def field_guide_url
      self['field_guide_url'] ||= elcode.empty? ? '' : "http://fieldguide.mt.gov/speciesDetail.aspx?elcode=#{self.elcode}"
    end

    def field_guide_html_doc
      url = self['field_guide_url'].to_s
      if url.empty?
        return nil
      end
      @fg_html_doc_priv ||= Nokogiri::HTML get_html_page(url)
      @fg_html_doc_priv
    end

    # any of the hash keys are also methods
    def method_missing(m)
      key = m.to_s
      return self[key] if self.has_key? key
      super
    end
  end
end

