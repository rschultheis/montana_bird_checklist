require 'google-search'

require_relative 'constants'

module BirdChecklist
  module ImageUtils

    include Locations

    def get_bird_images  bird
      q = "#{bird.genus} #{bird.species}"
      puts "Image searching for: #{q}"
      results = Google::Search::Image.new(query: q, image_size: :small).all
      if results.length < 1
        return []
      end

      bird_image_dir = File.join(ImageCacheDir, bird.slug)
      FileUtils.mkdir_p bird_image_dir
      html_file = File.join(bird_image_dir, 'images.html')
      File.open(html_file, 'w') do |f|
        puts "Writing #{results.length} images to #{html_file}"
        f.write %(<ul>)
        results.each do |image|
          f.write %(<li>)
          f.write %(<p>#{image.uri}</p>)
          f.write %(<img src="#{image.uri}">)
          f.write %(</li>)
        end
        f.write %(</ul>)
      end
    end

  end
end

# testing...
if __FILE__==$0
  include BirdChecklist::ImageUtils
  require_relative '../lib/csv_utils'
  include BirdChecklist::CsvUtils
  birds = get_raw_data(FullDataOutputCSV)
  birds.shuffle!

  get_bird_images birds[0]
end
