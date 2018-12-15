DECLARE SUB DrawPic (filename$, left!, topic!, high!, wide!)
SCREEN 12
LINE (0, 0)-(640, 480), 15, BF
CALL DrawPic("title01.ypg", 45, 30, 26, 240)
CALL DrawPic("title02.ypg", 140, 70, 91, 285)
CALL DrawPic("title03.ypg", 450, 90, 64, 55)
CALL DrawPic("title04.ypg", 120, 250, 183, 392)
a$ = INPUT$(1)
a$ = ""
CLS
LOCATE 2, 30: PRINT "H  E  L  P"
LOCATE 3, 27
FOR i = 1 TO 16
PRINT "Í";
NEXT
LOCATE 5, 1: PRINT "    This Game named Plane-shooting is a kind of game which be good for"
PRINT "brain. The inventor of this game is a pupil from P.R. of China. Now the"
PRINT "worker of The Great Yusoft Program-writing Centre has written it into a"
PRINT "Software on the computer, so we could enjoy it in front of your screen"
PRINT "for resting. You can hit your keyboard with a cup of hot coffee!"
PRINT : PRINT "    If you press any to come into the gaming screen. Now I will teach you"
PRINT "How to play this game."
PRINT : PRINT "    First you guess the place where the plane lies. Then Input the place"
PRINT "with Line and Row. If you shoot at the head of the plane, you had destroyed"
PRINT "a plane. There are two plane in once. If you shoot at the body of the plane"
PRINT "(Expect the head), The box will become yellow, these can help you shoot the"
PRINT "head of the head. A plean is like ñ, with five boxes in the fornt wing and"
PRINT "three boxes in the tail wing."
PRINT : PRINT "    This game is written by Lavender Joyously Yu who is the head of Yusoft."
PRINT "He hopes join you. Please E-mail him at < yuylong@hotmail.com >. He is"
PRINT "waiting for you to be one of his friends."
PRINT : PRINT "   More smiles, more happiness, and more wonderful in our lives."
PRINT : PRINT "                                       April 6th, 2003"
a$ = INPUT$(1)
a$ = ""

'The headfore Program
'Get the datas for running.
1 DIM plane(10, 10)
FOR i = 1 TO 10
    FOR j = 1 TO 10
        plane(i, j) = 0
    NEXT
NEXT
steps = 0
DIM head(4)
FOR i = 1 TO 4
    head(i) = INT(RND * 10)
    IF head(i) < 1 THEN head(i) = 1
    IF head(i) > 10 THEN head(i) = 10
NEXT
DIM orientation(2)
FOR i = 1 TO 2
   orientation(i) = INT(RND * 100) MOD 4 + 1
NEXT

'Check
check = 1
FOR i = 1 TO 2
SELECT CASE orientation(i)
    CASE 1
        IF head(i * 2 - 1) < 3 OR head(i * 2 - 1) > 8 OR head(i * 2) > 7 THEN check = 0: GOTO 2
        FOR j = 0 TO 3
            IF plane(head(i * 2 - 1), head(i * 2) + j) = 1 THEN check = 0
        NEXT
        FOR j = -2 TO 2
            IF plane(head(i * 2 - 1) + j, head(i * 2) + 1) = 1 THEN check = 0
        NEXT
        FOR j = -1 TO 1
            IF plane(head(i * 2 - 1) + j, head(i * 2) + 3) = 1 THEN check = 0
        NEXT
2
    CASE 2
        IF head(i * 2) < 3 OR head(i * 2) > 8 OR head(i * 2 - 1) > 7 THEN check = 0: GOTO 3
        FOR j = 0 TO 3
            IF plane(head(i * 2 - 1) + j, head(i * 2)) = 1 THEN check = 0
        NEXT
        FOR j = -2 TO 2
            IF plane(head(i * 2 - 1) + 1, head(i * 2) + j) = 1 THEN check = 0
        NEXT
        FOR j = -1 TO 1
            IF plane(head(i * 2 - 1) + 3, head(i * 2) + j) = 1 THEN check = 0
        NEXT
3
    CASE 3
        IF head(i * 2 - 1) < 3 OR head(i * 2 - 1) > 8 OR head(i * 2) < 4 THEN check = 0: GOTO 4
        FOR j = 0 TO 3
            IF plane(head(i * 2 - 1), head(i * 2) - j) = 1 THEN check = 0
        NEXT
        FOR j = -2 TO 2
            IF plane(head(i * 2 - 1) + j, head(i * 2) - 1) = 1 THEN check = 0
        NEXT
        FOR j = -1 TO 1
            IF plane(head(i * 2 - 1) + j, head(i * 2) - 3) = 1 THEN check = 0
        NEXT
4
    CASE 4
        IF head(i * 2) < 3 OR head(i * 2) > 8 OR head(i * 2 - 1) < 4 THEN check = 0: GOTO 5
        FOR j = 0 TO 3
            IF plane(head(i * 2 - 1) - j, head(i * 2)) = 1 THEN check = 0
        NEXT
        FOR j = -2 TO 2
            IF plane(head(i * 2 - 1) - 1, head(i * 2) + j) = 1 THEN check = 0
        NEXT
        FOR j = -1 TO 1
            IF plane(head(i * 2 - 1) - 3, head(i * 2) + j) = 1 THEN check = 0
        NEXT
5
END SELECT

IF check = 0 THEN 9

'Set Planes

SELECT CASE orientation(i)
    CASE 1
        FOR j = 0 TO 3
            plane(head(i * 2 - 1), head(i * 2) + j) = 1
        NEXT
        FOR j = -2 TO 2
            plane(head(i * 2 - 1) + j, head(i * 2) + 1) = 1
        NEXT
        FOR j = -1 TO 1
            plane(head(i * 2 - 1) + j, head(i * 2) + 3) = 1
        NEXT
    CASE 2
        FOR j = 0 TO 3
            plane(head(i * 2 - 1) + j, head(i * 2)) = 1
        NEXT
        FOR j = -2 TO 2
            plane(head(i * 2 - 1) + 1, head(i * 2) + j) = 1
        NEXT
        FOR j = -1 TO 1
            plane(head(i * 2 - 1) + 3, head(i * 2) + j) = 1
        NEXT
    CASE 3
        FOR j = 0 TO 3
            plane(head(i * 2 - 1), head(i * 2) - j) = 1
        NEXT
        FOR j = -2 TO 2
            plane(head(i * 2 - 1) + j, head(i * 2) - 1) = 1
        NEXT
        FOR j = -1 TO 1
            plane(head(i * 2 - 1) + j, head(i * 2) - 3) = 1
        NEXT
    CASE 4
        FOR j = 0 TO 3
            plane(head(i * 2 - 1) - j, head(i * 2)) = 1
        NEXT
        FOR j = -2 TO 2
            plane(head(i * 2 - 1) - 1, head(i * 2) + j) = 1
        NEXT
        FOR j = -1 TO 1
            plane(head(i * 2 - 1) - 3, head(i * 2) + j) = 1
        NEXT
END SELECT
plane(head(i * 2 - 1), head(i * 2)) = 2
9 NEXT
IF check = 0 THEN 1
shoot = 0

'Set Screen
CLS
FOR i = 0 TO 10
    LINE (30, 30 + 40 * i)-(430, 30 + 40 * i)
NEXT
FOR i = 0 TO 10
    LINE (30 + 40 * i, 30)-(30 + 40 * i, 430)
NEXT
FOR i = 0 TO 9
    LOCATE 1, 6 + i * 5: PRINT i
NEXT
j = 1
FOR i = 0 TO 9
    LOCATE j + (.5 * ((-1) ^ i) + 2.5), 1: PRINT i
    j = j + (.5 * ((-1) ^ i) + 2.5)
NEXT
LOCATE 29, 12
PRINT "= Die          = shoot at       = Blank";
LINE (68, 447)-(78, 460), 12, BF
LINE (190, 447)-(200, 460), 14, BF
LINE (323, 447)-(333, 460), 7, BF
LINE (450, 30)-(600, 190), , B
LOCATE 4, 61
PRINT "INPUT DATAS"
LOCATE 7, 58: PRINT "Line(Y):"
LOCATE 9, 58: PRINT "Row(X):"
LOCATE 11, 58: PRINT "Step:     0"
LINE (450, 200)-(600, 430), , B
LOCATE 15, 64: PRINT "HELP"
LOCATE 18, 58: PRINT CHR$(2) + " Press <ESC> to"
LOCATE 19, 60: PRINT "Quit"
LOCATE 21, 58: PRINT CHR$(2) + " Press <N> to"
LOCATE 22, 60: PRINT "Reset"
LOCATE 24, 58: PRINT CHR$(2) + " Made by:"
LOCATE 25, 62: PRINT "Lavender J Yu"

DO
10  LOCATE 7, 68: PRINT "Û"
    a$ = INPUT$(1)
    IF a$ = CHR$(27) OR a$ = "n" OR a$ = "N" THEN 50
    IF ASC(a$) < 48 OR ASC(a$) > 57 THEN 10
    y = ASC(a$) - 47
    LOCATE 7, 68: PRINT a$
20  LOCATE 9, 68: PRINT "Û"
    a$ = INPUT$(1)
    IF a$ = CHR$(27) OR a$ = "n" OR a$ = "N" THEN 50
    IF ASC(a$) < 48 OR ASC(a$) > 57 THEN 10
    x = ASC(a$) - 47
    LOCATE 9, 68: PRINT a$
    IF plane(x, y) = 1 THEN LINE (x * 40 - 9, y * 40 - 9)-(x * 40 + 29, y * 40 + 29), 14, BF
    IF plane(x, y) = 0 THEN LINE (x * 40 - 9, y * 40 - 9)-(x * 40 + 29, y * 40 + 29), 7, BF
    IF plane(x, y) = 2 THEN
        LINE (x * 40 - 9, y * 40 - 9)-(x * 40 + 29, y * 40 + 29), 12, BF
        shoot = shoot + 1
        plane(x, y) = 3
    END IF
    steps = steps + 1
    LOCATE 11, 67: PRINT steps
    LOCATE 9, 68: PRINT " "
50 LOOP UNTIL (a$ = CHR$(27) OR shoot = 2 OR a$ = "n" OR a$ = "N")
IF a$ = CHR$(27) THEN CLS : END
IF a$ = "n" OR a$ = "N" THEN 1
IF shoot = 2 THEN
    LINE (97, 197)-(503, 303), 12, BF
    LINE (100, 200)-(500, 300), 0, BF
    LINE (100, 200)-(500, 300), , B
    LOCATE 16, 20: PRINT "YOU ARE A HERO! YOU HAS WON THE GAME!"
    a$ = INPUT$(1)
    IF a$ = CHR$(27) THEN CLS : END ELSE GOTO 1
END IF

SUB DrawPic (filename$, left, topic, high, wide)
    OPEN filename$ FOR INPUT AS #1
    LINE INPUT #1, head$
    IF head$ <> "YUSOFT_GPH_1-" THEN 100
    FOR i = 1 TO high
        LINE INPUT #1, STAT$
        FOR j = 1 TO wide
            stata$ = MID$(STAT$, j, 1)
            IF stata$ = "0" THEN stataa = 0
            IF stata$ = "1" THEN stataa = 1
            IF stata$ = "2" THEN stataa = 2
            IF stata$ = "3" THEN stataa = 3
            IF stata$ = "4" THEN stataa = 4
            IF stata$ = "5" THEN stataa = 5
            IF stata$ = "6" THEN stataa = 6
            IF stata$ = "7" THEN stataa = 7
            IF stata$ = "8" THEN stataa = 8
            IF stata$ = "9" THEN stataa = 9
            IF stata$ = "A" THEN stataa = 10
            IF stata$ = "B" THEN stataa = 11
            IF stata$ = "C" THEN stataa = 12
            IF stata$ = "D" THEN stataa = 13
            IF stata$ = "E" THEN stataa = 14
            IF stata$ = "F" THEN stataa = 15
            LINE (left + j - 1, topic + i - 1)-(left + j - 1, topic + i - 1), stataa
        NEXT
   NEXT
   CLOSE #1
100 END SUB

