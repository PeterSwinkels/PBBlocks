$CPU 80386
$DIM ALL
$ERROR ALL ON
$EVENT OFF
$FLOAT NPX
$OPTION CNTLBREAK OFF
$OPTION GOSUB OFF
$OPTIMIZE SPEED
$SOUND 16
$STACK 2048
$STRING 1
DEFINT A-Z

DECLARE FUNCTION GetRotatedShapeMap (Shape AS INTEGER, Angle AS INTEGER) AS STRING
DECLARE FUNCTION GetShapeMap (Shape AS INTEGER) AS STRING
DECLARE FUNCTION RandomShapeX () AS INTEGER
DECLARE FUNCTION ShapeCanMove (MapV AS STRING, XDirection AS INTEGER, YDirection AS INTEGER) AS INTEGER
DECLARE SUB CheckForFullRows ()
DECLARE SUB CreateShape ()
DECLARE SUB DisplayStatus ()
DECLARE SUB DrawBlock (BlockColor AS STRING, PitX AS INTEGER, PitY AS INTEGER)
DECLARE SUB DrawPit ()
DECLARE SUB DrawShape (EraseShape AS INTEGER)
DECLARE SUB DropShape ()
DECLARE SUB InitializeGame ()
DECLARE SUB Main ()
DECLARE SUB RemoveFullRow (RemovedRow AS INTEGER)
DECLARE SUB SettleActiveShapeInPit ()

%BLOCKSCALE = 24
%FALSE = 0
%LASTSIDEBLOCK = 3
%PITHEIGHT = 16
%PITLEFT = 8
%PITTOP = 2
%PITWIDTH = 10
%SIDEBLOCKCOUNT = 4
%TRUE = -1

DIM DropRate AS SHARED DOUBLE
DIM GameOver AS SHARED INTEGER
DIM Pit AS SHARED STRING
DIM Score AS SHARED QUAD
DIM Shape AS SHARED INTEGER
DIM ShapeAngle AS SHARED INTEGER
DIM ShapeMap AS SHARED STRING
DIM ShapeX AS SHARED INTEGER
DIM ShapeY AS SHARED INTEGER

InitializeGame
Main

SUB CheckForFullRows
DIM FullRow AS LOCAL INTEGER
DIM PitX AS LOCAL INTEGER
DIM PitY AS LOCAL INTEGER

    FullRow = %FALSE

    FOR PitY = 0 TO %PITHEIGHT - 1
       FullRow = %TRUE
       FOR PitX = 0 TO %PITWIDTH - 1
           IF MID$(Pit, ((%PITWIDTH * PitY) + PitX) + 1, 1) = "0" THEN
              FullRow = %FALSE
              EXIT FOR
           END IF
       NEXT PitX
       IF FullRow THEN RemoveFullRow PitY
    NEXT PitY
END SUB

SUB CreateShape
    DropRate# = 1
    Shape = CINT(RND * 6)
    ShapeAngle = INT(RND * 4)
    ShapeMap = GetRotatedShapeMap(Shape, ShapeAngle)
    ShapeX = RandomShapeX
    ShapeY = -%SIDEBLOCKCOUNT
END SUB

SUB DisplayStatus
    COLOR 4
    LOCATE INT((%PITTOP * %BLOCKSCALE) / 16), INT((%PITLEFT * %BLOCKSCALE) / 8) + 1
    IF GameOver THEN
        PRINT "Game over - press Enter to play a new game."
    ELSE
        PRINT "Score:" & STR$(Score)
    END IF
END SUB

SUB DrawBlock (BlockColor AS STRING, PitX AS INTEGER, PitY AS INTEGER)
DIM DrawX AS LOCAL INTEGER
DIM DrawY AS LOCAL INTEGER

    DrawX = PitX * %BLOCKSCALE
    DrawY = PitY * %BLOCKSCALE

    LINE (DrawX + (%PITLEFT * %BLOCKSCALE), DrawY + (%PITTOP * %BLOCKSCALE))-STEP(%BLOCKSCALE, %BLOCKSCALE), VAL("&H" & BlockColor), BF
    LINE (DrawX + CINT(%BLOCKSCALE / 10) + (%PITLEFT * %BLOCKSCALE), DrawY + CINT(%BLOCKSCALE / 10) + (%PITTOP * %BLOCKSCALE))-STEP(%BLOCKSCALE - CINT(%BLOCKSCALE / 5), %BLOCKSCALE - CINT(%BLOCKSCALE / 5)), 0, B
END SUB

SUB DrawPit
DIM BlockColor AS LOCAL STRING
DIM PitX AS LOCAL INTEGER
DIM PitY AS LOCAL INTEGER

    LINE ((%PITLEFT * %BLOCKSCALE) - 1, (%PITTOP * %BLOCKSCALE) - 1)-STEP((%PITWIDTH * %BLOCKSCALE) + 2, (%PITHEIGHT* %BLOCKSCALE) + 2), 15, B
    LINE ((%PITLEFT * %BLOCKSCALE) - 1, (%PITTOP * %BLOCKSCALE) - 1)-STEP(%PITWIDTH * %BLOCKSCALE + 2, 0), 0

    FOR PitY = 0 TO %PITHEIGHT- 1
        FOR PitX = 0 TO %PITWIDTH - 1
            IF GameOver THEN
                BlockColor = "4"
            ELSE
                BlockColor = MID$(Pit, ((%PITWIDTH * PitY) + PitX) + 1, 1)
            END IF

            DrawBlock BlockColor, PitX, PitY
        NEXT PitX
    NEXT PitY
END SUB

SUB DrawShape (EraseShape AS INTEGER)
DIM BlockColor AS LOCAL STRING
DIM BlockX AS LOCAL INTEGER
DIM BlockY AS LOCAL INTEGER
DIM PitX AS LOCAL INTEGER
DIM PitY AS LOCAL INTEGER

    FOR BlockX = 0 TO %LASTSIDEBLOCK
        FOR BlockY = 0 TO %LASTSIDEBLOCK
            PitX = ShapeX + BlockX
            PitY = ShapeY + BlockY
            IF PitX >= 0 AND PitX < %PITWIDTH AND PitY >= 0 AND PitY < %PITHEIGHT THEN
                IF EraseShape THEN
                   BlockColor = MID$(Pit, ((%PITWIDTH * PitY) + PitX) + 1, 1)
                ELSE
                   BlockColor = MID$(ShapeMap, ((%SIDEBLOCKCOUNT * BlockY) + BlockX) + 1, 1)
                   IF BlockColor = "0" THEN BlockColor = MID$(Pit, ((%PITWIDTH * PitY) + PitX) + 1, 1)
                END IF
                DrawBlock BlockColor, PitX, PitY
            END IF
        NEXT BlockY
    NEXT BlockX
END SUB

SUB DropShape
    IF ShapeCanMove(ShapeMap, 0, 1) THEN
        DrawShape %TRUE
        IF DropRate# > 0 THEN SOUND 37, .3
        INCR ShapeY
        DrawShape %FALSE
    ELSE
        SettleActiveShapeInPit

        GameOver = (ShapeY < 0)

        CheckForFullRows
        DrawPit
        DisplayStatus

        IF ISFALSE GameOver THEN
            CreateShape
            DrawShape %FALSE
        END IF
    END IF
END SUB

FUNCTION GetRotatedShapeMap (Shape AS INTEGER, Angle AS INTEGER) AS STRING
DIM BlockX AS LOCAL INTEGER
DIM BlockY AS LOCAL INTEGER
DIM MapV AS LOCAL STRING
DIM NewBlockX AS LOCAL INTEGER
DIM NewBlockY AS LOCAL INTEGER
Dim RotatedMap AS LOCAL STRING

    MapV = GetShapeMap(Shape)

    IF Angle = 0 THEN
        RotatedMap = MapV
    ELSE
        RotatedMap = STRING$(%SIDEBLOCKCOUNT * %SIDEBLOCKCOUNT, "0")
        FOR BlockX = 0 TO %LASTSIDEBLOCK
            FOR BlockY = 0 TO %LASTSIDEBLOCK
                SELECT CASE Angle
                    CASE 1
                        NewBlockX = %LASTSIDEBLOCK - BlockY
                        NewBlockY = BlockX
                    CASE 2
                        NewBlockX = %LASTSIDEBLOCK - BlockX
                        NewBlockY = %LASTSIDEBLOCK - BlockY
                    CASE 3
                        NewBlockX = BlockY
                        NewBlockY = %LASTSIDEBLOCK - BlockX
                END SELECT

                MID$(RotatedMap, ((%SIDEBLOCKCOUNT * NewBlockY) + NewBlockX) + 1, 1) = MID$(MapV, ((%SIDEBLOCKCOUNT * BlockY) + BlockX) + 1, 1)
            NEXT BlockY
        NEXT BlockX
    END IF

    GetRotatedShapeMap = RotatedMap
END FUNCTION

FUNCTION GetShapeMap (Shape AS INTEGER) AS STRING
DIM MapV AS LOCAL STRING

    SELECT CASE Shape
        CASE 0
           MapV = "0000333300000000"
        CASE 1
           MapV = "0000111000100000"
        CASE 2
           MapV = "0000666060000000"
        CASE 3
           MapV = "00000EE00EE00000"
        CASE 4
           MapV = "0000022022000000"
        CASE 5
           MapV = "0000555005000000"
        CASE 6
           MapV = "0000440004400000"
        CASE ELSE
           MapV = ""
    END SELECT

    GetShapeMap = MapV
END FUNCTION

SUB InitializeGame
    RANDOMIZE TIMER
    PLAY "ML L64"

    SCREEN 12
    CLS
    COLOR 9
    LOCATE 1, 1
    PRINT "PBBlocks v1.00 - by: Peter Swinkels, ***2021***"

    CreateShape

    GameOver = %FALSE
    Pit = STRING$(%PITWIDTH * %PITHEIGHT, "0")
    Score = 0

    DrawPit
    DisplayStatus
END SUB

SUB Main
DIM KeyV AS LOCAL STRING
DIM NewAngle AS INTEGER
DIM RotatedMap AS STRING
DIM StartTime AS LOCAL DOUBLE
DIM TimerV AS LOCAL DOUBLE

    StartTime = TIMER
    DO
        DO
            IF ISFALSE GameOver THEN
                TimerV = TIMER
                IF TimerV >= StartTime + DropRate OR StartTime > TimerV THEN
                    DropShape
                    StartTime = TIMER
                END IF
            END IF
        LOOP UNTIL INSTAT
        KeyV = INKEY$
        IF KeyV = CHR$(27) THEN
            SCREEN 0
            END
        ELSEIF GameOver THEN
            IF KeyV = CHR$(13) THEN InitializeGame
        ELSE
            SELECT CASE KeyV
               CASE "A", "a"
                   DrawShape %TRUE
                   IF ShapeAngle = 3 THEN NewAngle = 0 ELSE NewAngle = ShapeAngle + 1
                   RotatedMap = GetRotatedShapeMap(Shape, NewAngle)
                   IF ShapeCanMove(RotatedMap, 0, 0) THEN
                       ShapeAngle = NewAngle
                       ShapeMap = RotatedMap
                   END IF
                   DrawShape %FALSE
               CASE CHR$(0) & "K"
                   DrawShape %TRUE
                   IF ShapeCanMove(ShapeMap, -1, 0) THEN DECR ShapeX
                   DrawShape %FALSE
               CASE CHR$(0) & "M"
                   DrawShape %TRUE
                   IF ShapeCanMove(ShapeMap, 1, 0) THEN INCR ShapeX
                   DrawShape %FALSE
               CASE " "
                   DropRate = 0
            END SELECT
        END IF
    LOOP
END SUB

FUNCTION RandomShapeX() AS INTEGER
DIM IntendedShapeX AS LOCAL INTEGER
Dim XMove AS LOCAL INTEGER

    IntendedShapeX = INT(RND * (%PITWIDTH - 1))
    ShapeX = 0

    FOR XMove = 0 TO IntendedShapeX
        IF ShapeCanMove(ShapeMap, 1, 0) THEN
            INCR ShapeX
        ELSE
            EXIT FOR
        END IF
    NEXT XMove

    RandomShapeX = ShapeX
END FUNCTION

SUB RemoveFullRow (RemovedRow AS INTEGER)
DIM BlockColor AS LOCAL STRING
DIM PitX AS LOCAL INTEGER
DIM PitY AS LOCAL INTEGER

    FOR PitY = RemovedRow TO 0 STEP -1
        FOR PitX = 0 TO %PITWIDTH - 1
            IF PitY = 0 THEN
                BlockColor = "0"
            ELSE
                BlockColor = MID$(Pit, ((%PITWIDTH * (PitY - 1)) + PitX) + 1, 1)
            END IF

            MID$(Pit, ((%PITWIDTH * PitY) + PitX) + 1, 1) = BlockColor
        NEXT PitX
    NEXT PitY

    INCR Score
END SUB

SUB SettleActiveShapeInPit
DIM BlockX AS LOCAL INTEGER
DIM BlockY AS LOCAL INTEGER
DIM PitX AS LOCAL INTEGER
DIM PitY AS LOCAL INTEGER

    PLAY "N21"

    FOR BlockY = 0 TO %LASTSIDEBLOCK
        FOR BlockX = 0 TO %LASTSIDEBLOCK
            PitX = ShapeX + BlockX
            PitY = ShapeY + BlockY
            IF PitX >= 0 AND PitX < %PITWIDTH AND PitY >= 0 AND PitY < %PITHEIGHT THEN
                IF ISFALSE MID$(ShapeMap, ((%SIDEBLOCKCOUNT * BlockY) + BlockX) + 1, 1) = "0" THEN
                   MID$(Pit, ((%PITWIDTH * PitY) + PitX) + 1, 1) = MID$(ShapeMap, ((%SIDEBLOCKCOUNT * BlockY) + BlockX) + 1, 1)
                END IF
            END IF
        NEXT BlockX
    NEXT BlockY
END SUB

FUNCTION ShapeCanMove (MapV AS STRING, XDirection AS INTEGER, YDirection AS INTEGER) AS INTEGER
DIM BlockX AS LOCAL INTEGER
DIM BlockY AS LOCAL INTEGER
DIM PitX AS LOCAL INTEGER
DIM PitY AS LOCAL INTEGER

    FOR BlockY = 0 TO %LASTSIDEBLOCK
        FOR BlockX = 0 TO %LASTSIDEBLOCK
            IF ISFALSE MID$(MapV, ((%SIDEBLOCKCOUNT * BlockY) + BlockX) + 1, 1) = "0" THEN
                PitX = (ShapeX + BlockX) + XDirection
                PitY = (ShapeY + BlockY) + YDirection
                IF PitX >= 0 AND PitX < %PITWIDTH AND PitY >= 0 AND PitY < %PITHEIGHT THEN
                    IF ISFALSE MID$(Pit, (((%PITWIDTH * PitY) + PitX) + 1), 1) = "0" THEN
                        ShapeCanMove = %FALSE
                        EXIT FUNCTION
                    END IF
                ELSEIF PitX < 0 OR PitX >= %PITWIDTH OR PitY >= %PITHEIGHT THEN
                    ShapeCanMove = %FALSE
                    EXIT FUNCTION
                END IF
            END IF
        NEXT BlockX
    NEXT BlockY

    ShapeCanMove = %TRUE
END FUNCTION

