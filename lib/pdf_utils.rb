require 'prawn'

module BirdChecklist
  module PdfUtils

    def write_checklist_to_pdf checklist, filename
      Prawn::Document.generate(filename) do
        checklist[0..5].each do |b|
          text b['common_name']
        end
      end

    end
  end
end


# testing...
if __FILE__==$0
  require_relative 'constants'
  require_relative 'csv_utils'
  require_relative 'checklist'
  include BirdChecklist::Locations
  include BirdChecklist::CsvUtils
  birds = get_raw_data FullDataOutputCSV
  checklist = BirdChecklist::Checklist.new birds

  include BirdChecklist::PdfUtils
  write_checklist_to_pdf checklist, 'output/test.pdf'
end
