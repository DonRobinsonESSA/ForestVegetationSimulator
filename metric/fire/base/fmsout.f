      SUBROUTINE FMSOUT (IYR)
      IMPLICIT NONE
C----------
C METRIC-FIRE-BASE $Id$
C----------
*     SINGLE-STAND VERSION
*     CALLED FROM: FMMAIN
*     CALLS:   FMSVOL
***********************************************************************
*----------------------------------------------------------------------
*  PURPOSE:
*     PRINT THE SNAG LIST.
*----------------------------------------------------------------------
*
*  CALL LIST DEFINITIONS:
*     IYR:     CURRENT YEAR
*
*  LOCAL VARIABLE DEFINITIONS:
*     SNVOLH, SNVOLS:  total volume of CURRENTLY-hard and CURRENTLY-soft
*                      snags, respectively, in each snag record
*     TOTDH, TOTDS:    total density of all CURRENTLY-hard and CURRENTLY-
*                      soft snags in each snag output class
*     TOTVLH, TOTVLS:  total volume of all CURRENTLY-hard and CURRENTLY-
*                      soft snags in each snag output class
*     TOTHTH, TOTHTS:  average height of all CURRENTLY hard and soft snags
*                      in each output snag class
*
*  COMMON BLOCK VARIABLES AND PARAMETERS:
*
***********************************************************************

C.... PARAMETER STATEMENTS.

C.... PARAMETER INCLUDE FILES.

      INCLUDE 'PRGPRM.F77'
      INCLUDE 'FMPARM.F77'
      INCLUDE 'METRIC.F77'

C.... COMMON INCLUDE FILES.

Csng  INCLUDE 'CONTRL.F77'
Csng  INCLUDE 'PLOT.F77'
      INCLUDE 'CONTRL.F77'
      INCLUDE 'PLOT.F77'
      INCLUDE 'FMCOM.F77'
      INCLUDE 'FMFCOM.F77'
C
C.... VARIABLE DECLARATIONS.
      INTEGER  YRLAST, JYR, II
      REAL     SNVOLS, SNVOLH, TEMPV
      
c      REAL     TOTDH(MAXSP,100,6), TOTDS(MAXSP,100,6)
c      REAL     TOTHTH(MAXSP,100,6), TOTHTS(MAXSP,100,6)
c      REAL     TOTVLS(MAXSP,100,6), TOTVLH(MAXSP,100,6)
c      REAL     TOTDBH(MAXSP,100,6)

      REAL, ALLOCATABLE:: TOTDH(:,:,:)
      REAL, ALLOCATABLE:: TOTDS(:,:,:)
      REAL, ALLOCATABLE:: TOTHTH(:,:,:)
      REAL, ALLOCATABLE:: TOTHTS(:,:,:)
      REAL, ALLOCATABLE:: TOTVLS (:,:,:)
      REAL, ALLOCATABLE:: TOTVLH(:,:,:)
      REAL, ALLOCATABLE:: TOTDBH (:,:,:)
      
      REAL     TOTN
      REAL     PRMS(4)
      LOGICAL  DEBUG, LOK
      INTEGER MYACT(1)
      DATA MYACT/2512/
      INTEGER  IYR,NTODO,JDO,NPRM,IACTK,IDC,JCL,DBSKODE
      
      ALLOCATE(TOTDH(MAXSP,100,6))
      ALLOCATE(TOTDS(MAXSP,100,6))
      ALLOCATE(TOTHTH(MAXSP,100,6))
      ALLOCATE(TOTHTS(MAXSP,100,6))
      ALLOCATE(TOTVLS(MAXSP,100,6))
      ALLOCATE(TOTVLH(MAXSP,100,6))
      ALLOCATE(TOTDBH(MAXSP,100,6))

C
C-----------
C     CHECK FOR DEBUG.
C-----------
      CALL DBCHK (DEBUG,'FMSOUT',6,ICYC)
      IF (DEBUG) WRITE(JOSTND,7) ICYC,IYR
  7   FORMAT(' ENTERING FMSOUT CYCLE = ',I2,' IYR=',I5)

C     FIRST CHECK TO SEE IF THE SNAG LIST IS TO BE PRINTED.

      CALL OPFIND(1,MYACT,NTODO)

      DO 5 JDO = 1,NTODO
         CALL OPGET(JDO,4,JYR,IACTK,NPRM,PRMS)
C         IF (JYR .NE. IYR) GOTO 5
            ISNAGB = IYR
            ISNAGE = INT(REAL(IYR) + PRMS(1))
            JSNOUT = INT(PRMS(3))
            LSHEAD = PRMS(4).EQ.0
            CALL OPDONE(JDO,IYR)
            GOTO 6
    5 CONTINUE
    6 CONTINUE
      IF (DEBUG) WRITE(JOSTND,9) ISNAGB,ISNAGE
 9    FORMAT(' FMSOUT: ISNAGB=',I5,'; ISNAGE=',I5)

C     CHECK TO MAKE SURE THAT THIS YEAR IS WITHIN THE REQUESTED REPORTING
C     PERIOD AND THAT IT IS A VALID YEAR (IF WE ARE USING A PRINTING INTERVAL)

      IF (IYR .EQ. 0 .AND. IYR.EQ. ISNAGB) GOTO 10
      IF (IYR .LT. ISNAGB .OR. IYR .GT. ISNAGE) goto 999

 10   CONTINUE

C     ZERO OUT THE CUMULATIVE VARIABLES

      DO JYR= 1,100
         DO IDC= 1,MAXSP
            DO JCL= 1,6
              TOTDH(IDC,JYR,JCL) = 0.0
              TOTDS(IDC,JYR,JCL) = 0.0
              TOTHTH(IDC,JYR,JCL) = 0.0
              TOTHTS(IDC,JYR,JCL) = 0.0
              TOTDBH(IDC,JYR,JCL) = 0.0
              TOTVLS(IDC,JYR,JCL) = 0.0
              TOTVLH(IDC,JYR,JCL) = 0.0
           ENDDO
        ENDDO
      ENDDO
      YRLAST = -1
      DO 100 II = 1, NSNAG

C        Skip this snag record if there are no snags in it or the snags
C        are too small to make it into the smallest snag printing class.

         IF ( ((DENIH(II)+DENIS(II)) .LE. 0.0)
     &     .OR. (DBHS(II) .LT. SNPRCL(1)) ) GOTO 100

C        Get the total volume of initially-soft snags in this record.

         SNVOLS = 0.0
         IF (DENIS(II) .GT. 0.0) THEN
           CALL FMSVOL (II, HTIS(II), TEMPV,.FALSE.,0)
           SNVOLS = TEMPV * DENIS(II)
         END IF

C        Get the volume of each initially-hard snag in this record, and
C        add their combined volume to either the currently-hard or
C        currently-soft totals, whichever is apppropriate.

         SNVOLH = 0.0
         IF (DENIH(II) .GT. 0.0) THEN
           CALL FMSVOL (II, HTIH(II), TEMPV,.FALSE.,0)

           IF (HARD(II)) THEN
             SNVOLH = TEMPV * DENIH(II)
           ELSE
             SNVOLS = SNVOLS + TEMPV * DENIH(II)
           END IF
         END IF

C        Determine what snag printing-class this record goes in (on the
C        basis of species, dhb and age)...

         JYR = IYR - YRDEAD(II) + 1

         IF (JYR .GT. 100)       JYR = 100
         IF (JYR .GT. YRLAST) YRLAST = JYR

         DO 80 JCL = 1,5
           IF (DBHS(II) .LT. SNPRCL(JCL+1)) GOTO 81
   80    CONTINUE
         JCL = 6
   81    CONTINUE

C        ...and add all its snags to the appropriate class totals.

         TOTDS(SPS(II),JYR,JCL) = TOTDS(SPS(II),JYR,JCL) + DENIS(II)
         TOTHTS(SPS(II),JYR,JCL) = TOTHTS(SPS(II),JYR,JCL) +
     &                             HTIS(II) * DENIS(II)

         IF (HARD(II)) THEN
           TOTDH(SPS(II),JYR,JCL) = TOTDH(SPS(II),JYR,JCL) + DENIH(II)
           TOTHTH(SPS(II),JYR,JCL) = TOTHTH(SPS(II),JYR,JCL) +
     &                               HTIH(II) * DENIH(II)
         ELSE
           TOTDS(SPS(II),JYR,JCL) = TOTDS(SPS(II),JYR,JCL) + DENIH(II)
           TOTHTS(SPS(II),JYR,JCL) = TOTHTS(SPS(II),JYR,JCL) +
     &                               HTIH(II) * DENIH(II)
         END IF

         TOTVLS(SPS(II),JYR,JCL) = TOTVLS(SPS(II),JYR,JCL) + SNVOLS
         TOTVLH(SPS(II),JYR,JCL) = TOTVLH(SPS(II),JYR,JCL) + SNVOLH

         TOTDBH(SPS(II),JYR,JCL) = TOTDBH(SPS(II),JYR,JCL) +
     &                             DBHS(II) * (DENIS(II) + DENIH(II))

  100 CONTINUE

      DO 130 JYR= 1,YRLAST
        DO 120 IDC= 1,MAXSP
          DO 110 JCL= 1,6
               TOTN = TOTDH(IDC,JYR,JCL) + TOTDS(IDC,JYR,JCL)
               IF (TOTN .EQ. 0.0) GOTO 110
               TOTDBH(IDC,JYR,JCL) = TOTDBH(IDC,JYR,JCL) / TOTN
               IF (TOTDH(IDC,JYR,JCL) .GT. 0.0) THEN
                  TOTHTH(IDC,JYR,JCL) = TOTHTH(IDC,JYR,JCL) /
     &                                  TOTDH(IDC,JYR,JCL)
               ELSE
                  TOTHTH(IDC,JYR,JCL) = 0.0
               ENDIF

               IF (TOTDS(IDC,JYR,JCL) .GT. 0.0) THEN
                  TOTHTS(IDC,JYR,JCL) = TOTHTS(IDC,JYR,JCL) /
     &                                  TOTDS(IDC,JYR,JCL)
               ELSE
                  TOTHTS(IDC,JYR,JCL) = 0.0
               ENDIF

  110       CONTINUE
  120    CONTINUE
  130 CONTINUE

C Convert units to metric equivalents, prior to sending to the DBS and/or sending 
C to a text file. Note that the text file version trims TOTVLH and TOTVLS to integers

      DO 140 JYR= 1,YRLAST
        DO 141 IDC= 1,MAXSP
          DO 142 JCL= 1,6
            TOTDBH(IDC,JYR,JCL) = TOTDBH(IDC,JYR,JCL) * INtoCM
            TOTHTH(IDC,JYR,JCL) = TOTHTH(IDC,JYR,JCL) * FTtoM
            TOTHTS(IDC,JYR,JCL) = TOTHTS(IDC,JYR,JCL) * FTtoM
            TOTVLH(IDC,JYR,JCL) = TOTVLH(IDC,JYR,JCL) * FT3toM3
            TOTVLS(IDC,JYR,JCL) = TOTVLS(IDC,JYR,JCL) * FT3toM3
            TOTDH(IDC,JYR,JCL)  = TOTDH(IDC,JYR,JCL)  / ACRtoHA
            TOTDS(IDC,JYR,JCL)  = TOTDS(IDC,JYR,JCL)  / ACRtoHA
  142     CONTINUE
  141   CONTINUE
  140 CONTINUE
C
C     CALL THE DBS MODULE TO OUTPUT DETAILED SNAG REPORT TO A DATABASE
C
      DBSKODE = 1
      CALL DBSFMDSNAG(IYR,TOTDBH,TOTHTH,TOTHTS,
     &  TOTVLH,TOTVLS,TOTDH,TOTDS,YRLAST,DBSKODE)
      IF (DBSKODE.EQ.0) GOTO 500

C     Make sure JSNOUT is opened.

      CALL openIfClosed (JSNOUT,"sng",LOK)
      IF (.NOT.LOK) goto 999

C     Print the snag output headings.

      IF (LSHEAD) THEN
         WRITE(JSNOUT,200) NPLT
         WRITE(JSNOUT,222)
         WRITE(JSNOUT,210)
         WRITE(JSNOUT,211)
         WRITE(JSNOUT,220)
         WRITE(JSNOUT,222)
  200    FORMAT(' ESTIMATED SNAG CHARACTERISTICS '
     &          '(BASED ON STOCKABLE AREA), STAND ID=',A)
  210    FORMAT(13X,'DEATH CURR',
     &         ' HEIGHT CURR VOLUME (M3)       ',
     &         '    DENSITY (SNAGS/HA)   ')
  211    FORMAT(9X,'DBH  DBH ',1X,
     &         4('-'),' (M)',3('-'),1X,17('-'),1X,'YEAR',1X,23('-'))
  220    FORMAT(' YEAR SP  CL  (CM)',1X,
     &         ' HARD  SOFT  HARD  SOFT TOTAL',
     &         1X,'DIED   HARD    SOFT    TOTAL')
  222    FORMAT(1X,76('-'))
         LSHEAD = .FALSE.
      ENDIF

C     Print information on each snag printing-class, first dividing
C     the total heights and dbhs to get the class-averages.

      DO 430 JYR= 1,YRLAST
         DO 420 IDC= 1,MAXSP
            DO 410 JCL= 1,6
               TOTN = TOTDH(IDC,JYR,JCL) + TOTDS(IDC,JYR,JCL)
               IF (TOTN .EQ. 0.0) GOTO 410
               WRITE(JSNOUT,300) IYR,JSP(IDC),JCL,
     &           TOTDBH(IDC,JYR,JCL),
     &           TOTHTH(IDC,JYR,JCL),
     &           TOTHTS(IDC,JYR,JCL),
     &           INT(TOTVLH(IDC,JYR,JCL)), 
     &           INT(TOTVLS(IDC,JYR,JCL)),
     &           INT(TOTVLH(IDC,JYR,JCL)+TOTVLS(IDC,JYR,JCL)),
     &           (IYR-JYR+1),
     &           TOTDH(IDC,JYR,JCL), 
     &           TOTDS(IDC,JYR,JCL), TOTN
  300          FORMAT(1X,I4,1X,A2,1X,I3,1X,3(F5.1,1X),
     &           3(I5,1X),I4,1X,3(F7.2,1X))
  410       CONTINUE
  420    CONTINUE
  430 CONTINUE

      inquire(unit=JSNOUT,opened=LOK)
      if (LOK) close(unit=JSNOUT)

  500 CONTINUE

  999 CONTINUE

      DEALLOCATE(TOTDH)
      DEALLOCATE(TOTDS)
      DEALLOCATE(TOTHTH)
      DEALLOCATE(TOTHTS)
      DEALLOCATE(TOTVLS)
      DEALLOCATE(TOTVLH)
      DEALLOCATE(TOTDBH)
     
      RETURN
      END

