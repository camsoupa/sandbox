

function fibonacci( num )
   if num <= 2 then
         return 1
   else
         return fibonacci( num-1 ) + fibonacci( num-2 )
   end
end


print("Calculator for nth Fibonnaci number: ")

again = true

while again do

	io.write("Please enter a number for n and press ENTER. ")

	n= nil

	repeat
	   n=io.read("*number\r")
	   io.flush()
	until n

	print( "The "..tostring( n ).."th Fibonacci number is: "..fibonacci( n ))

	io.write("Press 0 to QUIT or 1 to TRY AGAIN. ")

	replay = nil

	repeat

		replay = io.read()
		io.flush()
	until ( ( replay == "0" ) or ( replay == "1") )

	if replay == "0" then
		again = false
	end

end
