require_relative '../lib/scraper'
require_relative '../lib/csv_utils'

include BirdChecklist::Scraper
include BirdChecklist::Locations
include BirdChecklist::Taxonomies
include BirdChecklist::CsvUtils

birds = get_raw_data FullDataOutputCSV

birds.each do |bird|
  next unless bird['elcode']
  raw_img = get_web_image bird.monthly_observations_chart_url
  next unless raw_img
  puts bird['common_name']
  begin
    %x|convert #{raw_img} -crop 0x0+0+32 #{bird.observation_chart}|
  rescue Exception
  end
end
