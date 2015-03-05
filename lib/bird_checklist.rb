require_relative 'constants'
require_relative 'csv_utils'
require_relative 'excel_utils'
require_relative 'enhancers'
require_relative 'checklist'
require 'yaml'

module BirdChecklist
  class MtChecklistMaker
    include CsvUtils
    include ExcelUtils
    include Enhancers
    include Locations
    include RawDataKeys

    def initialize
      #load list birds out of the raw CSV
      birds = get_raw_data RawDataFileName
      @all = Checklist.new birds
      self
    end

    def enhance
      @all.translate_field_on_all_birds 'winter_code', WinterCodeKey
      @all.translate_field_on_all_birds 'breeding_code', BreedingCodeKey
      add_slug @all
      add_aab_url @all
      add_elcode @all
      add_mt_field_guide_url @all
      add_latin_names @all
      add_similar_species @all
      check_if_accidental_species @all
      self
    end

    def output
      write_birds_csv @all, FullDataOutputCSV

      sheets = []
      sheets << Sheet.new('All birds', @all, [['Listing of all birds with some annual presence in Montana']])

      Taxonomies::OrderDescriptions.each_pair do |order, description|
        sheets << Sheet.new(order, @all.select{|b| b['order'] == order}, [[description]])
      end
      write_excel_file ExcelOutput, sheets
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

