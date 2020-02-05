# Start of the makefile
# Defining variables
objects = MatrixOperations.o SEM_Single.o
f90comp = gfortran
switch = -O3
# Makefile
execname: $(objects)
	$(f90comp) -o execname $(switch) $(objects)
MatrixOperations.mod: MatrixOperations.o MatrixOperations.f90
	$(f90comp) -c $(switch) MatrixOperations.f90
MatrixOperations.o: MatrixOperations.f90
	$(f90comp) -c $(switch) MatrixOperations.f90
main.o:	MatrixOperations.mod SEM_Single.f90
	$(f90comp) -c $(switch) SEM_test.f90

%.o: %.f90
	$(f90comp) -c $(switch) $<
# Cleaning everything
clean: 
	rm $(objects)
	rm execname
	rm *.dat
# End of the makefile
