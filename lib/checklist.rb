require_relative 'bird'
require_relative 'csv_utils'
require_relative 'constants'


module BirdChecklist

  # A checklist is a list of Birds.  It can be enhanced and altered.  it can be outputed.
  class Checklist
    include CsvUtils
    include Enumerable
    include Taxonomies

    attr_reader :birds

    def initialize birds=[]
      @birds = birds
      @birds.delete_if{|b| b.nil? }
    end

    def each &block
      @birds.each{ |bird| block.call(bird) }
    end

    def select &block
      @birds.select{ |b| block.call(b) }
    end

    def sort! &block
      @birds.sort!{ |a,b| block.call(a,b) }
    end

    def add_field_to_all_birds birds, field_name, &blk
      puts "Setting field '#{field_name}' on all birds"
      @birds.each do |bird|
        bird[field_name] = yield bird
      end
    end

    def major_group

    end

    #turn one coded field into a clearer set of other fields
    def translate_field_on_all_birds source_field, translate_hash
      puts "Turning field #{source_field} into fields: #{translate_hash.values.join(', ')}"
      @birds.each do |bird|
        translate_hash.each_pair do |code, field|
          if bird[source_field] =~ /#{code}/
            bird[field] = 'X'
          else
            bird[field] = ''
          end
        end
        bird.delete source_field
      end
    end

    def write_csv filename
      write_birds_csv @birds, filename
    end

    def length
      @birds.length
    end

    def [] idx
      @birds[idx]
    end

  end
end

# testing
if __FILE__ == $0
  require 'yaml'
  require_relative 'csv_utils'
  include BirdChecklist::CsvUtils
  birds = get_translated_data

  checklist = BirdChecklist::Checklist.new birds
  checklist.each{|b| puts b.common_name }
end
