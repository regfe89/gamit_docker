      SUBROUTINE UPNAM1(FILEO,FILEN)
C
C  UPDATE FILE NAME (C-,P- FILES)
C    LOCATE CHARACTER BEFORE PERIOD (THE YEAR OR ITERATION CODE)
C     IF CHARACTER IS A NUMBER - CHANGE TO AN 'A' - FIRST ITERATION
C     IF CHARACTER IS A LETTER - ASSIGN THE NEXT LETTER
C
      CHARACTER*16 FILEO,FILEN,lowerc
      CHARACTER*1 ICHAR
      integer*4 icol
C
      FILEN=lowerc(FILEO)
      ICOL = INDEX(FILEN,'.')
C CHARACTER BEFORE PERIOD
      ICHAR = FILEN(ICOL-1:ICOL-1)
C UPDATE CHARACTER
      CALL NEWCHR(ICHAR)
      FILEN(ICOL-1:ICOL-1) = lowerc(ICHAR)
C
      RETURN
      END
