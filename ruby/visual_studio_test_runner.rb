require 'FileUtils'
require 'shell'

#run once to remove all .svn files
#for /r %R in (.svn) do if exist %R (rd /s /q "%R")

#total number of unit tests
tests_num = 12

sh = Shell.new

#puts 'Enter cadename:'
#cadename = gets
#remove the pesky newline
#cadename = cadename.chomp 

resultsfile = "unittests.txt"
FileUtils.touch resultsfile

proj_dir = "<ROOT_DIR>"

testbed_dir = proj_dir + "testbed\\"

grading_dir = proj_dir + "grading\\"

Dir.chdir "grading"
left_to_grade = Dir['*/']
Dir.chdir "../"

left_to_grade.each_index { |index| 

	cadename = File.basename left_to_grade[index]
	puts "Grading #{cadename}..."
	
	tests_src_dir = "testsource\\"
	
	student_test_dir = "#{testbed_dir}#{cadename}\\"
	test_solution = student_test_dir + "PS7.sln"
	tests_to_run = "testbed\\#{cadename}\\GradingTester\\bin\\Debug\\GradingTester.dll"
	
	FileUtils.cp_r tests_src_dir, student_test_dir, :verbose => true
	
	#copy .cs files into Spreadsheet testbed/Spreadsheet dir
	FileUtils.cp Dir.glob("./grading/#{cadename}/**/StringSocket.cs"), "./testbed/#{cadename}/StringSocket/", :verbose => true
	FileUtils.cp Dir.glob("./grading/#{cadename}/**/Class1.cs"), "./testbed/#{cadename}/StringSocket/", :verbose => true
	
	#build solution - need output
	IO.popen("devenv /rebuild Debug #{test_solution} /project GradingTester\\GradingTester.csproj /projectconfig Debug") do |output| 
		while line = output.gets do
			puts line
		end
	end

	File.open(resultsfile, 'a') do |f|
		if !(File.exists? tests_to_run)
		  puts "build failed for #{cadename}..."
		  f.puts "#{cadename}, ERROR"
		elsif
			#run unit tests
			IO.popen("mstest /testcontainer:#{tests_to_run}") do |output| 
				while line = output.gets do
					if (/^.*\/#{tests_num} test\(s\) Passed.*$/.match line) != nil
						puts "#{cadename} : #{line.split("/").first}"
						f.puts "#{cadename} : #{line.split("/").first}"
					end
					puts line
				end
			end
		end
	end
}


