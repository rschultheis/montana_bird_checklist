
require 'nokogiri'

require_relative 'scraper'
require_relative 'constants'

module BirdChecklist

  # A bird is really just a hash.  Keys and values.
  class Bird < Hash
    include Scraper
    include Taxonomies

    def winter_verified?
      self['winter_verified'] == 'X'
    end

    def winter_unverified?
      self['winter_unverified'] == 'X'
    end

    def winter?
      self.winter_verified? || self.winter_unverified?
    end

    def breeding_verified?
      self['breeding_verified'] == 'X'
    end

    def breeding_unverified?
      self['breeding_unverified'] == 'X'
    end

    def breeding?
      self.breeding_verified? || self.breeding_unverified?
    end

    def transient?
      self['transient'] == 'X'
    end

    def accidental?
      self['accidental'] == 'X'
    end

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

    def monthly_observations_chart_url
      if self['elcode']
        "http://fieldguide.mt.gov/RangeMaps/ObsChart_#{self.elcode}.png"
      else
        nil
      end
    end

    # any of the hash keys are also methods
    def method_missing(m)
      key = m.to_s
      return self[key] if self.has_key? key
      super
    end

    def major_group
      self['major_group'] ||= begin
        family = self.family
        MajorGroupings.select{|k,v| v.include? family }.keys.first
      end
      self['major_group']
    end

    def sort_key
      # we birds sorted in major groupings first, and by family within that
      # the sort should match what is defined in the data yaml file MajorGroupingConfig
      group_idx = MajorGroupings.keys.index{|g| g == major_group }
      group_mem_idx = MajorGroupings[major_group].index{|f| f == family }
      "#{"%2s" % group_idx}:#{"%2s" % group_mem_idx}:#{"%-20s" % self.family}.#{self.genus}.#{self.species}"
    end
  end
end

