"""
This script takes the raw data from fwp.mt.gov,
and enhances it with all the stuff
"""

require 'csv'
require 'yaml'
require 'fileutils'
require 'curb'
require 'nokogiri'

RawDataFileName = 'Montana_bird_checklist_raw_data.csv'
OutputCsv = 'Montana_bird_checklist.csv'

WinterCodeKey = {
  'W' => 'winter_verified',
  'w' => 'winter_present',
}
BreedingCodeKey = {
  'B' => 'breeding_verified',
  'b' => 'breeding_indirect',
  't' => 'transient',
}

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

def get_raw_data
  raw_data = CSV.read RawDataFileName
  headers = raw_data.shift
  raw_data.map{|a| Hash[ headers.zip(a) ]}
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

def get_translated_data
  birds = get_raw_data
  birds = translate_raw_codes birds, 'breeding_code', BreedingCodeKey
  birds = translate_raw_codes birds, 'winter_code', WinterCodeKey
  # puts "Translated Data:\n#{birds.to_yaml}"
  birds
end

def add_field_to_all_birds birds, field_name, &blk
  birds.each do |bird|
    bird[field_name] = yield bird
  end
end

BirdPages = {}
BirdPagesCacheDir = 'bird_pages'
FileUtils.mkdir_p BirdPagesCacheDir


def add_aab_url birds
  add_field_to_all_birds birds, 'aab_url' do |bird|
    # replace spaces with underscores, and lowercase it
    slug = bird['common_name'].gsub(/\s+/,'_').gsub(/\W/,'').downcase
    url = "http://www.allaboutbirds.org/guide/#{slug}/id"
    begin
      cache_file = File.join BirdPagesCacheDir, bird['common_name']
      html = if File.exist? cache_file
        IO.read cache_file
      else
        puts "Getting: #{url}"
        html = Curl.get(url).body_str
        File.open(cache_file, 'w') {|f| f.write html}
        html
      end
      BirdPages[bird['common_name']] = Nokogiri::HTML(html)
    rescue Exception => e
      puts "WARN: #{e}"
    end

    url
  end
end

def add_latin_names birds
  birds.each do |bird|
    html_doc = BirdPages[bird['common_name']]
    next unless html_doc

    species = html_doc.xpath("//div[@id='spp_name']/p[@class='latin']")
    latin_scrape_str = species.inner_text.strip.gsub(/\W+/,' ')
    ignore_this, genus, species, order, family = latin_scrape_str.match(/^(\w+)\s+(\w+)\s+ORDER\s+(\w+)\s+FAMILY\s+(\w+)$/).to_a
    bird['order_desc'] = OrderToGroup[order]
    bird['order'] = order
    bird['family'] = family
    bird['genus'] = genus
    bird['species'] = species
  end
end

def add_similar_species birds
  add_field_to_all_birds birds, 'similar_species' do |bird|
    html_doc = BirdPages[bird['common_name']]
    next unless html_doc
    similar_species = html_doc.xpath("//div[@id='id_similar_spp']//div[@class='annotations']/h4/a").map{|e| e.inner_text }.uniq
    similar_species.join(', ')
  end
end

def enhance_data birds
  add_aab_url birds
  add_latin_names birds
  add_similar_species birds
  puts "Enhanced Data:\n#{birds.to_yaml}"
  birds
end

def write_csv filename, rows
  puts "Writing: #{filename}"
  CSV.open(filename, 'w') do |csv|
    headers = rows[0].keys
    csv << headers
    rows.each do |row|
      csv << row.values
    end
  end
end


starting_data = get_translated_data
enhanced_data = enhance_data starting_data
write_csv OutputCsv, enhanced_data

puts ''
puts enhanced_data.map{|bird| bird['family']}.uniq
