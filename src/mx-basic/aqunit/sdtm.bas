������������ SDTM.B������������ #9d � Test DTM$, SDTM, SLEEP, VER H9n QU�0:� 0=Screen,1=Printer,2=File Y9� � 900:� Init c9� � 200 n9� � QE � �9� � "Undefined Error Return";QE �9� � �9� � 7,0:�:�:� �9� QT$�"RTC":� 910 �9� QU$�"TS$=DTM$(0)":� 980 �9� TS$��(0) :� � TS$��"" � 300:� RTC Present  :� QA$�"DTM$(0)=``":� 920 N:� � "No RTC present. Skipping clock tests." u:� � 600:� Skip remaining clock tests �:,QL�0:K��(0) �:1� �:6QT$�"DTM$":� 910 �:@QA$�"LEN(DTM$(0))=14":� 920 �:EQA$�"LEN(DTM$(1))=19":� 920 ;JDS$��(�(1),5,1):ES$��(�(1),8,1):� Hyphens check 7;OFS$��(�(1),11,1):� Space check l;TGS$��(�(1),14,1):HS$��(�(1),17,1):� Colons check �;YQU$�"DS$=MID$(DTM$(1),5,1)":� 980:QA$�"DS$=`-`":� 920 �;^QU$�"ES$=MID$(DTM$(1),8,1)":� 980:QA$�"ES$=`-`":� 920 <cQU$�"FS$=MID$(DTM$(1),11,1)":� 980:QA$�"FS$=` `":� 920 V<hQU$�"GS$=MID$(DTM$(1),14,1)":� 980:QA$�"GS$=`:`":� 920 �<mQU$�"HS$=MID$(DTM$(1),17,1)":� 980:QA$�"HS$=`:`":� 920 �<�QL�0:K��(0) �<�� �<�QT$�"SDTM":� 910 �<�OT$��(0):� Grab original datetime =�TT$�"270214020000":� 14 FEB 2027 @ 02:00:00 AM =�� TT$ U=�� (�(�(0),10) � �(TT$,10)) � 445:� Set Time works �=�� "RTC cannot be set. Skipping set tests." �=�� 500 �=�QA$�"LEFT$(DTM$(0),10) = LEFT$(TT$,10)":� 920 �=�� "Resetting datetime." �=�� (�(OT$,12) �=�QL�0:K��(0) >�� >�QT$�"SLEEP":� 910 %>SS�1000 U>OT��(�(�(0),6)�"0"):� Grab original MMSScc0 ^>� SS �>TT��(�(�(0),6)�"0"):� Grab new MMSScc0 �>QA$�"(TT-OT)>850":� 920 �>QA$�"(TT-OT)<1150":� 920 �>XQL�0:K��(0) �>]� �>bQT$�"VER":� 910 ?gQA$�"VER(0)=512":� 920 +?lQA$�"HEX$(VER(0))=`0200`":� 920 1? � G?*� "Passed:";QR(1) ]?4� "Failed:";QR(0) c?p� {?z� 970:QU$�QA$:� 980 �?�QF$��$:QF��(�$):� Init �?�� QU�1 � � Q(999):QP�0 �?�QU$�"Running "�QF$:� 980 �?�QF$��(�$,QF�4)�".TST" @�QR$(0)�"Fail: ":QR$(1)�"Pass: " @�� 7@�QU$�"Testing "�QT$:� Print Title A@�� 980 Z@�� 970:� Do Assertion i@�� � � 930 �@�QV���(QA$):� � � 0 �@�QU$�QR$(QV)�QA$:� 980 �@�QR(QV)�QR(QV)�1:� �@�QU$��$(0)�" Error in "�QA$ �@�� 980 �@�� �@�� 970:� Assert Error A�� � � 950 A�QV��(QA$):� � � 0 :A�QU$�"No Error in "�QA$ TA�� 980:QR(0)�QR(0)�1:� sA�QU$��$(0)�" Error in "�QA$ �A�QV��(�$(0)�QE$):QR(QV)�QR(QV)�1 �A�QU$�QR$(QV)�QU$:� 980 �A�� �:� � � 0 �A�� 150 �A�� so we can RETURN from Error B�QA$�QA$�" ":� Convert ` to " %B�� QI�0 � �(QA$)�1 8B�QC��(&&QA$�QI) TB�� QC�96 � � &&QA$�QI,34 \B��:� yB�� QU � 988:� Output Line �B�� QL�20 � QL�0:QK��(0) �B�� QU$:QL�QL�1:� �B�� QU�1 � � QU$:� �B�QN��(QU$)�2 �B�� &Q(0)�QP,QU$ �B�QP�QP�QN:� &Q(0)�1,13,10 C��                  