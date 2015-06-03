PDFKit.configure do |config|
  config.default_options = {
      :page_size     => 'A4',
      :margin_top    => '10mm',
      :margin_right  => '10mm',
      :margin_bottom => '10mm',
      :margin_left   => '10mm'
  }
end