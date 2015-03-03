require_relative '../lib/scraper'

include BirdChecklist::Scraper
include BirdChecklist::Locations
include BirdChecklist::Taxonomies

family_to_description = {}
OrderDescriptions.keys.each do |order|

  url = "http://fieldguide.mt.gov/displayFamily.aspx?order=#{order}"
  html = get_html_page url
  doc = Nokogiri::HTML(html)

  rows = doc.xpath("//b[ text() = 'Family']/following-sibling::table//tr")
  array = rows.map{|e| e.text.strip.split(/\s+-\s+/).reverse}
  family_to_description_for_order = Hash[array]
  family_to_description.merge! family_to_description_for_order
end

File.open(FamilyDescriptionsConfig, 'w'){|f| f.write family_to_description.to_yaml}
