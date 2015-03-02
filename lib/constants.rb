require 'fileutils'

module BirdChecklist

  # filenames...
  module Locations
    ProjDir = File.dirname(File.dirname(__FILE__))
    DataDir = File.join(ProjDir, 'data')
    OutputDir = File.join(ProjDir, 'output')
    FileUtils.mkdir_p OutputDir

    # This was compiled from birdSpeciesFinal-Checklist-for-WEB_small.pdf which is
    RawDataFileName = File.join(DataDir, 'Montana_bird_checklist_raw_data.csv')
    FullDataOutputCSV = File.join(OutputDir, 'Montana_bird_checklist.csv')

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
    OrderToGroup = {
      'ANSERIFORMES' => 'Ducks, Geese, and Swans',
      'GALLIFORMES' => 'Grouse, Quail, and Allies',
      'GAVIIFORMES' => 'Loons',
      'PODICIPEDIFORMES' => 'Grebes',
      'CICONIIFORMES' => 'Storks',
      'SULIFORMES' => 'Frigatebirds, Boobies, Cormorants, Darters, and Allies',
      'PELECANIFORMES' => 'Pelicans, Herons, Ibises, and Allies',
      'ACCIPITRIFORMES' => 'Hawks, Kites, Eagles, and Allies',
      'FALCONIFORMES' => 'Caracaras and Falcons',
      'GRUIFORMES' => 'Cranes and Rails',
      'CHARADRIIFORMES' => 'Plovers, Sandpipers, and Allies',
      'COLUMBIFORMES' => 'Pigeons and Doves',
      'CUCULIFORMES' => 'Cuckoos',
      'STRIGIFORMES' => 'Owls',
      'CAPRIMULGIFORMES' => 'Nightjars',
      'APODIFORMES' => 'Swifts and Hummingbirds',
      'CORACIIFORMES' => 'Kingfishers and Allies',
      'PICIFORMES' => 'Woodpeckers',
      'PASSERIFORMES' => 'Perching Birds',
    }
  end

end
