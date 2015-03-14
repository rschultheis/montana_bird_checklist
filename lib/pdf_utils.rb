require 'prawn'
require_relative 'constants'

module BirdChecklist
  module PdfUtils
    include BirdChecklist::Locations

    HeaderHeight = 48
    BirdHeight = 50

    Icons = {
      'winter_verified' => 0,
      'winter_unverified' => 30,
      'breeding_verified' => 60,
      'breeding_unverified' => 90,
      'transient' => 120,
    }

    def write_checklist_to_pdf checklist, filename

      group_names = checklist.map{|b| b['family_desc']}.uniq
      groups = {}
      group_names.each {|name| groups[name] = checklist.select{|b| b['family_desc'] == name}}


      puts "Writing PDF: #{filename}"
      Prawn::Document.generate(filename) do
        page_height = margin_box.height.to_i
        page_width = margin_box.width.to_i
        birds_per_page = ((page_height - HeaderHeight) / BirdHeight).to_i


        groups.each_pair do |group,all_birds|
          page = 0
          pages = (all_birds.length/birds_per_page.to_f).ceil
          all_birds.each_slice(birds_per_page) do |birds|
            start_new_page
            page += 1
            bounding_box([0,page_height], height: HeaderHeight, width: page_width) do
              # transparent(0.3) { stroke_bounds }
              header_str = if pages > 1
                             "#{group} (#{page}/#{pages})"
                           else
                             group
                           end
              text header_str, :align => :center, :size => 24
              text birds.first.family, align: :center, size: 12
            end

            bird_list_height = page_height - HeaderHeight
            bounding_box([0,bird_list_height], height: bird_list_height, width: page_width) do
              # transparent(0.7) { stroke_bounds }
              birds.each_with_index do |b,i|
                bounding_box([0,bird_list_height - (i*BirdHeight)], height: BirdHeight, width: page_width) do
                  transparent(0.5) { stroke_bounds }
                  text b['common_name'], size: 14
                  icons = []

                  bounding_box([10,30], height: 25, width: page_width) do
                    # transparent(0.3) { stroke_bounds }
                    Icons.each_pair do |icon, offset|
                      bounding_box([offset, 25], height: 25, width: 25) do
                        # transparent(0.12) { stroke_bounds }
                        if b.send("#{icon}?")
                          image File.join(IconDir, "#{icon}.png"), position: 0, height: 25
                        end
                      end
                    end
                  end

                end
              end
            end
          end
        end
      end

    end
  end
end


# testing...
if __FILE__==$0
  require_relative 'csv_utils'
  require_relative 'checklist'
  include BirdChecklist::Locations
  include BirdChecklist::CsvUtils
  birds = get_raw_data FullDataOutputCSV
  checklist = BirdChecklist::Checklist.new birds

  winter_checklist = checklist.select{|b| b.winter_verified? }

  include BirdChecklist::PdfUtils
  write_checklist_to_pdf winter_checklist, 'output/test.pdf'
end
