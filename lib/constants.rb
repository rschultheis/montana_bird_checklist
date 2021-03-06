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
    ElCodeMappingConfig = File.join(DataDir, 'elcode_mapping.yml')
    MajorGroupingConfig = File.join(DataDir, 'major_groupings.yml')
    ChecklistSortConfig = File.join(DataDir, 'checklist_sort.yml')

    FullDataOutputCSV = File.join(OutputDir, 'Montana_bird_checklist.csv')
    ExcelOutput = File.join(OutputDir, 'Montana_bird_checklist.xlsx')

    HtmlPageCacheDir = File.join(ProjDir, 'html_page_cache')

    ImageCacheDir = File.join(ProjDir, 'image_cache')

    IconDir = File.join(ProjDir, 'assets', 'icons')
    ObsChartDir = File.join(ProjDir, 'assets', 'observation_charts')
    ObsMapDir = File.join(ProjDir, 'assets', 'observation_maps')

  end

  # this is used to translate the raw data into boolean fields that are easier to work with
  module RawDataKeys
    WinterCodeKey = {
      'W' => 'winter_verified',
      'w' => 'winter_unverified',
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
    CommonNameToElCode = YAML.load_file Locations::ElCodeMappingConfig
    MajorGroupings = YAML.load_file Locations::MajorGroupingConfig
    ChecklistSort = YAML.load_file Locations::ChecklistSortConfig
  end

end
