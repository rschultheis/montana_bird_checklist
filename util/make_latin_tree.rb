require_relative '../lib/csv_utils'
require_relative '../lib/scraper'

include BirdChecklist::CsvUtils
include BirdChecklist::Locations

birds = get_raw_data FullDataOutputCSV

latin_tree = {}

birds.each do |bird|
  order, family, genus, species = bird['order'], bird['order'], bird['family'], bird['genus'], bird['species']
  latin_tree[order] ||= {}
  latin_tree[order][family] ||= {}
  latin_tree[order][family][genus] ||= {}
  latin_tree[order][family][genus][species] = bird['common_name']
end

puts latin_tree.to_yaml
