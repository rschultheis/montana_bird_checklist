require_relative '../lib/csv_utils'
require_relative '../lib/scraper'
require_relative '../lib/constants'

include BirdChecklist::CsvUtils
include BirdChecklist::Locations
include BirdChecklist::Taxonomies

birds = get_raw_data FullDataOutputCSV

ChecklistSort.each_pair do |group, minor_groups|
  minor_groups.each_pair do |minor_group, bird_names|
    bird_names.sort! do |b1n, b2n|
      b1 = birds.find{|b| b['common_name'] == b1n}
      b2 = birds.find{|b| b['common_name'] == b2n}
      b2.num_observations.to_i <=> b1.num_observations.to_i
    end
  end
end

puts ChecklistSort.to_yaml
