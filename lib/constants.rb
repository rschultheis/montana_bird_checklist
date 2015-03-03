require 'fileutils'
require 'yaml'

module BirdChecklist

  # filenames...
  module Locations
    ProjDir = File.dirname(File.dirname(__FILE__))
    DataDir = File.join(ProjDir, 'data')
    OutputDir = File.join(ProjDir, 'output')
    FileUtils.mkdir_p OutputDir

    # This was compiled from birdSpeciesFinal-Checklist-for-WEB_small.pdf which is
    RawDataFileName = File.join(DataDir, 'Montana_bird_checklist_raw_data.csv')
    OrderDescriptionsConfig = File.join(DataDir, 'order_descriptions.yml')
    FamilyDescriptionsConfig = File.join(DataDir, 'family_descriptions.yml')

    FullDataOutputCSV = File.join(OutputDir, 'Montana_bird_checklist.csv')
    ExcelOutput = File.join(OutputDir, 'Montana_bird_checklist.xlsx')

    HtmlPageCacheDir = File.join(ProjDir, 'html_page_cache')
  end

  # this is used to translate the raw data into boolean fields that are easier to work with
  module RawDataKeys
    WinterCodeKey = {
      'W' => 'winter_verified',
      'w' => 'winter_present',
    }
    BreedingCodeKey = {
      'B' => 'breeding_verified',
      'b' => 'breeding_indirect',
      't' => 'transient',
    }
  end

  module Taxonomies
    OrderDescriptions = YAML.load_file Locations::OrderDescriptionsConfig
    FamilyDescriptions = YAML.load_file Locations::FamilyDescriptionsConfig
  end

end
