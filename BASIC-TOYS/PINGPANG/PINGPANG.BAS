Prepare:
    OPEN "pingpang.dat" FOR INPUT AS #1
    DIM gamedata(8, 5, 8), datasum(8)
    FOR i = 1 TO 8
        LINE INPUT #1, temptext$
        FOR j = 1 TO 5
            FOR k = 1 TO 8
                gamedata(i, j, k) = VAL(MID$(temptext$, (j - 1) * 8 + k, 1))
                IF gamedata(i, j, k) <> 6 THEN datasum(i) = datasum(i) + gamedata(i, j, k)
            NEXT k
        NEXT j
    NEXT i
    CLOSE #1
    DIM gamedatanow(5, 8)

GameFace:
    SCREEN 12: CLS
    PRINT "            (C) & (P)  YUSOFT 0 o'Clock STUDIO"
    LOCATE 2, 25: PRINT "P I N G  P A N G              ver 1.0"
    LOCATE 30, 40: PRINT "Made by Lavender J YU, Jun 6th, 2004.";
    LINE (30, 55)-(410, 435), , B
    LOCATE 5, 57: PRINT "Information Board"
    LINE (420, 55)-(610, 435), , B
    LOCATE 8, 55: PRINT CHR$(2); " SCORE:"
    LOCATE 9, 75: PRINT "0"
    LOCATE 11, 55: PRINT CHR$(2); " LIVES:"
    LOCATE 12, 57: FOR i = 1 TO 5: PRINT " "; CHR$(3); : NEXT i
    LOCATE 14, 55: PRINT CHR$(2); " RECORD:"
    OPEN "record.dat" FOR INPUT AS #1
    FOR i = 15 TO 16
        LINE INPUT #1, temptext$: LOCATE i, 73 - i
        IF LEN(temptext$) <= 17 THEN PRINT temptext$ ELSE PRINT LEFT$(temptext$, 15); ".."
        IF i = 16 THEN record = VAL(temptext$)
    NEXT i
    CLOSE #1
    LOCATE 17, 55: PRINT CHR$(2); " UNIT:"
    LOCATE 18, 75: PRINT "1"
    LOCATE 20, 55: PRINT CHR$(2); " SPEED:"
    LOCATE 21, 75: PRINT "1"
    LOCATE 23, 55: PRINT CHR$(2); " HELP:"
    LOCATE 24, 57: PRINT "Press <SPACE> to"
    LOCATE 25, 58: PRINT "start. "
    LOCATE 26, 57: PRINT "Press <ESC> to quit."

WelcomeFace:
    unit = 1: speed = 1
1   GOSUB DrawBox
    k = -1: b = 630: st = 1: x = 210: death = 1
    FOR i = 1 TO 5
        FOR j = 1 TO 8
            gamedatanow(i, j) = gamedata(unit, i, j)
        NEXT j
    NEXT i
    datasumnow = datasum(unit)
2   jumpout = 0
    DO
        FOR i = 1 TO 60100 - 10000 * speed: NEXT i: death = 0
        CIRCLE (x, k * x + b), 2, 0
        x = x + st
        GOSUB Collision
        CIRCLE (x, k * x + b), 2
        racket = x
        IF racket > 383 THEN racket = 383
        IF racket < 58 THEN racket = 58
        GOSUB DrawRacket
        a$ = INKEY$
        IF a$ = " " THEN jumpout = 3
        IF a$ = CHR$(27) THEN END
        IF LEN(a$) = 2 THEN
            SELECT CASE ASC(RIGHT$(a$, 1))
            CASE 72
                speed = speed + 1: IF speed = 6 THEN speed = 1
                LOCATE 21, 74: PRINT speed
                jumpout = 2
            CASE 80
                speed = speed - 1: IF speed = 0 THEN speed = 5
                LOCATE 21, 74: PRINT speed
                jumpout = 2
            CASE 75
                unit = unit - 1: IF unit = 0 THEN unit = 8
                LOCATE 18, 74: PRINT unit
                jumpout = 1
            CASE 77
                unit = unit + 1: IF unit = 9 THEN unit = 1
                LOCATE 18, 74: PRINT unit
                jumpout = 1
            END SELECT
        END IF
    LOOP UNTIL jumpout <> 0
    IF jumpout = 1 THEN 1
    IF jumpout = 2 THEN 2

Gaming:
    lifenum = 5: death = 1: score = 0: LOCATE 9, 65: PRINT "          0"
4   GOSUB DrawBox
    FOR i = 1 TO 5
        FOR j = 1 TO 8
            gamedatanow(i, j) = gamedata(unit, i, j)
        NEXT j
    NEXT i
    datasumnow = datasum(unit)
3   racket = 210: b = 630: k = -1: x = 210: st = 1
5   GOSUB DrawRacket
    CIRCLE (racket, 420), 2
    jumpout = 0
    DO
        a$ = INKEY$
        IF a$ = " " THEN jumpout = 3
        IF a$ = CHR$(27) THEN
            IF score > record THEN GOSUB RecordChanging
            GOTO GameFace
        END IF
        IF LEN(a$) = 2 THEN
            SELECT CASE ASC(RIGHT$(a$, 1))
            CASE 75
                CIRCLE (racket, 420), 2, 0
                racket = racket - 1: IF racket < 58 THEN racket = 58
                GOSUB DrawRacket
                b = racket + 420: x = racket
                jumpout = 1
            CASE 77
                CIRCLE (racket, 420), 2, 0
                racket = racket + 1: IF racket > 383 THEN racket = 382
                GOSUB DrawRacket
                b = racket + 420: x = racket
                jumpout = 1
            END SELECT
        END IF
    LOOP UNTIL jumpout <> 0
    IF jumpout = 1 THEN 5
    jumpout = 0
    DO
        FOR i = 1 TO 60100 - 10000 * speed: NEXT i
        CIRCLE (x, k * x + b), 2, 0
        x = x + st
        GOSUB Collision
        CIRCLE (x, k * x + b), 2
        a$ = INKEY$
        IF a$ = " " THEN
            DO
            LOOP UNTIL INKEY$ <> ""
        END IF
        IF a$ = CHR$(27) THEN
            IF score > record THEN GOSUB RecordChanging
            GOTO GameFace
        END IF
        IF LEN(a$) = 2 THEN
            SELECT CASE ASC(RIGHT$(a$, 1))
            CASE 75
                racket = racket - 2 - speed: IF racket < 58 THEN racket = 58
                GOSUB DrawRacket
            CASE 77
                racket = racket + 2 + speed: IF racket > 382 THEN racket = 382
                GOSUB DrawRacket
            END SELECT
        END IF
        IF datasumnow = 0 THEN jumpout = 1
        IF lifenum = -1 THEN jumpout = 2
    LOOP UNTIL jumpout <> 0
    IF jumpout = 1 THEN
        unit = unit + 1: IF unit = 9 THEN unit = 1: speed = speed + 1
        IF speed = 6 THEN speed = 1
        LOCATE 18, 74: PRINT unit
        LOCATE 21, 74: PRINT speed
        GOTO 4
    END IF
    IF jumpout = 2 THEN
        LINE (100, 200)-(340, 290), 12, BF
        LINE (102, 202)-(338, 288), , BF
        LINE (103, 203)-(337, 287), 0, BF
        LOCATE 16, 19: PRINT "G A M E   O V E R !"
        IF score > record THEN
            FOR i = 0 TO 300000: NEXT i
            GOSUB RecordChanging
        ELSE
            DO
            LOOP UNTIL INKEY$ <> ""
        END IF
        GOTO GameFace
    END IF
    IF jumpout = 4 THEN CIRCLE (x, y), 2, 0: GOTO 3
    
   

    

DrawBox:
    LINE (31, 56)-(409, 434), 0, BF
FOR i = 1 TO 5
    FOR j = 1 TO 8
        PSET (j * 47 - 13, i * 25 + 84), 0
        SELECT CASE gamedata(unit, i, j)
        CASE 1
            LINE -STEP(43, 21), , B
        CASE 2
            LINE -STEP(43, 21), 1, BF
        CASE 3
            LINE -STEP(43, 21), 14, BF
        CASE 4
            LINE -STEP(43, 21), 6, BF
        CASE 5
            LINE -STEP(43, 21), 10, BF
        CASE 6
            LINE -STEP(43, 21), 4, BF
        END SELECT
    NEXT j
NEXT i
RETURN

DrawRacket:
    LINE (31, 423)-(409, 427), 0, BF
    LINE (racket - 25, 423)-(racket + 25, 427), 14, BF
    RETURN

ChangeBox:
    IF c <> 0 THEN LINE (x0 * 47 - 13, y0 * 25 + 84)-STEP(43, 21), 0, BF
    PSET (x0 * 47 - 13, y0 * 25 + 84), 0
    SELECT CASE gamedatanow(y0, x0)
    CASE 1
        LINE -STEP(43, 21), , B
    CASE 2
        LINE -STEP(43, 21), 1, BF
    CASE 3
        LINE -STEP(43, 21), 14, BF
    CASE 4
        LINE -STEP(43, 21), 6, BF
    CASE 5
        LINE -STEP(43, 21), 10, BF
    CASE 6
        LINE -STEP(43, 21), 4, BF
    END SELECT
    RETURN

Collision:
    y = k * x + b
    IF x = 407 OR x = 33 THEN GOSUB collisionLR
    IF y = 58 THEN GOSUB collisionUD
    IF y = 420 AND death = 0 THEN GOSUB collisionUD
    IF y = 420 AND ABS(x - racket) <= 25 AND death = 1 THEN GOSUB collisionUD
    IF y = 420 AND ABS(x - racket) > 25 AND death = 1 THEN GOSUB Deathlife
    x0 = INT((x + 13) / 47): y0 = INT((y - 84) / 25)
    IF y0 > 0 AND y0 < 6 THEN
        IF gamedatanow(y0, x0) <> 0 THEN
            IF x0 * 47 - 13 = x OR (x0 + 1) * 47 - 14 = x THEN GOSUB collisionLR
            IF y0 * 25 + 84 = y OR (y0 + 1) * 25 + 83 = y THEN GOSUB collisionUD
            IF gamedatanow(y0, x0) <> 6 THEN
                datasumnow = datasumnow - 1
                gamedatanow(y0, x0) = gamedatanow(y0, x0) - 1
                c = 1: GOSUB ChangeBox
                score = score + 1
                LOCATE 9, 76 - LEN(STR$(score)): PRINT score
            END IF
        END IF
    END IF
        'Process the corner lacks of the color boxes.
            IF x0 < 8 AND x0 > -1 AND y0 > 0 AND y0 < 6 THEN
                x0 = x0 + 1
                IF gamedatanow(y0, x0) <> 0 THEN c = 0: GOSUB ChangeBox
                x0 = x0 - 1
            END IF
            IF y0 < 5 AND y0 > -1 AND x0 > 0 AND x0 < 9 THEN
                y0 = y0 + 1
                IF gamedatanow(y0, x0) <> 0 THEN c = 0: GOSUB ChangeBox
                y0 = y0 - 1
            END IF
            IF x0 < 8 AND x0 > -1 AND y0 < 5 AND y0 > -1 THEN
                x0 = x0 + 1: y0 = y0 + 1
                IF gamedatanow(y0, x0) <> 0 THEN c = 0: GOSUB ChangeBox
            END IF
    RETURN
collisionLR:
    b = 2 * k * x + b: st = -st: k = -k
    RETURN
collisionUD:
    b = 2 * k * x + b: k = -k
    RETURN

Deathlife:
    lifenum = lifenum - 1
    LOCATE 12, 58: PRINT "          ": LOCATE 12, 58
    IF lifenum > 0 THEN
        FOR i = 1 TO lifenum
            PRINT CHR$(3); " ";
        NEXT i
    END IF
    LINE (racket - 25, 423)-(racket + 25, 427), 0, BF
    jumpout = 4
    RETURN

RecordChanging:
    name$ = ""
    LINE (200, 100)-(450, 280), , BF
    LINE (201, 101)-(449, 279), 0, BF
    LOCATE 8, 31: PRINT "Noting the New Record!"
    LOCATE 10, 29: PRINT "Name:"
    LOCATE 11, 30: PRINT "_"
    LOCATE 14, 29: PRINT "Score:"
    LOCATE 16, 54 - LEN(STR$(score)): PRINT score
6   DO
    a$ = INKEY$
    LOOP UNTIL a$ <> ""
    IF a$ = CHR$(13) THEN
        OPEN "record.dat" FOR OUTPUT AS #1
        PRINT #1, name$
        PRINT #1, STR$(score)
        CLOSE #1
        RETURN
    ELSE
        IF ASC(a$) >= 32 THEN name$ = name$ + a$: LOCATE 11, 30: PRINT name$; "_"
        IF ASC(a$) = 8 AND name$ <> "" THEN name$ = LEFT$(name$, LEN(name$) - 1): LOCATE 11, 30 + LEN(name$): PRINT "_ "
        GOTO 6
    END IF

    

