require_relative 'constants'
require_relative 'csv_utils'
require_relative 'enhancers'
require 'yaml'

module BirdChecklist
  class ChecklistMaker
    include CsvUtils
    include Enhancers

    def initialize
      #load list birds out of the raw CSV
      @birds = get_translated_data
      self
    end

    def enhance
      add_slug @birds
      add_aab_url @birds
      add_latin_names @birds
      add_similar_species @birds
      self
    end

    def output
      write_all_birds_csv @birds
      self
    end

    def go
      enhance
      output
    end
  end
end

if __FILE__==$0
  chklst = BirdChecklist::ChecklistMaker.new
  chklst.enhance
  chklst.output
end

