require 'writeexcel'
require 'fileutils'

require_relative 'constants'

module BirdChecklist
  module ExcelUtils

    class Sheet
      attr_accessor :name, :birds, :intro_data
      def initialize name, birds=[], intro_data=[]
        @name, @birds, @intro_data = name, birds, intro_data
      end

    end

    include Locations

    def write_excel_file filename, sheets

      puts "Writing excel file: #{filename} (#{sheets.length} sheets)"
      wkbk = WriteExcel.new filename

      sheets.each do |sheet|
        wksht = wkbk.add_worksheet(sheet.name)

        row = 0
        col = 0

        if not sheet.intro_data.empty?
          sheet.intro_data.each do |intro_row|
            wksht.write_row row, col, intro_row
            row += 1
          end
          row += 1
        end

        headers = sheet.birds[0].keys
        wksht.write_row row, col, headers

        sheet.birds.each do |bird|
          row += 1
          wksht.write_row row, col, bird.values
        end
      end

      wkbk.close
    end
  end
end

#testing
if __FILE__==$0

  include BirdChecklist::ExcelUtils
  require_relative 'csv_utils'
  include BirdChecklist::CsvUtils

  test_file = File.join 'output', 'testing123.xlsx'
  birds = get_translated_data

  sheets = []
  sheets << Sheet.new('All Birds', birds)
  write_excel_file test_file, sheets

end
