require_relative '../lib/scraper'
require_relative '../lib/csv_utils'

include BirdChecklist::Scraper
include BirdChecklist::Locations
include BirdChecklist::Taxonomies
include BirdChecklist::CsvUtils

birds = get_raw_data(FullDataOutputCSV).shuffle

birds.each do |bird|
  next unless bird['elcode']
  raw_img = get_web_image bird.monthly_observations_map_url
  puts "Downloaded: #{raw_img}"
  next unless raw_img
  puts bird['common_name']
  begin
    %x|convert #{raw_img} -crop 0x190+0+0 #{bird.observation_map}|
  rescue Exception
  end
end
