require 'prawn'
require_relative 'constants'

module BirdChecklist
  module PdfUtils
    include BirdChecklist::Locations
    include BirdChecklist::Taxonomies

    BlockHeight = 60
    IconHeight = 20
    IconWidth = 25
    ObservationChartHeight = 40

    Icons = {
      'winter_verified' => 0,
      'winter_unverified' => 0,
      'breeding_verified' => 1,
      'breeding_unverified' => 1,
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
          @block_num = 0

          write_title_page

          current_family = nil

          ChecklistSort.each_pair do |major_group, minor_groups|

            group_common_names = minor_groups.values.flatten
            group_birds = group_common_names.map{|n| @checklist.find{|b| b['common_name'] == n}}
            group_rare_birds = group_birds.select{|b| b and (b.accidental? || b.num_observations.to_i < 100)}
            non_rare_birds = group_birds - group_rare_birds
            next unless non_rare_birds.length > 1

            write_major_group major_group

            minor_groups.each_pair do |minor_group, common_names|

              group_birds = common_names.map{|n| @checklist.find{|b| b['common_name'] == n}}
              rare_birds = group_birds.select{|b| b and (b.accidental? || b.num_observations.to_i < 100)}
              non_rare_birds = group_birds - rare_birds
              next unless non_rare_birds.length > 1

              write_family minor_group if ChecklistSort[major_group].keys.length > 1

              non_rare_birds.each do |bird|
                write_bird bird if bird
              end
            end

            if group_rare_birds.length > 0
              write_rarities group_rare_birds
            end
          end

        end

      end

      private

      def new_page
        @pdf.start_new_page
        @page_num += 1
        @block_num = 0
      end

      def write_title_page
        @pdf.text "Montana Bird Checklist"
        @pdf.text "compiled by Robert Schultheis"
        new_page
      end

      def write_major_group group
        new_page if @block_num > (@blocks_per_page / 2)

        write_block :major do
          @pdf.pad_top(8) do
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
        str = "#{FamilyDescriptions[family]} (#{family})"
        write_block :heading do
          @pdf.pad_top(8) do
            @pdf.transparent(0.4) do
              @pdf.line @pdf.bounds.top_right, @pdf.bounds.top_left
            end
            @pdf.pad_top(8) do
              @pdf.text str, :align => :center, :size => 18
            end
          end
        end
      end

      def write_bird bird

        write_block do
          @pdf.transparent(0.4) do
            @pdf.line @pdf.bounds.top_right, @pdf.bounds.top_left
            if @block_num.even?
              @pdf.line @pdf.bounds.top_right, @pdf.bounds.bottom_right
            else
              @pdf.line @pdf.bounds.top_left, @pdf.bounds.bottom_left
            end
            @pdf.stroke
          end
          @pdf.pad_top(5) do
            @pdf.text bird.common_name, :align => :center, :size => 12
          end

          icon_box_width = IconWidth * 3
          icon_box_x = (((@pdf.bounds.right - @pdf.bounds.left) / 2) - (icon_box_width / 2)).to_i
          @pdf.bounding_box([icon_box_x, IconHeight + 10], height: IconHeight, width: icon_box_width) do
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
          observation_box_x = icon_box_x + icon_box_width + 5
          observation_box_width = @pdf.bounds.right - observation_box_x - 10
          observation_map_box_x = icon_box_x - observation_box_width - 5
          if bird.observation_chart
            @pdf.bounding_box([observation_box_x, ObservationChartHeight], width: observation_box_width, height: ObservationChartHeight) do
              # @pdf.stroke_bounds
              @pdf.image bird.observation_chart, position: 0, height: @pdf.bounds.height, width: @pdf.bounds.width
            end
          end
          if bird.observation_map and File.exist? bird.observation_map
            @pdf.bounding_box([observation_map_box_x, ObservationChartHeight], width: observation_box_width, height: ObservationChartHeight) do
              # @pdf.stroke_bounds
              @pdf.image bird.observation_map, position: 0, height: @pdf.bounds.height, width: @pdf.bounds.width
            end
          end

        end
      end

      def write_rarities birds
        rare_birds_str =  birds.map{|b| b.common_name }.join(', ')
        type = if rare_birds_str.length > 800
                 :rareties_3x
               elsif rare_birds_str.length > 400
                 :rareties_2x
               else
                 :rareties
               end
        write_block :rareties do
          @pdf.pad_top(5) do
            @pdf.text "Other rare #{birds.first.major_group}", align: :center, size: 16
            @pdf.text rare_birds_str, align: :center, size: 10
          end
          @pdf.transparent(0.4) { @pdf.stroke_bounds }
        end
        write_block {}
      end

      def write_block type=:bird, &block
        x = case type
            when :heading
              0
            when :rareties, :rareties_2x, :major
              ((@page_width / 14.0) * 1.0).to_i
            else
              ((@page_width / 7.0) * 2.0).to_i
            end

        y = @page_height - (@block_num * BlockHeight)
        width = case type
                when :heading
                  @page_width
                when :rareties, :rareties_2x, :major
                  ((@page_width / 14.0) * 12.0).to_i
                else
                  ((@page_width / 7.0) * 3.0).to_i
                end
        height = case type
                 when :rareties_3x
                   @block_num += 6
                   BlockHeight*6
                 when :rareties_2x
                   @block_num += 4
                   BlockHeight*4
                 when :rareties, :major
                   @block_num += 2
                   BlockHeight*2
                 else
                   @block_num += 1
                   BlockHeight
                 end
        if @block_num > @blocks_per_page
          new_page
          y = @page_height
          case type
          when :rareties
            @block_num += 2
          else
            @block_num += 1
          end
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
  winter_checklist = checklist.select{|b| b.winter_verified? }
  pdf = PdfWriter.new winter_checklist, 'output/MontanaBirdsWinter.pdf'
  pdf.write_checklist_to_pdf
end
