require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

puts 'EventManager Initialized!'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(form_letter, id)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone(number)
  number.gsub!(/\D/, '')
  if number.length == 10 || (number.length == 11 && number[0] == '1')
    number = number[-10..-1]
  else 
    "Bad Number"
  end
end


def get_the_peak_hours(contents)
  def get_hour_frequency(reg_date)
    reg_time = Time.strptime(reg_date,"%m/%d/%Y %k:%M")
    reg_time.hour.to_s
  end
  
  def get_peak_hours(hour_array)
    sorter_hash = Hash.new(0)
    hour_array.each { |v| sorter_hash[v] += 1}
    sorter_hash.sort.reduce([0, 0]) {|r,v| r = v if v[1] > r[1]; r}[0]
  end
  hour_array = []
  contents.each do |row|
    hour_array.push(get_hour_frequency(row[:regdate]))
  end
  get_peak_hours(hour_array)
end

def get_the_peak_day(contents)
  def get_date_frequency(reg_date)
    reg_time = Time.strptime(reg_date,"%m/%d/%Y %k:%M")
    # reg_time.date.wday.to_s
    Date::DAYNAMES[reg_time.wday]
  end
  def get_peak_days(date_array)
    sorter_hash = Hash.new(0)
    date_array.each { |v| sorter_hash[v] += 1}
    sorter_hash.sort.reduce([0, 0]) {|r,v| r = v if v[1] > r[1]; r}[0]
  end
  date_array = []
  contents.each do |row|
    date_array.push(get_date_frequency(row[:regdate]))
  end
  get_peak_days(date_array)
end

def open_sesame(file)
  CSV.open(
    file,
    headers: true, 
    header_converters: :symbol
  )  
end
contents = open_sesame('event_attendees.csv')
titents = open_sesame('event_attendees.csv')
datents = open_sesame('event_attendees.csv')
contents = CSV.open(
  'event_attendees.csv',
  headers: true, 
  header_converters: :symbol
)

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])
  home_phone = clean_phone(row[:homephone])

  
  legislators = legislators_by_zipcode(zipcode)
  
  form_letter = erb_template.result(binding)
  save_thank_you_letter(form_letter, id)
end

most_frequent_hour = get_the_peak_hours(titents)
puts most_frequent_hour
wyoming = get_the_peak_day(datents)
puts wyoming








