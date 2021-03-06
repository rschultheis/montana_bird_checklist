require_relative 'constants'
require_relative 'scraper'

module BirdChecklist
  module Enhancers

    include Scraper
    include Taxonomies

    def add_slug birds
      puts "Setting slug field on all birds"
      add_field_to_all_birds birds, 'slug' do |bird|
        aab_slug bird['common_name']
      end
    end

    def add_aab_url birds
      puts "Setting aab_url field on all birds"
      birds.each { |bird| bird.aab_url }
    end

    def add_elcode birds
      puts "Setting elcode field on all birds"
      birds.each { |bird| bird.elcode }
    end

    def add_mt_field_guide_url birds
      puts "Setting field guide url on all birds"
      birds.each { |bird| bird.field_guide_url }
    end

    def add_latin_names birds
      puts "Setting latin name fields on all birds"
      birds.each do |bird|
        html_doc = bird.aab_html_doc
        next unless html_doc

        species = html_doc.xpath("//div[@id='spp_name']/p[@class='latin']")
        latin_scrape_str = species.inner_text.strip.gsub(/\W+/,' ')
        ignore_this, genus, species, order, family = latin_scrape_str.match(/^(\w+)\s+(\w+)\s+ORDER\s+(\w+)\s+FAMILY\s+(\w+)$/).to_a
        genus, species, order, family = genus.capitalize, species.capitalize, order.capitalize, family.capitalize
        bird['order_desc'] = OrderDescriptions[order]
        bird['order'] = order
        bird['family_desc'] = FamilyDescriptions[family]
        bird['family'] = family
        bird['genus'] = genus
        bird['species'] = species
      end
    end

    def add_similar_species birds
      # the similar species list comes from allaboutbirds.com
      # it lists similiar species all over N America with any range overlap
      # we will trim their list to only species in the checklist already
      all_listed_species = birds.map{|b| b['slug'] }
      add_field_to_all_birds birds, 'similar_species' do |bird|
        html_doc = bird.aab_html_doc
        next unless html_doc
        similar_species = html_doc.xpath("//div[@id='id_similar_spp']//div[@class='annotations']/h4/a").map{|e| e.inner_text }.uniq
        mt_similar_species = similar_species.select{|s| all_listed_species.include?(aab_slug(s)) }
        mt_similar_species.join(', ')
      end
    end

    def check_if_accidental_species birds
      add_field_to_all_birds birds, 'accidental' do |bird|
        html_doc = bird.field_guide_html_doc
        next unless html_doc
        matches = html_doc.xpath("//a[ text() = 'Accidental Species']")
        if not matches.empty?
          'X'
        else
          ''
        end
      end
    end

    def add_number_of_observations birds
      add_field_to_all_birds birds, 'num_observations' do |bird|
        html_doc = bird.field_guide_html_doc
        next unless html_doc
        txt = html_doc.xpath("//b[ text() = 'Number of Observations:' ]")[0].parent.inner_text
        txt.match(/Number of Observations:\s+(\d+)/)[1].to_i
      end
    end

    def sort_birds birds
      puts "Sorting birds"
      birds.sort! do |bird_a, bird_b|
        bird_a.sort_key <=> bird_b.sort_key
      end
    end

    private

    # set a field on a bird from a bloctk
    def add_field_to_all_birds birds, field_name, &blk
      puts "Setting field '#{field_name}' on all birds"
      birds.each do |bird|
        bird[field_name] = yield bird
      end
    end

  end
end

# testing
if __FILE__ == $0
  include BirdChecklist::DataEnhancer
  require 'yaml'
  require_relative 'csv_utils'
  include BirdChecklist::CsvUtils
  birds = get_translated_data

  add_slug birds
  # add_aab_url birds
  # add_latin_names birds
  # add_similar_species birds

  puts birds[0..5].to_yaml
end
