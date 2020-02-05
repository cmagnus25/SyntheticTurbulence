!THIS PROGRAM IMPLEMENTS THE SEM METHOD DESCRIBED IN N. JARRAIN THESIS, CHP. 4
!
!USER CAN MODIFY THE FILE TO SET THE SIMULATION PARAMETERS, BUT SHOULD NOT MODIFY
!ANYTHING UNDER THE ADVERTISEMENT LINE.
!
!THE OUTPUT OF THIS SCRIPTS ARE:
!
!VEL_YYY_ZZZ.dat    --> FILE WITH THE VELOCITY CALCULATED FOR THE (YYY,ZZZ) GRID POINT
!
!VEL_GLOB_TXXX.dat  --> FILE WITH THE VELOCITY CALCULATED FOR THE WHOLE GRID AT THE XXX TIME STEP
!
!OUTDATA.dat        --> FILE WITH THE POSTPROCESSING DATA

PROGRAM SEMEQUATIONS
USE MatrixOperations

IMPLICIT NONE

DOUBLE PRECISION :: SIGMA      ,VOL        ,GENEREPSILO,L          ,ENNE       ,DT         ,XMIN       ,XMAX       ,&
                    YMIN       ,YMAX       ,ZMIN       ,ZMAX , PI, GEN_RANDOM_NUMBER,START_TIME,END_TIME
DOUBLE PRECISION, DIMENSION(:,:,:), ALLOCATABLE ::      V,V_GLOB
DOUBLE PRECISION, DIMENSION(:,:), ALLOCATABLE ::        X_EDDY     ,EPSILO     ,MOLT, DATAVEC
DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE ::          K
DOUBLE PRECISION, DIMENSION(:) ::           X_POINT(3)             ,REYNOLDS(6)            ,TEMP(3)    ,TEMP2(3)   ,&
                                            U(3)
DOUBLE PRECISION :: TMPE,RAND
REAL :: rand_number
DOUBLE PRECISION, DIMENSION(:) :: VEL_AVERAGE(3),VEL2_AVERAGE(6),VEL3_AVERAGE(3),&
                                  VEL4_AVERAGE(3),VEL2_AVERAGE_DEF(3),VELMIX_AVERAGE_DEF(3),&
                                  VEL3_AVERAGE_DEF(3),VEL4_AVERAGE_DEF(3)
DOUBLE PRECISION, DIMENSION(:,:) :: R(3,3)
INTEGER ::          DIVY       ,DIVZ       ,IY         ,IZ         ,II          ,N          ,IT         ,ITMAX     ,&
                    P          ,INDIX      ,POST_PROCESSING, IDXY, IDXZ, KIDX
INTEGER :: MYRANK,SIZE_MPI,IERR,N_part,nseed
INTEGER, ALLOCATABLE :: seed(:)
CHARACTER*43::      FILETEST1  ,FILETEST2  ,FILETEST3  ,FILETEST4  ,FILETEST5  ,FILETEST6  ,FILETEST7  ,FILETEST8  ,&
                    FILETEST9  ,FILETEST10
CHARACTER*26 ::     FILE_LOCATION
CHARACTER*44 ::     FILEGLOBAL

!-----------------------------------------------------------------|
!---------------------USER MODIFICLABLE AREA----------------------|
!-----------------------------------------------------------------|

! PARALLEL COMPUTATION INITIATION

!CALL MPI_INIT(IERR)
!CALL MPI_COMM_RANK(MPI_COMM_WORLD,MYRANK,IERR)
!CALL MPI_COMM_SIZE(MPI_COMM_WORLD,SIZE_MPI,IERR)

! Initialize the random number generator

CALL RANDOM_SEED()
CALL RANDOM_SEED(size = nseed)
ALLOCATE(seed(nseed))
MYRANK = 0
seed = 12 + MYRANK*12
CALL RANDOM_SEED(put=seed(1:nseed))
DEALLOCATE(seed)


![U0] IS THE BACKGROUND VELOCITY

U = (/ 10.0D0, 0.0D0, 0.0D0 /)  ![M/S]

![REYNOLDS(6)] IS A VECTOR WITH THE SIX ELEMENTS OF REYNOLDS STRESSES. THE ELEMENT MUST
!BE REPORTED AS FOLLOWS:
!
!  |REYNOLDS(1)  REYNOLDS(2)  REYNOLDS(4)|
!  |REYNOLDS(2)  REYNOLDS(3)  REYNOLDS(5)|
!  |REYNOLDS(4)  REYNOLDS(5)  REYNOLDS(6)|

REYNOLDS = (/ 0.5D0, 0.0D0, 2.25D0, 0.0D0, 0.0D0, 0.5D0 /)  ![M/S]

![SIGMA] IS THE EDDY LENGH-SCALE

SIGMA = 0.5D0

!THE BOX DIMENSIONS ARE DIFINED AS [XLENGHT] * [L] * [L]
![DIVX], [DIVY] & [DIVZ] ARE THE NUMBERS OF SPACIAL POINTS. [DT] IS THE TIME STEP

PI = ACOS(0.0D0)
L = PI
DIVY = 64
DIVZ = 64
DT = 0.125D0 * SIGMA / U(1)

IDXY = 32
IDXZ = 32

!THE USER CAN MODIFY THE TIME STEP NUMBER [ITMAX] AND THE EDDIES NUMBER [N]
!WITH [P] THE USER CAN MODIFY THE OUTPUT DATA. THE PROGRAM CREATE A GLOBAL VELOCITY
!OUTPUT FILE EVERY [P] TIME STEPS.
!WARNING: [N] AND [ENNE] REPRESENT THE SAME PARAMETER! THE ONLY DIFFERENCE IS THAT [N]
!IS A INTEGER WHILE [ENNE] IS A REAL USED FOR SOME FARTHER CALCULATIONS.

ITMAX = 10000
N = 500
ENNE = N
P = 10

!ALLOCATION OF THE EDDIES VECTOR.
![V(DIVX,DIVY,DIVZ,3)] IS THE INSTANTANEOUS VELOCITY VECTOR IN THE POINT WITH
!X,Y,Z COMPONENTS
![X_EDDY(3,N)] IS THE N-TH EDDY LOCATION X,Y,Z
![EPSILO(3,N)] IS THE N-TH EDDY INTENSITY IN X,Y,Z
![MOLT(3,N)] IS THE MATRIX PRODUCT [R(3,3)] * [EPSILO(3,N)]
![K(N)] IS A VECTOR USED TO CHECK WHITCH EDDY IS OUTSIDE THE BOX AFTER THE CONVECTION

ALLOCATE(V(DIVY,DIVZ,3))
ALLOCATE(X_EDDY(3,N))
ALLOCATE(EPSILO(3,N))
ALLOCATE(MOLT(3,N))
ALLOCATE(K(N))
ALLOCATE(DATAVEC(ITMAX,15))

![FILE_LOCATION] SET THE DIRECTORY WHERE THE OUTPUT FILES WILL BE STORED (MAX 26 CHARACTERS)

FILE_LOCATION = ""

![POST_PROCESSING] SET IF DO OR NOT THE DATA POST PROCESSING. IT CALL A SOUBROUTINE THAT CREATE A
!FILE IN THE DIRECTORI SPECIFIED, WITH ALL POST-PROCESSING DATA
! 1 - DO POST PROCESSING

POST_PROCESSING = 1

!-----------------------------------------------------------------|
!------------------END OF USER MODIFICLABLE AREA------------------|
!-----------------------------------------------------------------|

!POST PROCESSOR VARIABLES
VEL_AVERAGE(:) = (/ 0.0D0, 0.0D0, 0.0D0 /)
VEL2_AVERAGE(:) = (/ 0.0D0, 0.0D0, 0.0D0 ,0.0D0, 0.0D0, 0.0D0/)
VEL3_AVERAGE(:) = (/ 0.0D0, 0.0D0, 0.0D0 /)
VEL4_AVERAGE(:) = (/ 0.0D0, 0.0D0, 0.0D0 /)


PRINT *, "TOTAL TIME INTERVAL = ", DT * ITMAX, " [S]"

!CALCULATION OF THE EDDY BOX PARAMETERS

XMIN = 0.0D0 - SIGMA
XMAX = 0.0D0 + SIGMA
YMIN = 0.0D0 - SIGMA
YMAX = L + SIGMA
ZMIN = 0.0D0 - SIGMA
ZMAX = L + SIGMA

VOL = (XMAX - XMIN) * (YMAX - YMIN) * (ZMAX - ZMIN)

!GENERATION OF THE EDDY LOCATION INSIDE THE BOX AND INITIALIZATION OF THE [K] VECTOR


!PRINT *, "Initialize Eddys"

!DO II=1,10

!CALL RANDOM_NUMBER(rand_number)
!PRINT *, "Random number:", GEN_RANDOM_NUMBER(0.0D0)

!END DO

DO II=1,N
  
  X_EDDY(1,II) = (XMAX - XMIN) * GEN_RANDOM_NUMBER(0.0D0) + XMIN
  X_EDDY(2,II) = (YMAX - YMIN) * GEN_RANDOM_NUMBER(0.0D0) + YMIN
  X_EDDY(3,II) = (ZMAX - ZMIN) * GEN_RANDOM_NUMBER(0.0D0) + ZMIN
  K(II) = 0

!INITIALIZATION OF THE INTENSITIES. FOR EVERY DIRECTION THE AVERAGE INTENSITY VALUE IS CALCULATED AND
!IT IS FORCED TO BE LOWER THAN THE [VLIM] VALUE


  EPSILO(1,II) = GENEREPSILO(0.0D0)
  EPSILO(2,II) = GENEREPSILO(0.0D0)
  EPSILO(3,II) = GENEREPSILO(0.0D0)
END DO

!INITIALIZATION OF THE [R(3,3)] MATRIX WITH THE CHOLENSKY DECOMPOSITION
!OF THE REYNOLDS STRESS TENSOR

!PRINT *, "Set RS Tensor"

DO IY= 1,3
  DO IZ = 1,3
    R(IY,IZ) = 0
  END DO
END DO

R(1,1) = SQRT(REYNOLDS(1))
R(2,1) = REYNOLDS(2) / R(1,1)
R(2,2) = SQRT(REYNOLDS(3) - R(2,1) * R(2,1))
R(3,1) = REYNOLDS(4) / R(1,1)
R(3,2) = (REYNOLDS(5) - R(2,1) * R(3,1)) / R(2,2)
R(3,3) = SQRT(REYNOLDS(6) - R(3,1) * R(3,1) - R(3,2) * R(3,2))

!BEGINNING OF TIME ITERATIONS
PRINT *, "ITERATION STARTING ..."

DO IT=1,ITMAX

  INDIX = 0
 

!PRINTINGS OF GLOBAL VELOCITY AND OF CONVECTION VELOCITY
  IF (IT==1 .OR. MOD(IT,P)==0 .OR. IT==ITMAX) THEN
     WRITE(*,*) "ITERATION ", IT, "IN PROGRESS. TIME: ",(IT-1) * DT,' [S]'
  END IF

  MOLT = MATMUL(R,EPSILO)

!------BEGINNING OF SPATIAL ITERATION

  !DO IY = 1,DIVY
  !  DO IZ = 1,DIVZ
   DO KIDX = 1, DIVY*DIVZ     

       IY = MOD(KIDX-1,DIVY)+1
       IZ = (KIDX-1)/DIVY + 1
       !X_POINT = GRID POINT COORDINATES
       X_POINT = (/ 0.0D0, (IY-1) * L/(DIVY -1) + YMIN, (IZ-1) * L/(DIVZ-1)+ ZMIN /)

      V(IY,IZ,:) = (/ 0.0D0, 0.0D0, 0.0D0 /)

!------------BEGINNING OF EDDIES ITERATIONS

      DO II=1,N
        !TEMP = (XPOINT - XEDDY) / SIGMA
        TEMP(:) = ABS(X_POINT(:) - X_EDDY(:,II))/SIGMA

        IF (TEMP(1).LT.1.0D0 .AND. TEMP(2).LT.1.0D0 .AND. TEMP(3).LT.1.0D0) THEN
          TEMP2 = MOLT(:,II)
          V(IY,IZ,:) = V(IY,IZ,:) + TEMP2 * (SQRT(VOL) * SQRT(1.5D0)**3.0D0 * &
          (1.0D0 - TEMP(1)) * (1.0D0 - TEMP(2)) * (1.0D0 - TEMP(3)))/ SQRT(SIGMA**3.0D0)
        END IF

      END DO

!-----------END OF EDDIES ITERATIONS

      V(IY,IZ,:) = (V(IY,IZ,:) / SQRT(ENNE)) + U(:)


  ! END DO
  END DO

!------END OF SPATIAL ITERATIONS

!THIS IS THE POST-PROCESSING PART, ACTIVATED ONLY IF [POST_PROCESSING] == 1
  IF (POST_PROCESSING == 1) THEN
    VEL_AVERAGE(:) = (V(IDXY,IDXZ,:) + VEL_AVERAGE(:) * (IT-1)) / IT
    VEL2_AVERAGE(:) = ((/V(IDXY,IDXZ,1)**2,V(IDXY,IDXZ,2)**2,V(IDXY,IDXZ,3)**2,V(IDXY,IDXZ,1)*V(IDXY,IDXZ,2), &
			 V(IDXY,IDXZ,1)*V(IDXY,IDXZ,3), V(IDXY,IDXZ,2)*V(IDXY,IDXZ,3) /) + VEL2_AVERAGE(:) * (IT-1)) / IT
    TEMP(:) = V(IDXY,IDXZ,:)-U(:)
    VEL3_AVERAGE(:) = ((/ TEMP(1)**3, TEMP(2)**3, TEMP(3)**3 /) + VEL3_AVERAGE(:) * (IT-1)) / IT
    VEL4_AVERAGE(:) = ((/ TEMP(1)**4, TEMP(2)**4, TEMP(3)**4 /) + VEL4_AVERAGE(:) * (IT-1)) / IT 
 
    VEL2_AVERAGE_DEF(:) = VEL2_AVERAGE(1:3) - (/ VEL_AVERAGE(1)**2, VEL_AVERAGE(2)**2, VEL_AVERAGE(3)**2 /)
    VELMIX_AVERAGE_DEF(:) = VEL2_AVERAGE(4:6) - (/ VEL_AVERAGE(1)*VEL_AVERAGE(2), VEL_AVERAGE(1)*VEL_AVERAGE(3), &
                                                   VEL_AVERAGE(2)*VEL_AVERAGE(3)  /)

    VEL3_AVERAGE_DEF(1) = VEL3_AVERAGE(1) / VEL2_AVERAGE_DEF(1)**(3/2)
    VEL3_AVERAGE_DEF(2) = VEL3_AVERAGE(2) / VEL2_AVERAGE_DEF(2)**(3/2)
    VEL3_AVERAGE_DEF(3) = VEL3_AVERAGE(3) / VEL2_AVERAGE_DEF(3)**(3/2)

    VEL4_AVERAGE_DEF(1) = VEL4_AVERAGE(1) / VEL2_AVERAGE_DEF(1)**(2)
    VEL4_AVERAGE_DEF(2) = VEL4_AVERAGE(2) / VEL2_AVERAGE_DEF(2)**(2)
    VEL4_AVERAGE_DEF(3) = VEL4_AVERAGE(3) / VEL2_AVERAGE_DEF(3)**(2)


   DATAVEC(IT,:) = (/VEL_AVERAGE(1),VEL_AVERAGE(2),VEL_AVERAGE(3),VEL2_AVERAGE_DEF(1),VEL2_AVERAGE_DEF(2),VEL2_AVERAGE_DEF(3), &
		     VELMIX_AVERAGE_DEF(1),VELMIX_AVERAGE_DEF(2),VELMIX_AVERAGE_DEF(3),VEL3_AVERAGE_DEF(1),VEL3_AVERAGE_DEF(2), &
 	   	     VEL3_AVERAGE_DEF(3),VEL4_AVERAGE_DEF(1),VEL4_AVERAGE_DEF(2),VEL4_AVERAGE_DEF(3) /)

  ENDIF

!--------BEGINNING OF EDDIES CONVECTION ITERATIONS

  DO II=1,N

    !RE-CALCULATION OF THE EDDIES POSITION. IF ANY EDDY GOES BEYOND THE BOX LIMITS
    !IT IS RESTARTED AT THE SURFACE FACING THE EXIT.
    X_EDDY(1,II) = X_EDDY(1,II) + U(1) * DT
    X_EDDY(2,II) = X_EDDY(2,II) + U(2) * DT
    X_EDDY(3,II) = X_EDDY(3,II) + U(3) * DT

    !AFTER THE EDDIES CONVECTIONS ARE NECESSARY SOME TESTS TO CHECK IF ANY EDDY IS NOW OUTSIDE
    !THE SEM BOX DEFINED EARLIER
    !WHEN A EDDY IS RE-GENERATE THE K(I) FACTOR ASSUME THE 1 VALUE. THIS VALUE IS USED LATER TO
    !GENERATE A NEW INTENSITY FOR THE NEW EDDY
    IF (X_EDDY(1,II) > XMAX) THEN
      X_EDDY(1,II) = XMIN
      X_EDDY(2,II) = (YMAX - YMIN) * GEN_RANDOM_NUMBER(0.0D0) + YMIN
      X_EDDY(3,II) = (ZMAX - ZMIN) * GEN_RANDOM_NUMBER(0.0D0) + ZMIN
      K(II) = 1
    ELSE IF (X_EDDY(1,II) < XMIN) THEN
      X_EDDY(1,II) = XMAX
      X_EDDY(2,II) = (YMAX - YMIN) * GEN_RANDOM_NUMBER(0.0D0) + ZMIN
      X_EDDY(3,II) = (ZMAX - ZMIN) * GEN_RANDOM_NUMBER(0.0D0) + ZMIN
      K(II) = 1
    ELSE IF (X_EDDY(2,II) > YMAX) THEN
      X_EDDY(1,II) = (XMAX - XMIN) * GEN_RANDOM_NUMBER(0.0D0) + XMIN
      X_EDDY(2,II) = YMIN
      X_EDDY(3,II) = (ZMAX - ZMIN) * GEN_RANDOM_NUMBER(0.0D0) + ZMIN
      k(II) = 1
    ELSE IF (X_EDDY(2,II) < YMIN) THEN
      X_EDDY(1,II) = (XMAX - XMIN) * GEN_RANDOM_NUMBER(0.0D0) + XMIN
      X_EDDY(2,II) = YMAX
      X_EDDY(3,II) = (ZMAX - ZMIN) * GEN_RANDOM_NUMBER(0.0D0) + ZMIN
      K(II) = 1
    ELSE IF  (X_EDDY(3,II) > ZMAX) THEN
      X_EDDY(1,II) = (XMAX - XMIN) * GEN_RANDOM_NUMBER(0.0D0) + XMIN
      X_EDDY(2,II) = (YMAX - YMIN) * GEN_RANDOM_NUMBER(0.0D0) + ZMIN
      X_EDDY(3,II) = ZMIN 
      K(II) = 1
    ELSE IF (X_EDDY(3,II) < ZMIN) THEN
      X_EDDY(1,II) = (XMAX - XMIN) * GEN_RANDOM_NUMBER(0.0D0) + XMIN
      X_EDDY(2,II) = (YMAX - YMIN) * GEN_RANDOM_NUMBER(0.0D0) + ZMIN
      X_EDDY(3,II) = ZMAX
      K(II) = 1
    END IF

    !INTENSITY GENERATION FOR THE RE-CREATED EDDIES. WE ARE USING THE K FACTOR AS EXPLAINED FATOR.
    IF (K(II)== 1) THEN
      EPSILO(3,II) = GENEREPSILO(0.0D0)
      EPSILO(2,II) = GENEREPSILO(0.0D0)
      EPSILO(1,II) = GENEREPSILO(0.0D0)
    END IF

    K(II) = 0

  END DO

!---------END OF EDDIES CONVECTIONS ITERATIONS

  IF (U(1) < 0 .OR. U(1) > 20) THEN
    PRINT *, "PROTRAM VELOCITY ERROR @ ", IT, "-TH ITERATION. SPEED EXCEED LIMIT VALUE U(1) = ", U(1)
    EXIT
  END IF

END DO



  !open(out_unit, file="output.dat", access="stream")
  !write(out_unit) results

OPEN (UNIT=55, FILE='test.dat',FORM='unformatted', ACCESS="stream") !, STATUS="UNKNOWN", ACTION="WRITE"
WRITE(55) DATAVEC

!----END OF TIME ITERATIONS

CLOSE (UNIT=11)
CLOSE (UNIT=21)
CLOSE (UNIT=31)
CLOSE (UNIT=41)
CLOSE (UNIT=51)
CLOSE (UNIT=61)
CLOSE (UNIT=71)
CLOSE (UNIT=81)
CLOSE (UNIT=91)
 CLOSE (UNIT=55)

END PROGRAM SEMEQUATIONS

FUNCTION GEN_RANDOM_NUMBER(X) !FUNCTION FOR CALLING A RANDOM NUMBER

DOUBLE PRECISION :: GEN_RANDOM_NUMBER,X

CALL RANDOM_NUMBER(GEN_RANDOM_NUMBER)

END FUNCTION GEN_RANDOM_NUMBER



!-------------------------------------------------------
FUNCTION GENEREPSILO(X)  !FUNCTION FOR EDDIES INTENSITY GENERATION

DOUBLE PRECISION :: GENEREPSILO, X, RANDOM, GEN_RANDOM_NUMBER

DO 
  GENEREPSILO = (GEN_RANDOM_NUMBER(0.0D0) * 2.0D0 - 1.0D0)
  IF (GENEREPSILO /= 0.0D0) THEN
    EXIT
  END IF
END DO

GENEREPSILO = FLOOR(GENEREPSILO)
IF (GENEREPSILO == 0.0D0) THEN
  GENEREPSILO = 1
END IF


END FUNCTION GENEREPSILO

!---------------------------------------------------------


