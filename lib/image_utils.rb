require 'google-search'

require_relative 'constants'

module BirdChecklist
  module ImageUtils

    def get_bird_images  bird

    end

  end
end

# testing...
if __FILE__==$0
  include BirdChecklist::ImageUtils
  puts get_bird_images 'Canada Goose'
end
