# Start of the makefile
# Defining variables
objects = SEM_test.o
f90comp = gfortran
switch = -O3
# Makefile
execname: $(objects)
	$(f90comp) -o execname $(switch) $(objects)

main.o:	SEM_test.f90
	$(f90comp) -c $(switch) SEM_test.f90

%.o: %.f90
	$(f90comp) -c $(switch) $<
# Cleaning everything
clean:
#    rm global.mod 
	rm $(objects)
	rm execname
	rm *.dat
# End of the makefile
