require 'prawn'
require_relative 'constants'

module BirdChecklist
  module PdfUtils
    include BirdChecklist::Locations
    include BirdChecklist::Taxonomies

    BlockHeight = 80
    IconHeight = 16
    IconWidth = 20
    ObservationChartHeight = 40

    Icons = {
      'winter_verified' => 0,
      'winter_unverified' => 0,
      'breeding_verified' => 1,
      'breeding_unverified' => 1,
      'accidental' => 1,
      'transient' => 2,
    }

    class PdfWriter
      def initialize checklist, filename
        @checklist, @filename = checklist, filename
      end

      def write_checklist_to_pdf

        puts "Writing PDF: #{@filename}"
        Prawn::Document.generate(@filename) do |pdf|
          @pdf = pdf
          @page_height = pdf.margin_box.height.to_i
          @page_width = pdf.margin_box.width.to_i
          @blocks_per_page = (@page_height / BlockHeight).to_i
          @page_num = 0
          @cur_y = @page_height

          write_title_page

          current_family = nil

          ChecklistSort.each_pair do |major_group, minor_groups|

            group_common_names = minor_groups.values.flatten
            group_birds = group_common_names.map{|n| @checklist.find{|b| b['common_name'] == n}}
            next if group_birds.all?{|b| b.very_rare? }

            write_major_group major_group

            minor_groups.each_pair do |minor_group, common_names|

              group_birds = common_names.map{|n| @checklist.find{|b| b['common_name'] == n}}
              rare_birds = group_birds.select{|b| b.very_rare? }
              non_rare_birds = (group_birds - rare_birds).select{|b| !b.nil? }

              write_family minor_group if ChecklistSort[major_group].keys.length > 1

              non_rare_birds.each_slice(2) do |row_of_2|

                write_block :bird_row do
                  bird_width = @pdf.bounds.width / 2
                  @pdf.bounding_box([0,@pdf.bounds.height], width: bird_width, height: @pdf.bounds.height) do
                    @pdf.transparent(0.4) do
                      @pdf.line @pdf.bounds.top_right, @pdf.bounds.top_left
                      @pdf.line @pdf.bounds.top_right, @pdf.bounds.bottom_right
                      @pdf.line @pdf.bounds.bottom_right, @pdf.bounds.bottom_left
                      @pdf.stroke
                    end

                    write_bird row_of_2[0]
                  end
                  @pdf.bounding_box([bird_width,@pdf.bounds.height], width: bird_width, height: @pdf.bounds.height) do
                    @pdf.transparent(0.4) do
                      @pdf.line @pdf.bounds.top_right, @pdf.bounds.top_left
                      @pdf.line @pdf.bounds.bottom_right, @pdf.bounds.bottom_left
                      @pdf.stroke
                    end
                    write_bird row_of_2[1] if row_of_2[1]
                  end
                end
              end

              if (rare_birds.length > 0)
                write_rarities minor_group, rare_birds
              end
            end

          end

        end

      end

      private

      def new_page
        @pdf.start_new_page
        @page_num += 1
        @cur_y = @page_height
      end

      def write_title_page
        @pdf.image 'cover/MT_Bird_Checklist_Cover.png', position: 0, height: @pdf.bounds.height, width: @pdf.bounds.width
        new_page
        @pdf.text "This is where usage instructions will go"
        new_page
      end

      def write_major_group group
        new_page if @cur_y < (@page_height * 0.50)

        write_block :heading do
          @pdf.pad_top(20) do
            @pdf.transparent(0.9) do
              @pdf.line @pdf.bounds.top_right, @pdf.bounds.top_left
            end
            @pdf.pad_top(8) do
              @pdf.text group, :align => :center, :size => 24
            end
          end
        end
      end

      def write_family family
        new_page if @cur_y < (@page_height * 0.25)

        write_block :heading, 60 do
          @pdf.bounding_box([0, 26], height: 26, width: @pdf.bounds.width) do
            @pdf.pad_top(4) do
              @pdf.stroke_bounds
              @pdf.text family, align: :center, size: 18
            end
          end
        end
      end

      def write_bird bird

        puts "BIRD: #{bird['common_name']}"

        @pdf.pad_top(5) do
          @pdf.text bird.common_name, :align => :center, :size => 12
        end

        icon_box_width = IconWidth * 3
        icon_box_x = (((@pdf.bounds.right - @pdf.bounds.left) / 2) - (icon_box_width / 2)).to_i
        @pdf.bounding_box([icon_box_x, IconHeight + 35], height: IconHeight, width: icon_box_width) do
          Icons.each_pair do |icon_key, offset|
            if bird.send("#{icon_key}?")
              @pdf.bounding_box([offset * IconWidth, IconHeight], height: IconHeight, width: IconWidth) do
                if icon_key =~ /unverified/
                  @pdf.transparent(0.5) { @pdf.image File.join(IconDir, "#{icon_key}.png"), position: 0, height: IconHeight }
                else
                  @pdf.image File.join(IconDir, "#{icon_key}.png"), position: 0, height: IconHeight
                end
              end
            end
          end
        end

        #observations by month
        observation_box_x = icon_box_x + icon_box_width + 20
        observation_box_width = @pdf.bounds.right - observation_box_x - 20
        observation_map_box_x = icon_box_x - observation_box_width - 30
        if bird.observation_chart
          @pdf.bounding_box([observation_box_x, ObservationChartHeight + 15], width: observation_box_width, height: ObservationChartHeight) do
            @pdf.image bird.observation_chart, position: 0, height: @pdf.bounds.height, width: @pdf.bounds.width
          end if File.exist?(bird.observation_chart)
        end
        if bird.observation_map and File.exist? bird.observation_map
          @pdf.bounding_box([observation_map_box_x, ObservationChartHeight + 20], width: observation_box_width, height: ObservationChartHeight) do
            # @pdf.stroke_bounds
            @pdf.image bird.observation_map, position: 0, height: @pdf.bounds.height, width: @pdf.bounds.width
          end if File.exist?(bird.observation_map)
        end
        @pdf.bounding_box([@pdf.bounds.left + 5, @pdf.bounds.bottom+10], height: 10, width: @pdf.bounds.width) do
          @pdf.text "Date:                                   Location:", align: :left, size: 8
        end
      end

      def write_rarities group, birds
        bird_rows = birds.length / 3
        bird_rows += 1 if birds.length % 3 > 0
        rheight = (bird_rows * 20) + 36
        cur_ry = rheight - 36
        write_block :rareties, rheight do
          @pdf.stroke_bounds
          @pdf.pad_top(10) do
            @pdf.text "Very rare/vagrant #{group}", align: :center, size: 16
            rwidth = @pdf.bounds.width / 3
            birds.each_slice(3) do |rbird_row|
              3.times do |i|
                @pdf.bounding_box([rwidth*i, cur_ry], height: 20, width: rwidth) do
                  @pdf.bounding_box([@pdf.bounds.left + 5, @pdf.bounds.top-5], height: 10, width: 10) do
                    @pdf.stroke_bounds
                  end
                  @pdf.bounding_box([@pdf.bounds.left + 20, @pdf.bounds.top], height: 20, width: @pdf.bounds.width - 20) do
                    @pdf.pad_top(4) do
                      @pdf.text rbird_row[i]['common_name'], align: :left, size: 10
                    end
                  end
                end if rbird_row[i]
              end
              cur_ry -= 20
            end
          end
        end
      end

      def write_block type=:bird, height=:block_size, &block
        x = case type
            when :bird_row, :major
              0
            when :rareties, :heading
              ((@page_width / 14.0) * 1.0).to_i
            else
              ((@page_width / 7.0) * 2.0).to_i
            end

        y = @cur_y
        width = case type
                when :bird_row, :major
                  @page_width
                when :rareties, :heading
                  ((@page_width / 14.0) * 12.0).to_i
                else
                  ((@page_width / 7.0) * 3.0).to_i
                end
        height = case height
                 when Integer, Fixnum
                   height.to_i
                 else
                   BlockHeight
                 end
        @cur_y -= height

        if @cur_y < 0
          new_page
          y = @page_height
          @cur_y = y - height
        end

        @pdf.bounding_box([x,y], width: width, height: height) do
          # @pdf.transparent(0.1) { @pdf.stroke_bounds }
          yield block
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
  include BirdChecklist::PdfUtils
  pdf = PdfWriter.new checklist, 'output/MontanaBirdsFullYear.pdf'
  pdf.write_checklist_to_pdf
  # winter_checklist = checklist.select{|b| b.winter_verified? }
  # pdf = PdfWriter.new winter_checklist, 'output/MontanaBirdsWinter.pdf'
  # pdf.write_checklist_to_pdf
end
