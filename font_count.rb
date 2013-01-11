#!/usr/bin/env ruby
# Script to invoke the PDFBoxMiner java and recover a JSON version of the text
# 
# Usage: ruby process.rb <FILENAME> 
# For development purposes only
require 'json'

filename = ARGV[0]
if filename.nil? or filename.empty?
  puts "Checks which fonts are used in a native-generated PDF file."
  puts
  puts "Usage: "
  puts "       ruby font_count.rb <PATH/TO/FILENAME>"
  puts
  puts "To narrow scope to certain pages, specify <first_page> and <last_page>"
  puts "       ruby font_count.rb <PATH/TO/FILENAME> <first_page>"
  puts "       ruby font_count.rb <PATH/TO/FILENAME> <first_page> <last_page>"
  puts
  exit
end

begin
  raw_data = `java -jar target/pdfboxminer-0.0.1-jar-with-dependencies.jar --format JSON #{filename}`
  data = JSON.parse(raw_data)

  puts
  puts "Processing #{filename}"
  puts raw_data.size.to_s + " bytes returned"
  puts

  if ARGV[1] and ARGV[1].to_i and ARGV[1].to_i < data.count
    first_page = ARGV[1].to_i - 1
  else
    first_page = 0
  end

  if ARGV[2] and ARGV[2].to_i and ARGV[2].to_i < data.count and ARGV[2] <= ARGV[1]
    last_page = ARGV[2].to_i - 1
  else
    last_page = data.count - 1
  end
  
  # first_page to last_page define the index of pages to focus on

  # Array in an Array
  # Font is entry[4]
  # Font size is entry[3]
  # Character itself is entry[2]

  # Focus on the selected pages
  total_font_usage = Hash.new(0)
  (first_page..last_page).each do |page|
    data[page].each { |c| total_font_usage["#{c[4]}-#{c[3]}"] += 1 unless c[2] == " " }
  end
  puts "#{filename}"
  puts "from page #{(first_page + 1).to_s} to #{(last_page + 1).to_s}"

  total_usage = 0
  total_font_usage.values.each { |x| total_usage += x }
  puts total_usage.to_s + " characters total"
  puts

  puts "Percent of characters in each font/size:"
  fonts = total_font_usage.keys
  fonts_sorted = fonts.sort { |x,y| total_font_usage[y] <=> total_font_usage[x] }
  fonts_sorted.each do |font|
    percent = total_font_usage[font] * 1.0 / total_usage
    printf("%3.2f", 100 * percent)
    puts "% : #{font}"
  end

rescue
  puts "Exited with a problem on filename '#{filename}'"
end
