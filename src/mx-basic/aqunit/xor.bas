������������ XOR.BA������������ )9d � Test AND(), OR(), XOR() functions N9n QU�0:� 0=Screen,1=Printer,2=File _9� � 900:� Init i9� � 200 �9� � QE � 282,284,286,288,290 �9� � QE�5 � 382,384,386,388,390 �9� � QE�10 � 482,484,486,488,490 �9� � "Undefined Error Return";QE �9� � 	:� QT$�"AND()":� 910 0:� QA$�"AND($FFFF,$FFFF)=$FFFF":� 920 W:� QA$�"AND($FFFF,$0000)=$0000":� 920 ~:� QA$�"AND($7777,$8888)=$0000":� 920 �:� QA$�"AND($7777,$FFFF)=$7777":� 920 �:� QA$�"AND($7777,$0000)=$0000":� 920 �:� QA$�"AND($FF*16,$FFFF)=$FF0":� 920 ;� QA$�"AND(2^15, 65535)=32768":� 920 A;� QA$�"AND(65535,-65535)=1   ":� 920 l;QA$�"AND(65536,0)":QE$�"FC":QE�1:� 940 �;QA$�"AND(0,65536)":QE$�"FC":QE�2:� 940 �;QA$�"AND(-65536,0)":QE$�"FC":QE�3:� 940 �;QA$�"AND(0,-65536)":QE$�"FC":QE�4:� 940 < QA$�"AND(65536,-65536)":QE$�"FC":QE�5:� 940 %<"� :<,QT$�"OR()":� 910 `<6QA$�"OR($FFFF,$FFFF)=$FFFF":� 920 �<8QA$�"OR($FFFF,$0000)=$FFFF":� 920 �<:QA$�"OR($7777,$8888)=$FFFF":� 920 �<<QA$�"OR($0000,$8888)=$8888":� 920 �<>QA$�"OR($7777,$0000)=$7777":� 920 =@QA$�"OR($FF*16,$000F)=$FFF":� 920 D=BQA$�"OR(2^15, 65535)=65535":� 920 k=JQA$�"OR(65535,-65535)=65535":� 920 �=|QA$�"OR(65536,0)":QE$�"FC":QE�6:� 940 �=~QA$�"OR(0,65536)":QE$�"FC":QE�7:� 940 �=�QA$�"OR(-65536,0)":QE$�"FC":QE�8:� 940 >�QA$�"OR(0,-65536)":QE$�"FC":QE�9:� 940 E>�QA$�"OR(65536,-65536)":QE$�"FC":QE�10:� 940 K>�� a>�QT$�"XOR()":� 910 �>�QA$�"XOR($FFFF,$FFFF)=$0000":� 920 �>�QA$�"XOR($FFFF,$0000)=$FFFF":� 920 �>�QA$�"XOR($7777,$8888)=$FFFF":� 920 �>�QA$�"XOR($7777,$FFFF)=$8888":� 920 $?�QA$�"XOR($7777,$0000)=$7777":� 920 K?�QA$�"XOR($FF*16,$0FFF)=$00F":� 920 r?�QA$�"XOR(2^15, 65535)=32767":� 920 �?�QA$�"XOR(65535,-65535)=$FFFE":� 920 �?�QA$�"XOR(65536,0)":QE$�"FC":QE�11:� 940 �?�QA$�"XOR(0,65536)":QE$�"FC":QE�12:� 940 @�QA$�"XOR(-65536,0)":QE$�"FC":QE�13:� 940 L@�QA$�"XOR(0,-65536)":QE$�"FC":QE�14:� 940 }@�QA$�"XOR(65536,-65536)":QE$�"FC":QE�15:� 940 �@�� �@ � �@*QU$�"Passed:"��(QR(1)) �@/� 980 �@4QU$�"Failed:"��(QR(0)) �@9� 980 �@f� �@p� QU � �  Ar� "...Press a key..." AtQL�0:QK��(0)  Av� QK�3 � � &Ax� >Az� 970:QU$�QA$:� 980 YA�QF$��$:QF��(�$):� Init tA�� QU�1 � � Q(999):QP�0 �A�QU$�"Running "�QF$:� 980 �A�QF$��(�$,QF�4)�".TST" �A�QR$(0)�"Fail: ":QR$(1)�"Pass: " �A�� �A�QU$�"Testing "�QT$:� Print Title B�� 980 B�� 970:� Do Assertion ,B�� � � 930 DB�QV���(QA$):� � � 0 ^B�QU$�QR$(QV)�QA$:� 980 tB�QR(QV)�QR(QV)�1:� �B�QU$��$(0)�" Error in "�QA$ �B�� 980 �B�� �B�� 970:� Assert Error �B�� � � 950 �B�QV��(QA$):� � � 0 �B�QU$�"No Error in "�QA$ C�� 980:QR(0)�QR(0)�1:� 6C�QU$��$(0)�" Error in "�QA$ ZC�QV��(�$(0)�QE$):QR(QV)�QR(QV)�1 tC�QU$�QR$(QV)�QU$:� 980 �C�� �:� � � 0 �C�� 150 �C�� so we can RETURN from Error �C�QA$�QA$�" ":� Convert ` to " �C�� QI�0 � �(QA$)�1 �C�QC��(&&QA$�QI) D�� QC�96 � � &&QA$�QI,34 D��:� <D�� QU � 988:� Output Line PD�� QL�20 � � 880 dD�� QU$:QL�QL�1:� yD�� QU�1 � � QU$:� �D�QN��(QU$)�2 �D�� &Q(0)�QP,QU$ �D�QP�QP�QN:� &Q(0)�1,13,10 �D��                  