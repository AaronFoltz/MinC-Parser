%{
import java.io.*;
import java.util.*;
%}
 
%token ID NUM IF ELSE WHILE TRUE FALSE BOOL INT TYPE_ID RETURN PRINTINT GETINT ASSIGN_OP REL_OP LOGICAL_OP
 
%left REL_OP
%left LOGICAL_AND LOGICAL_OR
%left LOGICAL_NOT
%left '+' '-'
%left '*'

%right SHIFT_ELSE
%right ELSE
 
%%            

start: {System.out.println();enterScope();} program {exitScope();}
	;

program:	program  prog_decls 
	|		prog_decls
	;

prog_decls:	fn_decl  
	| 		var_decl
	| 		type_decl	
	;

fn_decl: type ID {
					// Insert the function into the current scope
					insert($2, $1.val); 
					
					// Save the current function that we are inside.  This is used for
					//  	return checking.
					currentFunct = $2; 
					enterScope();
				  } params '{' var_decls statements '}'	{
																exitScope();
															}
	;

var_decl:	type ID ';' {
							insert($2, $1.val);
							
							// IF null, it isn't a type
							if($1.type == null){}
							
							// IF it is declaring a type, make sure that type exists
							else{
								if($1.type.equals("type")){
									// Set the parameters of the declaration to the parent
									//	This is the members of the struct
									$2.typeParams = lookup($1,3).typeParams;
									// Length of the array
									$2.length = lookup($1,3).length;
									//	Type of the declared identifier (from the parent)
									$2.parentType = lookup($1,3).type;
								}
							}
							
						}
	;

type_decl:	type '[' NUM ']' TYPE_ID ';' {insert($5, $1.val); $5.length = Integer.parseInt($3.val);}
	|		'{' {struct.clear();} type_list '}' TYPE_ID ';' {
																insert($5, "type_list");
																// The members of this struct were calculated in type_list
																$5.typeParams = struct;
															 }
	;

type_list:	type_list type ID ';' {		// Add to list of members of the struct
										struct.push($3);
										insert($3, $2.val);
									}
	|		type ID ';' {	// Add to list of members of the struct
							struct.push($3);
							insert($2, $1.val);
						}
	;

type:	INT	
	|	BOOL 
	|	TYPE_ID 
	;

params:	'(' ')'
	|		'(' param_list ')'
	;

param_list:	param_list ',' type ID {
										// IF not already declared, add it to the list of parameters
										// 	for the current function
										if(!insert($4, $3.val)){
											currentFunct.parameters.push($3.val);
										}
									}
	|		type ID {
						// IF not already declared, add it to the list of parameters
						// 	for the current function
						if(!insert($2, $1.val)){
							currentFunct.parameters.push($1.val);
						}
						
					}
	;

statements:	statements statement
	|		statement	
	;

var_decls:	var_decls var_decl
	|		{/*EMPTY*/}
	;

statement:	'{' {enterScope();} var_decls statements '}' {exitScope();}

	|		var {assignedVarType = $1.type; assignedVarName = $1.val;} ASSIGN_OP expression ';' {
										
										// There is a type Mismatch among the types or the type doesn't exist
										if(!assignedVarType.equals($4.type) && !assignedVarType.equals("default")){
											yytypeError(assignedVarName, $4.type, assignedVarType, 2);
										}
									  }
	|		PRINTINT '(' expression ')' ';' {		
												// Expression must result in an integer
												if($3.type.equals("int")){
													$$.type = "int";
												// Expression does not result in an integer
												}else{
													yytypeError("printint", $3.type, "int", 2);

													// Fix the error so we can continue without "cascading errors"
													$$.type = "int";
												}
											 }
	|		ID '(' ')' ';' { 
								// Lookup the function (only global scope needs to be checked)
								functionCalled = lookupFunction($1);
								
								// IF the function accepts parameters
								if(functionCalled.length > 0){
									yyfunctionError($1.val,2, functionCalled.parameters.size());
								}
								
								$$.type = functionCalled.type;
							}
	|		ID '(' expression_list ')' ';' { 
												// Lookup the function (only global scope needs to be checked)
												functionCalled = lookupFunction($1);
												
												// IF the function has been declared
												if(functionCalled.val != null){
													
													// IF the correct # of parameters isn't given
													if(parametersInCall.size() != functionCalled.parameters.size()){
														yyfunctionError($1.val,2, functionCalled.parameters.size());
														
													// Else it must have the correct amount of parameters
													}else{
														// Compare the given parameters to the functions parameters
														for(int i = 0; i < functionCalled.parameters.size(); i++){
															if(!functionCalled.parameters.get(i).equals(parametersInCall.get(i))){
																	yyfunctionError($1.val, 3, functionCalled.parameters.size());
															}	
														}	
													}
												}
												// Clear the parameters for another function call
												parametersInCall.clear();
												
												$$.type = functionCalled.type;
										   }
	|		WHILE '(' expression ')' statement {		
													// IF the expression results in a boolean
													if($3.type.equals("bool")){
														$$.type = "bool";
														
													// The result doesn't result in a boolean
													}else{
														yytypeError($3.val, $3.type, "bool", 2);

														// Fix the error so we can continue without "cascading errors"
														$$.type = "bool";
													}
												}
	|		IF '(' expression ')' statement ELSE statement {		
																// IF the expression results in a boolean
																if($3.type.equals("bool")){
																	$$.type = "bool";
																	
																// The result doesn't result in a boolean
																}else{
																	yytypeError($3.val, $3.type, "bool", 2);

																	// Fix the error so we can continue without "cascading errors"
																	$$.type = "bool";
																}
														  	}
	|		IF '(' expression ')' statement %prec SHIFT_ELSE {		
																// IF the expression results in a boolean
																if($3.type.equals("bool")){
																	$$.type = "bool";
																	
																// The result doesn't result in a boolean
																}else{
																	yytypeError($3.val, $3.type, "bool", 2);

																	// Fix the error so we can continue without "cascading errors"
																	$$.type = "bool";
																}
														  	   }
	|		RETURN '(' ')' ';' {
									// IF the current function doesn't have the return type void
									if(!currentFunct.type.equals("void")){
										yytypeError("return", "void", currentFunct.type, 2);	
									}		
								}
	|		RETURN '(' expression ')' ';' {
												// IF the current function isn't supposed to return
												// 		the given type.
												if(!currentFunct.type.equals($3.type)){
													yytypeError("return", $3.type, currentFunct.type, 2);
												}
										   }
	;

var:	ID { 	
				// Lookup the variable in the symbol table
				varCalled = lookup($1,1);
				
				// The var does exist
				if(varCalled.val != null){
					$$.type = varCalled.type;
					
				// The var does not exist - this fixes cascading return errors
				}else{
					$$.type = currentFunct.type;
				}
			}
	|	ID '[' expression ']' {	
									// Lookup the array on the symbol table
									arrayCalled = lookup($1,1);
									
									// There is an variable of that type
									if(arrayCalled.val != null){
										
										// The type referenced is not an array
										if(arrayCalled.type.equals("int") || arrayCalled.type.equals("bool") || arrayCalled.parentType.equals("type_list")){
											yytypeError(arrayCalled.val, arrayCalled.type, "an array", 1);
											$$.type = "default";
											
										// The type referenced must be an array
										}else{
											
											// Indexing array without an integer
											if($3.type != "int"){
												yytypeError("array", $3.type, "int",2);
												
											// The index is an integer
											}else{
												
												// Is the index greater than the length of the array?
												if(!(arrayCalled.length > Integer.parseInt($3.val))){
													yytypeError(arrayCalled.val, null, null, 4);
												}
											}
											$$.type = arrayCalled.parentType;
										}
										
									// There is no variable with that name
									}else{
										$$.type = "default";
									}
								}
	|	ID '.' ID {
						// Look up the structure on the symbol table
						structCalled = lookup($1,1);
						
						// IF the variables type isn't even a declared struct type
						if(structCalled.parentType == null || !structCalled.parentType.equals("type_list")){
							
							// The identifier isn't even declared at all
							if(structCalled.val !=null){
								yytypeError(structCalled.val, structCalled.type, "a type list", 1);
							}
							$$.type = "default";
							
							
						// The type referenced must be a user-declared type
						}else{
							error = true;
							
							// Iterate through the struct to see if it contains the identifier
							for(Semantic id: structCalled.typeParams){
								if(id.val.equals($3.val)){
									error = false;
									$$.type = id.type;
									$$.val = id.val;
								}
							}
							
							// There was an error (the identifier wasn't found)
							if(error){
								// The type doesn't contain the declaration for that identifier
								yytypeError($1.val, $1.type, $3.val, 3);
							}
							
						}
					}
	;

expression_list:	expression_list ',' expression {	// Push the function parameters onto a list
														parametersInCall.push($3.type);
													}
	|	expression {	// Push the function parameters onto a list
						parametersInCall.push($1.type);
					}
	;

expression:	bool1 LOGICAL_OP bool1 {		
										// IF both expressions are boolean
										if($1.type.equals("bool") && $3.type.equals("bool")){
											$$.type = $1.type;
											
											// IF there is no error here, we want this to be known as
											//	an expression in subsequent errors
											$$.val = "expression";
											
										// Both expressions are not boolean
										}else{
											// The second expression isn't of type bool
											if($1.type.equals("bool")){
												yytypeError($3.val, $3.type, $1.type, 1);
											
											// The first expression isn't of type boolean
											}else if($3.type.equals("bool")){
												yytypeError($1.val, $1.type, $3.type, 1);
											}
											// Fix the error so we can continue without "cascading errors"
											$$.type = "bool";
										}
								  }
	|	bool1 {$$.type = $1.type;}
	;
	
bool1:	LOGICAL_NOT bool1 {	
							// IF the expression results in a boolean
							if($2.type.equals("bool")){
								$$.type = "bool";
								// IF there is no error here, we want this to be known as
								//	an expression in subsequent errors
								$$.val = "expression";
							
							// The expression doesn't result in a boolean
							}else{
								yytypeError($2.val, $2.type, "bool", 1);

								// Fix the error so we can continue without "cascading errors"
								$$.type = "bool";
								$$.val = "expression";
							}
					  }
	|	bool2 {$$.type = $1.type;}
	;

bool2:	exp REL_OP exp {		
							// IF both expression result in integers
							if($1.type.equals("int") && $3.type.equals("int")){
								$$.type = "bool";
							
							// Both expressions do not result in an integer
							}else{
								
								// The second expression isn't of type int
								if($1.type.equals("int")){
									yytypeError($3.val, $3.type, $1.type, 1);
								
								// The first expression isn't of type int
								}else if($3.type.equals("int")){
									yytypeError($1.val, $1.type, $3.type, 1);
								}
								
								// Fix the error so we can continue without "cascading errors"
								$$.type = "bool";
							}
					  }
	|	exp {$$.type = $1.type;}
	;

exp:	exp '+' term {		
							// IF both expression result in integers
							if($1.type.equals("int") && $3.type.equals("int")){
								$$.type = "int";
								
							// Both expressions do not result in an integer
							}else{
								
								// The second expression isn't of type int
								if($1.type.equals("int")){
									yytypeError($3.val, $3.type, $1.type, 1);
								
								// The first expression isn't of type int
								}else if($3.type.equals("int")){
									yytypeError($1.val, $1.type, $3.type, 1);
								}
								
								// Fix the error so we can continue without "cascading errors"
								$$.type = "int";
							}
					  }
	|	exp '-' term {		// IF both expression result in integers
							if($1.type.equals("int") && $3.type.equals("int")){
								$$.type = $1.type;
								
							// Both expressions do not result in an integer	
							}else{
								
								// The second expression isn't of type int
								if($1.type.equals("int")){
									yytypeError($3.val, $3.type, $1.type, 1);
									
								// The first expression isn't of type int
								}else if($3.type.equals("int")){
									yytypeError($1.val, $1.type, $3.type, 1);
								}
								
								// Fix the error so we can continue without "cascading errors"
								$$.type = "int";
							}
					  }
	|	term {$$.type = $1.type;}
	;

term:	term '*' fact {		// IF both expression result in integers
							if($1.type.equals("int") && $3.type.equals("int")){
								$$.type = $1.type;
								
							// Both expressions do not result in an integer
							}else{
								
								// The second expression isn't of type int
								if($1.type.equals("int")){
									yytypeError($3.val, $3.type, $1.type, 1);
									
								// The first expression isn't of type int
								}else if($3.type.equals("int")){
									yytypeError($1.val, $1.type, $3.type, 1);
								}
								
								// Fix the error so we can continue without "cascading errors"
								$$.type = "int";
							}
					  }
	|	fact {$$.type = $1.type;}
	;

fact:	'-' fact {			// The expression results in an integer
							if($2.type.equals("int")){
								$$.type = "int";
								// IF there is no error here, we want this to be known as
								//	an expression in subsequent errors
								$$.val = "expression";
								
							// The expression doesn't result in an integer
							}else{
								yytypeError($2.val, $2.type, "int", 1);
								
								// Fix the error so we can continue without "cascading errors"
								$$.type = "int";
							}
					  }
	|	factor	{$$.type = $1.type;}
	;

factor:	'(' expression ')'	{$$.type = $2.type;$$.val = $2.val;}
	|	ID '(' ')' { 	// Lookup the function that was called (global scope only)
						functionCalled = lookupFunction($1);
						
						// The function does exist
						if(functionCalled.val != null){
							// IF the function accepts parameters
							if(functionCalled.length > 0){
								yyfunctionError($1.val, 2, functionCalled.parameters.size());
							}
							$$.type = functionCalled.type;
							
						// The function doesn't exist
						}else{
								$$.type = currentFunct.type;
							}
					}
	|	ID '(' expression_list ')' { 	// Lookup the function that was called (global scope only)
										functionCalled = lookupFunction($1);
										
										// IF the function does exist
										if(functionCalled.val != null){
											
											// IF the correct # of parameters isn't given
											if(parametersInCall.size() != functionCalled.parameters.size()){
												yyfunctionError($1.val,2, functionCalled.parameters.size());
												
											// Else it must have the correct amount
											}else{
												
												// Compare the parameters to the function parameters
												for(int i = 0; i < functionCalled.parameters.size(); i++){
													if(!functionCalled.parameters.get(i).equals(parametersInCall.get(i))){
															yyfunctionError($1.val, 3, functionCalled.parameters.size());
													}	
												}	
											}
											$$.type = functionCalled.type;
											
										// No such funciton exists - return the type of the current function
										//  that we are in.  This resolves returning undeclared functions
										//  and the resulting type error from incorrect return type
										}else{
											$$.type = currentFunct.type;
										}
										
										// Clear the parameters for another function call
										parametersInCall.clear();
										
								   }
	|	var    
	|	GETINT '(' ')' {$$.type = "int";}
	|	NUM 
	|	TRUE	{ $$.type = "bool";}
	|	FALSE	{ $$.type = "bool";}
	;
	
	
%%
	// LinkedList symbolTable - used to provide all the operations of a stack
	// 		with the added benefit of an easy search mechanism.  This holds 
	//		the current state of the Symbol Table tree.
	private LinkedList<LinkedList> symbolTable = new LinkedList<LinkedList>();
	
	// LinkedList scope - a LinkedList structure is used to hold the state of
	// 		the local(current) scope
	// parent - holds the parent(s) of the current scope
	// global - holds the "global" scope
	// struct - holds the members of a struct data type
	private LinkedList<Semantic> scope, parent, global;
	private LinkedList<Semantic> struct = new LinkedList<Semantic>();

	// currentFunct - Holds the current function.  This is used for returns
	// functionCalled - Holds the function that was just looked up
	// structCalled - holds the struct that was looked up
	// arrayCalled - holds the array that was just looked up
	// varCalled - holds the variable that was just looked up
	private Semantic currentFunct, functionCalled, structCalled, arrayCalled, varCalled;
	
	// lexer - an instance of the lex scanner
	private Lexer lexer;
	
	// parametersInCall - List which holds the types of the parameters in a function call
	private LinkedList<String> parametersInCall = new LinkedList<String>();
	
	// Boolean checking to see if an identifier is a member of a struct
	boolean error;
	
	// Holds the variable type and name - used for assigning values to a variables
	//	This had to be done because the normal $1 notation would not work for some reason
	String assignedVarType, assignedVarName;
		
	/**
	 * Main method in order to call the parser
	 */
	public static void main (String [] args) throws IOException {
		Parser yyparser = new Parser(new FileReader(args[0]));
		yyparser.yyparse();
	} 
	
	/**
	 * Constructor for this Parser class.  It simply instantiates an instance of 
	 * the lexer scanner
	 */
	public Parser (Reader r) {
		lexer = new Lexer (r, this);
	}
	
	/* Interfaces to the lexer */
	private int yylex() {
		int retVal = -1;
		try {
			retVal = lexer.yylex();
		} catch (IOException e) {
			System.err.println("IO Error:" + e);
		}
		return retVal;
	}
	
	/* error reporting */
	private void yyerror(String error) {
		System.err.println("Error: " + error + " at line " + lexer.getLine());
		System.err.println("String rejected");
	}
	
	private void yytypeError(String id, String type, String expectedType, int error){
		switch(error){
		case 1: System.out.println("Line " + lexer.getLine() + ": Type Error - " + id + " expected to be " 
					+ expectedType + ", received type " + type);
			break;
		case 2: System.out.println("Line " + lexer.getLine() + ": Type Error - " + id + " expected " 
					+ expectedType + ", received type " + type);
			break;	
		case 3: System.out.println("Line " + lexer.getLine() + ": Type " + id + " doesn't declare variable "
					+ expectedType);
			break;	
		case 4: System.out.println("Line " + lexer.getLine() + ": Indexing outside of array " + id);
		}
	}
	
	private void yyfunctionError(String id, int error, int numParams){
		switch(error){
			case 1:	System.out.println("Line " + lexer.getLine() + ": " + id + " must accept at least one parameter");
				break;
			case 2: System.out.println("Line " + lexer.getLine() + ": " + id + " must accept " + numParams + " parameters");
				break;
			case 3: System.out.println("Line " + lexer.getLine() + ": " + id + " cannot accept those parameter types");
				break;
		}
	}

/***********************************************
 *   SYMBOL TABLE IMPLEMENTATION				*                                             
 ***********************************************/
	
 	/**
	 * Enters a new scope.  Creates a new linked list which will hold the symbols
	 */
	 private void enterScope(){
		 scope = new LinkedList<Semantic>();
		 symbolTable.addFirst(scope);	
	 }
	 
	 /**
	  * Exits the current scope 
	  */
	 private void exitScope(){
		 symbolTable.pop();
	 }
	 
	 /**
	  * Inserts the identifier and its type into the current scope if it is not already there.
	  * @return boolean - If the identifier is already in the current scope
	  */
	 
	 @SuppressWarnings("unchecked")
	 private boolean insert(Semantic id, String type){
		 // Set the identifiers type
		 id.type = type;	 	 
	
		 
		 // Grab the current local scope
		 scope = (LinkedList<Semantic>) symbolTable.peek();
		 
		 // Iterate through the identifiers already in the scope
		 for(Semantic identifier : scope){
		 	 
		 	 // If the identifier is already available - return true
			 if(identifier.val.equals(id.val)){
				 System.out.println("Line " + lexer.getLine() + ": Duplicate declaration of " + id.val);
				 return true;
			 }
		 }
		 
		 // If the identifier is not already available, add it.
		 scope.add(id);
		 return false;
	 }
	 
	 /**
	  * Finds the identifier in the symbol table, either in the local scope or its parent scopes
	  * @param value - an object with a value that we need to find
	  * @param error - decided by the calling method, used for error printing
	  * @return Semantic - an instance of the identifier that we were looking for 
	  */
	 @SuppressWarnings("unchecked")
	 private Semantic lookup(Semantic value, int error){
		 //@@System.out.println("LOOKUP: " + value.val);
		 
		 // Grab the current local scope
		 scope = (LinkedList) symbolTable.peek();
		 
		 // Search for the identifier in the current scope.  If found, return.
		 for(Semantic identifier : scope){
			 if(identifier.val.equals(value.val)){
				 return identifier;
			 }
		 }
		 
		 for(int x = 1; x < symbolTable.size(); x++){
			 
				// Grab the parents scope
				 scope = (LinkedList) symbolTable.get(x);
				 
				 // Iterate through parent to see if the identifier is available
				 for(Semantic identifier : scope){
					 if(identifier.val.equals(value.val)){
						 return identifier;
					 }
				 }
		 }
		 
		 // Print out a respective error
		 switch(error){
			case 1: System.out.println("Line " + lexer.getLine() + ": Undeclared variable " + value.val);
				break;
			case 2: System.out.println("Line " + lexer.getLine() + ": Undeclared function " + value.val);
				break;
			case 3: System.out.println("Line " + lexer.getLine() + ": Undeclared type " + value.val);
				break;
			default:
				break;	 
		 }
		 
		 // If not found, send back a default Semantic object
		 return new Semantic(null, "default", -1);
	 }
	 
	 /**
	  * Find the function by checking the global scope only
	  * @param value - a Semantic object with a value (identifier) that we wish to lookup in the symbol table.
	  * @return Semantic - an instance of the found function
	  */
	 @SuppressWarnings("unchecked")
	 private Semantic lookupFunction(Semantic value){	 	 
		 
		 // Grab the global scope
		 global = (LinkedList) symbolTable.getLast();
		 
		 // Iterate through the functions/types, returning if found
		 for(Semantic identifier : global){
			 if(identifier.val.equals(value.val)){
				return identifier;		 
			 }
		 }
		 
		 // The function has not yet been declared
		 System.out.println("Line " + lexer.getLine() + ": Undeclared function " + value.val);
		 
		 // If nothing is found, send back a default Semantic object
		 return new Semantic(null, "default", -1);
	 }
	 
/***********************************************
 *   Semantic object - in place of ParserVal   *                                          
 ***********************************************/
 
	 public static final class Semantic{
		 private String val;			// Name of the identifier
		 private String type;			// Type of the identifier
		 private int length;			// length of the array
		 private String parentType; 	// original type of the declaration
		 
		 // parameters - List which holds the parameters of a function
		 public LinkedList<String> parameters = new LinkedList<String>();
		 
		 // typeParams - List which holds the members of a struct
		 public LinkedList<Semantic> typeParams = new LinkedList<Semantic>();
		 
		 public Semantic(){	 
			 
		 }
		 public Semantic(String id, String type){
			this.val = id;
			this.type = type;
		 }	 
		 
		 public Semantic(String id, String type, int length){
			this.val = id;
			this.type = type;
			this.length = length;
		 }
		 public Semantic(String value){
			 this.val = value;
		 }
		 public Semantic(int ival){
		 }
		 public Semantic(int ival, String sval){
		 } 	 	 
	 }