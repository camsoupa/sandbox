(0..0o777).each do |n|
  puts "#{ARGV[0]}'\\#{"%03o" % n}'"
end
