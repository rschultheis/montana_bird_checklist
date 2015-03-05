require_relative 'constants'
require_relative 'bird'

require 'csv'

module BirdChecklist
  module CsvUtils
    include RawDataKeys

    # if you want the full raw data, with translated fields, call this
    def get_translated_data filename
      birds = get_raw_data filename
      birds = translate_raw_codes birds, 'breeding_code', BreedingCodeKey
      birds = translate_raw_codes birds, 'winter_code', WinterCodeKey
      # puts "Translated Data:\n#{birds.to_yaml}"
      birds
    end

    def write_birds_csv birds, filename
      rows = birds
      puts "Writing #{rows.length} birds to csv: #{filename}"
      CSV.open(filename, 'w') do |csv|
        headers = rows[0].keys
        csv << headers
        rows.each do |row|
          csv << row.values
        end
      end
    end

    private

    def get_raw_data filename
      puts "Reading csv: #{filename}"
      raw_data = CSV.read filename
      headers = raw_data.shift
      raw_data.map{|a| Bird[ headers.zip(a) ]}
    end

    def translate_raw_codes data, source_field, translate_hash
      data.each do |bird|
        translate_hash.each_pair do |code, field|
          if bird[source_field] == code
            bird[field] = true
          else
            bird[field] = false
          end
        end
        bird.delete source_field
      end
    end

  end
end


# testing...
if __FILE__==$0
  include BirdChecklist::CsvUtils
  include BirdChecklist::Locations
  require 'yaml'
  data = get_raw_data RawDataFileName
  bird = data.find{|b| b['common_name'] == "Clark's Nutcracker" }
  puts bird.aab_html_doc

  write_birds_csv data, 'output/test.csv'
end
