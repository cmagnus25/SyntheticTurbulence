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

PROGRAM DAVBIL
USE MatrixOperations

IMPLICIT NONE

DOUBLE PRECISION :: VOL        ,GENEREPSILO,L          ,ENNE       ,DT         ,XMIN       ,XMAX       ,&
                    YMIN       ,YMAX       ,ZMIN       ,ZMAX , PI, GEN_RANDOM_NUMBER,START_TIME,END_TIME
DOUBLE PRECISION, DIMENSION(:,:,:), ALLOCATABLE ::      V,V_GLOB
DOUBLE PRECISION, DIMENSION(:,:), ALLOCATABLE ::        DATAVEC, KAP, SIGMA, SIGMA_P, K_P
DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE ::          K, PHI, PSI, ALPHA, THETA
DOUBLE PRECISION, DIMENSION(:) ::     X_POINT(3), REYNOLDS(6), TEMP(3), TEMP2(3), TEMP1(3), &
				      TEMP3(3), TEMP4(3), U(3), VELFLU(3), X_POINT_P(3), &
				      SQRTEIGVAL(3), ISQRTEIGVAL(3)
DOUBLE PRECISION :: TMPE,RAND, DELTA, DELTAMIN, KEY, KE, KEYMAX, TAU, ACOEFF, BCOEFF, &
		    EPS, NU, UCAP, ARGUMENT, DELTAKEY, LT, ENERGY, KETA, TRACE, URMS, KIN, PDAVBIL, &
		    SCALINGPARAM, AMP, KNORM
REAL :: rand_number
DOUBLE PRECISION, DIMENSION(:) :: VEL_AVERAGE(3),VEL2_AVERAGE(6),VEL3_AVERAGE(3),&
                                  VEL4_AVERAGE(3),VEL2_AVERAGE_DEF(3),VELMIX_AVERAGE_DEF(3),&
                                  VEL3_AVERAGE_DEF(3),VEL4_AVERAGE_DEF(3), EIGVAL(3), K_DIR(3), &
				  EPSILO2(3), TMPVEC(3)	
DOUBLE PRECISION, DIMENSION(:,:) :: R(3,3), ROT(3,3),ROTT(3,3), TMPMAT(3,3)
INTEGER :: DIVY       ,DIVZ       ,IY         ,IZ         ,II          ,N          ,IT         ,ITMAX     ,&
                    P          ,INDIX      ,POST_PROCESSING, IDXY, IDXZ, KIDX
INTEGER :: MYRANK,SIZE_MPI,IERR,N_part,nseed, stat = 0, I, J
INTEGER, ALLOCATABLE :: seed(:)
CHARACTER*43::      FILETEST1  ,FILETEST2  ,FILETEST3  ,FILETEST4  ,FILETEST5  ,FILETEST6  ,FILETEST7  ,FILETEST8  ,&
                    FILETEST9  ,FILETEST10
CHARACTER*26 ::     FILE_LOCATION
CHARACTER*44 ::     FILEGLOBAL
LOGICAL	     ::     ISPRINT

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

U = (/ 1.0D0, 0.0D0, 0.0D0 /)  ![M/S]

!  |REYNOLDS(1)  REYNOLDS(2)  REYNOLDS(4)|
!  |REYNOLDS(2)  REYNOLDS(3)  REYNOLDS(5)|
!  |REYNOLDS(4)  REYNOLDS(5)  REYNOLDS(6)|

!REYNOLDS = (/ 1.9670D0, 0.4296D0, 1.5472D0, 0.3955D0, -0.5678D0, 1.9727D0 /)  ![M/S]
REYNOLDS = (/ 0.75D0, -0.66D0, 3.19D0, 0.0D0, 0.0D0, 1.49D0 /)  ![M/S]
!REYNOLDS = (/ 0.75D0, -0.66D0, 3.19D0, 0.33D0, 0.88D0, 1.49D0 /)  ![M/S]
!REYNOLDS = (/ 7.66D0, 0.66D0, 0.319D0, 0.0D0, 0.0D0, 1.49D0 /)  ![M/S]
!REYNOLDS = (/ 2.75D0, -0.66D0, 3.19D0, 0.0D0, 0.0D0, 1.49D0 /)  ![M/S]
!REYNOLDS = (/ 7.67D0, -0.66D0, 0.32D0, 0.0D0, 0.0D0, 1.50D0 /)  ![M/S]

KIN = 0.5D0 * (REYNOLDS(1) + REYNOLDS(3) + REYNOLDS(6)) 

![DIVX], [DIVY] & [DIVZ] ARE THE NUMBERS OF SPACIAL POINTS. [DT] IS THE TIME STEP

PI = 2.0D0*ASIN(1.0D0)
L = PI
DIVY = 1 ! 64
DIVZ = 1 ! 64 


IDXY = 1 ! 32
IDXZ = 1 ! 32


ITMAX = 50000
N = 150	 ! Modes
ENNE = N
P = 5000

! SETTINGS

DELTAMIN = 0.004D0 !0.004D0
PDAVBIL = 2.0D0
AMP = 1.453D0

DT = 0.0123D0 !0.125D0 * DELTA / U(1)
NU = 15.2D-6   !1.0D0/395.0D0

SCALINGPARAM = SQRT(10.0D0)

LT = 0.11D0 !0.11D0  !0.2D0*DELTA
EPS = KIN**(1.5D0)/LT !40.88D0 !4.0D0**(1.5D0/(0.1D0*DELTA))
URMS = SQRT(2.0D0*KIN/3.0D0)


KEYMAX = 2.0D0 * PI / DELTAMIN
KE = AMP * 9.0D0 * PI / (55.0D0 * LT)
DELTAKEY = (KEYMAX - KE/PDAVBIL) / (ENNE - 1.0D0)

TAU = 0.22D0 !0.2D0 * DELTA / U(1)
ACOEFF = EXP(-DT / TAU)
BCOEFF = SQRT(1.0D0 - ACOEFF**2)

KETA = EPS**(0.25D0) * NU**(-0.75D0)

!PRINT *, KEYMAX
!PRINT *, KE
!PRINT *, DELTAKEY

!ISPRINT = .FALSE.
ISPRINT = .TRUE.

IF (ISPRINT) THEN
PRINT *, "=================================================="
PRINT *, "N: ", N
PRINT *, "Nit: ", ITMAX
PRINT *, "Lt: ", LT
PRINT *, "TAU: ", TAU
PRINT *, "p: ", PDAVBIL
PRINT *, "VISC: ", NU
PRINT *, "DT: ", DT
PRINT *, "TURBKIN: ", KIN
PRINT *, "URMS: ", URMS
PRINT *, "ACOEFF: ", ACOEFF
PRINT *, "BCOEFF: ", BCOEFF
PRINT *, "Kappa max: ", KEYMAX
PRINT *, "Kappa e: ", KE
PRINT *, "Kappa 1: ", KE / PDAVBIL
PRINT *, "Delta Kappa: ", DELTAKEY
PRINT *, "Kappa Eta: ", KETA
PRINT *, "=================================================="
END IF

ALLOCATE(V(DIVY,DIVZ,3))
ALLOCATE(PSI(N))
ALLOCATE(PHI(N))
ALLOCATE(ALPHA(N))
ALLOCATE(THETA(N))
ALLOCATE(KAP(3,N))
ALLOCATE(SIGMA(3,N))
ALLOCATE(SIGMA_P(3,N))
ALLOCATE(K_P(3,N))
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

R(1,1) = REYNOLDS(1)
R(1,2) = REYNOLDS(2)
R(1,3) = REYNOLDS(4)
R(2,1) = REYNOLDS(2)
R(2,2) = REYNOLDS(3)
R(2,3) = REYNOLDS(5)
R(3,1) = REYNOLDS(4)
R(3,2) = REYNOLDS(5)
R(3,3) = REYNOLDS(6)

! DIVIDE BY TRACE(RIJ) TIMES 3 TO NORMALIZE?
TRACE = R(1,1) + R(2,2) + R(3,3)

R = 3.0D0*R/TRACE

!CALL DSYEVJ3(R, EVEROT, EIGVAL)
CALL RS(3,3,R,EIGVAL,1,ROT,TEMP3,TEMP4,IERR)

SQRTEIGVAL = SQRT(EIGVAL)
ISQRTEIGVAL = 1.0D0 / SQRTEIGVAL

ROTT = TRANSPOSE(ROT)

IF (ISPRINT) THEN
PRINT *, "Eigenvalues: "
PRINT *, EIGVAL
PRINT *, "Rotation matrix: "
DO I = 1,3
    WRITE(*,*) ( ROT(I,J), J=1,3)
END DO



PRINT *, "=================================================="
END IF

PRINT *, "TOTAL TIME INTERVAL = ", DT * ITMAX, " [S]"


!INITIALIZATION OF THE [R(3,3)] MATRIX WITH THE CHOLENSKY DECOMPOSITION
!OF THE REYNOLDS STRESS TENSOR

!PRINT *, "Set RS Tensor"

!DO IY= 1,3
!  DO IZ = 1,3
!    R(IY,IZ) = 0
!  END DO
!END DO


!BEGINNING OF TIME ITERATIONS
PRINT *, "ITERATION STARTING ..."

DO IT=1,ITMAX

  INDIX = 0

!PRINTINGS OF GLOBAL VELOCITY AND OF CONVECTION VELOCITY
  IF (IT==1 .OR. MOD(IT,P)==0 .OR. IT==ITMAX) THEN
     WRITE(*,*) "ITERATION ", IT, "IN PROGRESS. TIME: ",(IT-1) * DT,' [S]'
  END IF

KEY = KE / PDAVBIL + 0.5D0 * DELTAKEY

DO II=1,N
  PHI(II) = 2.0D0 * PI * GEN_RANDOM_NUMBER(0.0D0)
  PSI(II) = 2.0D0 * PI * GEN_RANDOM_NUMBER(0.0D0)
  ALPHA(II) = 2.0D0 * PI * GEN_RANDOM_NUMBER(0.0D0)
  THETA(II) = ACOS(-2.0D0 * GEN_RANDOM_NUMBER(0.0D0) + 1.0D0)

  KAP(1,II) = KEY * SIN(THETA(II)) * COS(PHI(II))
  KAP(2,II) = KEY * SIN(THETA(II)) * SIN(PHI(II))
  KAP(3,II) = KEY * COS(THETA(II))

  K_P(:,II) = MATMUL(ROTT,KAP(:,II)) * ISQRTEIGVAL


  SIGMA(1,II) = COS(PHI(II)) * COS(THETA(II)) * COS(ALPHA(II)) + &
		(-1.0D0) * SIN(PHI(II)) * SIN(ALPHA(II))
  SIGMA(2,II) = COS(THETA(II)) * SIN(PHI(II)) * COS(ALPHA(II)) + &
		COS(PHI(II)) * SIN(ALPHA(II))
  SIGMA(3,II) = (-1.0D0) * SIN(THETA(II)) * COS(ALPHA(II))

  SIGMA_P(:,II) = MATMUL(ROTT,SIGMA(:,II)) * SQRTEIGVAL
		
  KEY = KEY + DELTAKEY

  !TMPE = KAP(1,II) * SIGMA(1,II) + KAP(2,II) * SIGMA(2,II)+ KAP(3,II) * SIGMA(3,II) 

  !PRINT *, TMPE
END DO

!PRINT *, ACOEFF
!PRINT *, BCOEFF


!PRINT *, KE

!PRINT *, "TERMINATING"
!CALL EXIT(IERR)
!------BEGINNING OF SPATIAL ITERATION

  DO IY = 1,DIVY
    DO IZ = 1,DIVZ
  ! DO KIDX = 1, DIVY*DIVZ     

  !     IY = MOD(KIDX-1,DIVY)+1
   !    IZ = (KIDX-1)/DIVY + 1
       !X_POINT = GRID POINT COORDINATES
       !X_POINT = (/ 0.0D0, (IY-1) * L/(DIVY -1) + YMIN, (IZ-1) * L/(DIVZ-1)+ ZMIN /)
       X_POINT = (/0.0D0, 0.5D0*PI, 0.5D0*PI/)

       !KETA = EPS**(0.25D0) * NU**(-0.75D0)

       V(IY,IZ,:) = (/ 0.0D0, 0.0D0, 0.0D0 /)
       VELFLU = 0.0D0

       X_POINT_P = MATMUL(ROTT,X_POINT)

!------------BEGINNING OF EDDIES ITERATIONS

       KEY = KE / PDAVBIL + (0.5D0 * DELTAKEY)

       DO II=1,N

	!K AND SIGMA IN PRINCIPAL SYSTEM

	

	KNORM = SQRT(KAP(1,II)**2.D0 + KAP(2,II)**2.D0 + KAP(3,II)**2.D0)

	! NORMALIZE K AND SIGMA
	!K_P = K_P * ISQRTEIGVAL

	!TMPE = K_P(1) * SIGMA_P(1) + K_P(2) * SIGMA_P(2) + K_P(3) * SIGMA_P(3) 

	!KNORM = SQRT(KAP(1,II)**2.D0 + KAP(2,II)**2.D0 + KAP(3,II)**2.D0)

	!IF (KNORM < KEYMAX) THEN
	
	ENERGY = AMP * URMS**2.0D0 / KE * ( KNORM / KE)**4.0D0 / &
		 (1.0D0 + (KNORM/KE)**2.0D0)**(17.0D0/6.0D0) * &
		 EXP(-2.0D0 * ( KNORM/KETA )**2.0D0)
 	UCAP = SQRT(ENERGY * DELTAKEY)

	!PRINT *, "KEY ", KEY
	!PRINT *, "ETA ", KETA
	!PRINT *, "ENERGY ",ENERGY
	!PRINT *, "UN ", UCAP

	KEY = KEY + DELTAKEY
			
	ARGUMENT = DOT_PRODUCT(K_P(:,II),X_POINT_P) + PSI(II)

	!IF (IY == 2 .AND. IZ == 2) THEN
	!TMPE = MEAN
	!MEAN = (SIGMA_P(2) + MEAN * (II-1)) / II
	!VAR = VAR + (SIGMA_P(2) - TMPE) / (SIGMA_P(2) - MEAN) 
	!PRINT *, ARGUMENT
	!PRINT *,SIGMA_P(2)
	!END IF

	VELFLU = VELFLU + SCALINGPARAM * UCAP * COS(ARGUMENT) * SIGMA_P(:,II)

	!END IF

       END DO

	!PRINT *, 
	!IF (IY == 2 .AND. IZ == 2) THEN
	!PRINT *, MEAN
	!PRINT *, VAR
	!CALL EXIT(IERR)
	!END IF

	VELFLU = VELFLU * 2.0D0

	VELFLU = MATMUL(ROT,VELFLU)

!		IF (IY == 2 .AND. IZ == 2) THEN
!PRINT *, EVEROT
!PRINT *, X_POINT_P
!PRINT *, VELFLU
!CALL EXIT(IERR)
!END IF

	IF (IT .GT. 1) THEN
	  VELFLU(1) = ACOEFF * V(IY,IZ,1) + BCOEFF * VELFLU(1)
	  VELFLU(2) = ACOEFF * V(IY,IZ,2) + BCOEFF * VELFLU(2)
	  VELFLU(3) = ACOEFF * V(IY,IZ,3) + BCOEFF * VELFLU(3)
	END IF
	 
	V(IY,IZ,1) = VELFLU(1) !+ U(1)
	V(IY,IZ,2) = VELFLU(2)
	V(IY,IZ,3) = VELFLU(3)        




   END DO
  END DO




!------END OF SPATIAL ITERATIONS

!THIS IS THE POST-PROCESSING PART, ACTIVATED ONLY IF [POST_PROCESSING] == 1
  IF (POST_PROCESSING == 1) THEN
    VEL_AVERAGE(:) = (V(IDXY,IDXZ,:) + VEL_AVERAGE(:) * (IT-1)) / IT
    VEL2_AVERAGE(:) = ((/V(IDXY,IDXZ,1)**2.0D0,V(IDXY,IDXZ,2)**2.0D0,V(IDXY,IDXZ,3)**2.0D0,V(IDXY,IDXZ,1)*V(IDXY,IDXZ,2), &
			 V(IDXY,IDXZ,1)*V(IDXY,IDXZ,3), V(IDXY,IDXZ,2)*V(IDXY,IDXZ,3) /) + VEL2_AVERAGE(:) * (IT-1)) / IT
    TEMP(:) = V(IDXY,IDXZ,:)-U(:)
    VEL3_AVERAGE(:) = ((/ TEMP(1)**3.0D0, TEMP(2)**3.0D0, TEMP(3)**3.0D0 /) + VEL3_AVERAGE(:) * (IT-1)) / IT
    VEL4_AVERAGE(:) = ((/ TEMP(1)**4.0D0, TEMP(2)**4.0D0, TEMP(3)**4.0D0 /) + VEL4_AVERAGE(:) * (IT-1)) / IT 
 
    VEL2_AVERAGE_DEF(:) = VEL2_AVERAGE(1:3) - (/ VEL_AVERAGE(1)**2, VEL_AVERAGE(2)**2.0D0, VEL_AVERAGE(3)**2.0D0 /)
    VELMIX_AVERAGE_DEF(:) = VEL2_AVERAGE(4:6) - (/ VEL_AVERAGE(1)*VEL_AVERAGE(2), VEL_AVERAGE(1)*VEL_AVERAGE(3), &
                                                   VEL_AVERAGE(2)*VEL_AVERAGE(3)  /)

    VEL3_AVERAGE_DEF(1) = VEL3_AVERAGE(1) / VEL2_AVERAGE_DEF(1)**(1.5D0)
    VEL3_AVERAGE_DEF(2) = VEL3_AVERAGE(2) / VEL2_AVERAGE_DEF(2)**(1.5D0)
    VEL3_AVERAGE_DEF(3) = VEL3_AVERAGE(3) / VEL2_AVERAGE_DEF(3)**(1.5D0)

    VEL4_AVERAGE_DEF(1) = VEL4_AVERAGE(1) / VEL2_AVERAGE_DEF(1)**(2.0D0)
    VEL4_AVERAGE_DEF(2) = VEL4_AVERAGE(2) / VEL2_AVERAGE_DEF(2)**(2.0D0)
    VEL4_AVERAGE_DEF(3) = VEL4_AVERAGE(3) / VEL2_AVERAGE_DEF(3)**(2.0D0)


!   DATAVEC(IT,:) = (/VEL_AVERAGE(1),VEL_AVERAGE(2),VEL_AVERAGE(3),VEL2_AVERAGE_DEF(1),VEL2_AVERAGE_DEF(2),VEL2_AVERAGE_DEF(3), &
DATAVEC(IT,:) = (/V(IDXY,IDXZ,1),V(IDXY,IDXZ,2),V(IDXY,IDXZ,3),VEL2_AVERAGE_DEF(1),VEL2_AVERAGE_DEF(2),VEL2_AVERAGE_DEF(3), &
	VELMIX_AVERAGE_DEF(1),VELMIX_AVERAGE_DEF(2),VELMIX_AVERAGE_DEF(3),VEL3_AVERAGE_DEF(1),VEL3_AVERAGE_DEF(2), &
VEL3_AVERAGE_DEF(3),VEL4_AVERAGE_DEF(1),VEL4_AVERAGE_DEF(2),VEL4_AVERAGE_DEF(3) /)

  ENDIF

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

END PROGRAM DAVBIL

FUNCTION GEN_RANDOM_NUMBER(X) !FUNCTION FOR CALLING A RANDOM NUMBER

DOUBLE PRECISION :: GEN_RANDOM_NUMBER,X

CALL RANDOM_NUMBER(GEN_RANDOM_NUMBER)

END FUNCTION GEN_RANDOM_NUMBER



!-------------------------------------------------------
FUNCTION GENEREPSILO(X)  !FUNCTION FOR EDDIES INTENSITY GENERATION

DOUBLE PRECISION :: GENEREPSILO, X, RANDOM, GEN_RANDOM_NUMBER

!DO 
!  GENEREPSILO = (GEN_RANDOM_NUMBER(0.0D0) * 2.0D0 - 1.0D0)
!  IF (GENEREPSILO /= 0.0D0) THEN
!    EXIT
!  END IF
!END DO

!GENEREPSILO = FLOOR(GENEREPSILO)
!IF (GENEREPSILO == 0.0D0) THEN
!  GENEREPSILO = 1
!END IF


GENEREPSILO = GEN_RANDOM_NUMBER(0.0D0)

IF (GENEREPSILO .GT. 0.5D0) THEN
    GENEREPSILO = 1.D0
ELSE
    GENEREPSILO = -1.D0
ENDIF



END FUNCTION GENEREPSILO

!---------------------------------------------------------


