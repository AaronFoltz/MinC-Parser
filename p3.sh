#! /bin/bash
clear
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

./yacc.macosx -v -Jsemantic=Semantic Parser.y
javac Parser.java

#java -jar /Users/aaron/Desktop/Dropbox/CS/CS540/JFlex/JFlex.jar /Users/aaron/Desktop/Dropbox/CS/CS540/Program3/Lexer.l
#javac /Users/aaron/Desktop/Dropbox/CS/CS540/Program3/Lexer.java

java Parser test0.mc
