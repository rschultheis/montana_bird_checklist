require_relative '../lib/scraper'
require_relative '../lib/csv_utils'

include BirdChecklist::Scraper
include BirdChecklist::Locations
include BirdChecklist::Taxonomies
include BirdChecklist::CsvUtils

common_name_to_elcode = {}
birds = get_translated_data
birds = birds
common_names = birds.map{|b| b['common_name']}

=begin
#tricky ones
common_names = [
  'Mute Swan',
  'Canada Goose',
  'Brant',
  'Green-winged Teal',
  'Sora',
  'Northern Flicker',
  'Yellow-rumped Warbler',
  'Brewer\'s Sparrow',
  'Sage Sparrow',
  'Dark-eyed Junco',
  'Gray-crowned Rosy-Finch',
]
=end

common_names.each do |name|
  begin
    response = Curl.post("http://fieldguide.mt.gov/search.aspx", {'q' => name})
    doc = Nokogiri::HTML response.body_str
    el = if response.status.to_i == 302
           doc.xpath('//a')
         elsif response.status.to_i == 200
           doc.xpath("(//div[@id='searchResults']//a)")
         else
           raise "Bad response: #{response.status}"
         end
    raise "No results for '#{name}'" unless el.length > 0
    location = URI.decode(el.attr('href').value)
    elcode = location.match(/([^=]+)$/)[1]

    puts "#{name} -> #{elcode}"
    common_name_to_elcode[name] = elcode
  rescue Exception => e
    puts "ERROR: #{name}: #{e.to_s}"
  end
end

File.open(ElCodeMappingConfig, 'w'){|f| f.write common_name_to_elcode.to_yaml}
