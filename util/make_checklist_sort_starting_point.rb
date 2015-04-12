require_relative '../lib/csv_utils'
require_relative '../lib/scraper'
require_relative '../lib/constants'

include BirdChecklist::CsvUtils
include BirdChecklist::Locations
include BirdChecklist::Taxonomies

birds = get_raw_data FullDataOutputCSV

new_grouping = {}

MajorGroupings.each_pair do |group, families|
  new_grouping[group] = {}
  families.each do |family|
    fam_birds = birds.select{|b| b['family'] == family}
    fam_desc = FamilyDescriptions[family]
    new_grouping[group][fam_desc] = fam_birds.map{|b| b['common_name']}
  end
end

puts new_grouping.to_yaml
