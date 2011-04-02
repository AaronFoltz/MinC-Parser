/**
 * Aaron Foltz
 * CS540
 * Program 3
 */

import java.io.*;

%%
%class Lexer
%unicode
%line
%column
%byaccj

%{
	private Parser yyparser;
		
	// lexer - An instance of the Lexer class
	private static Lexer lexer;
	/**
	 * Constructor for this lexer class 
	 */
	public Lexer (Reader r, Parser yyparser) {
		this (r);	
		this.yyparser = yyparser;
	}
	
	public int getLine() {
		return yyline+1;
	}
	
	
%}

/*******************************************************************************
 *   		         				Lexer     									 *					                                        
 *******************************************************************************/

// Identifiers start with a lower-case alphabetic character, followed by zero or more alphabetic
// characters, numbers or underscores
identifier = [a-z][a-zA-Z0-9_]*

types = [A-Z][a-zA-Z0-9_]*

// Numbers are strings of digits and are non-negative
number = [0-9]+

// Comments begin with the percent symbol
comment = "//".+

%%
	
" "				{ ;}
[\t]			{ ;}
"if"			{ return Parser.IF;}
"else"			{ return Parser.ELSE;}
"while"			{ return Parser.WHILE;}
"true"			{ return Parser.TRUE;}
"false"			{ return Parser.FALSE;}
"bool"			{ yyparser.yylval = new Parser.Semantic("bool"); return Parser.BOOL;}
"int"			{ yyparser.yylval = new Parser.Semantic("int"); return Parser.INT;}
"return"		{ return Parser.RETURN;}
"printint"		{ return Parser.PRINTINT;}
"getint"		{ return Parser.GETINT;}


","				{ return (int) yycharat(0);}
";"				{ return (int) yycharat(0);}

"+"				{ return (int) yycharat(0);}
"-"				{ return (int) yycharat(0);}
"*"				{ return (int) yycharat(0);}

"="				{ return Parser.ASSIGN_OP;}
"<"				{ return Parser.REL_OP;}
"<="			{ return Parser.REL_OP;}
">="			{ return Parser.REL_OP;}
">"				{ return Parser.REL_OP;}
"=="			{ return Parser.REL_OP;}
"!="			{ return Parser.REL_OP;}
"("				{ return (int) yycharat(0);}
")"				{ return (int) yycharat(0);}
"{"				{ return (int) yycharat(0);}
"}"				{ return (int) yycharat(0);}
"&&"			{ return Parser.LOGICAL_OP;}
"||"			{ return Parser.LOGICAL_OP;}
"!"				{ return Parser.LOGICAL_NOT;}
"["				{ return (int) yycharat(0);}
"]"				{ return (int) yycharat(0);}
"."				{ return (int) yycharat(0);}

{identifier}	{ yyparser.yylval = new Parser.Semantic(yytext()); return Parser.ID;}
{types}			{ yyparser.yylval = new Parser.Semantic(yytext(), "type"); return Parser.TYPE_ID;}

{number}		{ yyparser.yylval = new Parser.Semantic(yytext(), "int"); return Parser.NUM;}

{comment}		{;}

[\n]			{;}

[&%$#@~\^\\_\"\'?]			{;}
