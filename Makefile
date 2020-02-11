# Start of the makefile
# Defining variables
objects = MatrixOperations.o SEM_Single.o
f90comp = gfortran
switch = -O3
# Makefile
SEM_Single: $(objects)
	$(f90comp) -o SEM_Single $(switch) $(objects)
DFSEM_Single: MatrixOperations.o DFSEM_Single.o
	$(f90comp) -o DFSEM_Single $(switch) MatrixOperations.o DFSEM_Single.o
DAVBIL_Single: MatrixOperations.o DAVBIL_Single.o
	$(f90comp) -o DAVBIL_Single $(switch) MatrixOperations.o DAVBIL_Single.o
MatrixOperations.mod: MatrixOperations.o MatrixOperations.f90
	$(f90comp) -c $(switch) MatrixOperations.f90
MatrixOperations.o: MatrixOperations.f90
	$(f90comp) -c $(switch) MatrixOperations.f90
SEM_Single.o: MatrixOperations.mod SEM_Single.f90
	$(f90comp) -c $(switch) SEM_Single.f90
DFSEM_Single.o: MatrixOperations.mod DFSEM_Single.f90
	$(f90comp) -c $(switch) DFSEM_Single.f90
DAVBIL_Single.o: MatrixOperations.mod DAVBIL_Single.f90
	$(f90comp) -c $(switch) DAVBIL_Single.f90

%.o: %.f90
	$(f90comp) -c $(switch) $<
# Cleaning everything
clean: 
	rm $(objects)
	rm SEM_Single
	rm DFSEM_Single
	rm DAVBIL_Single
	rm *.dat
# End of the makefile
