package cesk

import scala.util.parsing.combinator.JavaTokenParsers;

/**
 * A parser for Dalvik to OOCESK objects
 */
class DalvikParser extends JavaTokenParsers{

	def classdef:Parser[ClassDef] = ( 
		"class"~ident~"extends"~ident~"{"~opt(rep(fielddef))~opt(rep(methoddef))~"}" ^^ { 
			case "class"~className~"extends"~superClass~"{"~fields~methods~"}" => 
				new ClassDef(className, superClass)
						.addFields(fields.get.toArray[FieldDef])
						.addMethods(methods.get.toArray[MethodDef])
		}| failure("illegal classdef")
	)
				
  	def fielddef:Parser[FieldDef] = ( "var"~ident~";" ^^ { 
  			case "var"~fieldName~";" => new FieldDef(fieldName) 
	}| failure("illegal fielddef")) 
  	
  	def methoddef:Parser[MethodDef] = ( "def"~ident~"("~opt(repsep(register, ","))~")"~"{"~opt(stmt)~"}" ^^ { 
  			case "def"~methodName~"("~formals~")"~"{"~body~"}" =>  
  			  	new MethodDef(methodName, formals.get.toArray, body.get)
	} | failure("illegal methoddef") )
  	
  	def register = ("$"~ident ^^ { case "$"~reg => reg } | failure("illegal register"))
  	
	def stmt:Parser[Stmt] = ( /* labelstmt 
							|  skipstmt
							|  gotostmt
							|  ifstmt
							|  fieldassignstmt
							|  returnstmt
							|  assignaexpstmt
							|  newstmt
							|  invokestmt
							|  invokesuperstmt
							|  pushhandlerstmt
							|  pophandlerstmt
							|  throwstmt
							|  moveexceptionstmt )

	def labelstmt:Parser[LabelStmt] = "label"~ident~";"~opt(stmt) ^^ { 
			case "label"~label~";"~Some(next) => new LabelStmt(label, next)
			case "label"~label~";"~None  => new LabelStmt(label, null) 
	}
	
	def skipstmt = "skip"~";"~opt(stmt) ^^{ 
			case "skip"~";"~Some(next) => new SkipStmt(next)
			case "skip"~";"~None  => new SkipStmt(null) 
	}
	
	def gotostmt = "goto"~ident~";"~opt(stmt) ^^ { 
	  		case "goto"~label~";"~Some(next) => new GotoStmt(next, label)
	  		case "goto"~label~";"~None => new GotoStmt(null, label)
	}
	  
	def ifstmt = "if"~aexp~"goto"~ident~";"~opt(stmt) ^^ { 
	  		case "if"~aexpr~"goto"~label~";"~Some(next) => new IfStmt(next, aexpr, label)
	  		case "if"~aexpr~"goto"~label~";"~None => new IfStmt(null, aexpr, label)
	}
	
	def fieldassignstmt:Parser[FieldAssignStmt] = ( aexp~"."~ident~":="~aexp~";"~opt(stmt) ^^ { 
	  		case lhs~"."~field~":="~rhs~";"~Some(next) => new FieldAssignStmt(next, lhs, field, rhs)
	  		case lhs~"."~field~":="~rhs~";"~None => new FieldAssignStmt(null, lhs, field, rhs)
	} | failure("invalid fieldassignstmt")) 
	
	def returnstmt = "return"~aexp~";"~opt(stmt) ^^ { 
	  		case "return"~aexpr~";"~Some(next) => new ReturnStmt(next, aexpr)
	  		case "return"~aexpr~";"~None => new ReturnStmt(null, aexpr)
	}
	
	def assignaexpstmt = "$"~ident~":="~(aexp)~";"~opt(stmt) ^^ { 
	  		case "$"~name~":="~aexpr~";"~Some(next) => new AssignAExpStmt(next, name, aexpr)
	  		case "$"~name~":="~aexpr~";"~None => new AssignAExpStmt(null, name, aexpr)
	}

	def pushhandlerstmt = "push-handler"~ident~ident~";"~opt(stmt) ^^ { 
	  		case "push-handler"~className~label~";"~Some(next) => new PushHandlerStmt(next, className, label)
	  		case "push-handler"~className~label~";"~None => new PushHandlerStmt(null, className, label)
	}
	
	def pophandlerstmt = "pop-handler"~";"~opt(stmt) ^^ { 
	  		case "pop-handler"~";"~Some(next) => new PopHandlerStmt(next)
	  		case "pop-handler"~";"~None => new PopHandlerStmt(null)
	}
	
	def throwstmt = "throw"~aexp~";"~opt(stmt) ^^ { 
	  		case "throw"~aexpr~";"~Some(next) => new ThrowStmt(next, aexpr)
	  		case "throw"~aexpr~";"~None => new ThrowStmt(null, aexpr)
	}
	
	def moveexceptionstmt = "move-exception"~"$"~ident~";"~opt(stmt) ^^ { 
	  		case "move-exception"~"$"~reg~";"~Some(next) => new MoveExceptionStmt(next, reg)
	  		case "move-exception"~"$"~reg~";"~None => new MoveExceptionStmt(null, reg)
	}
	
	def cexp = (  newstmt 
				| invokestmt 
				| invokesuperstmt )
			
	def newstmt = "$"~ident~":="~"new"~ident~";"~opt(stmt) ^^ { 
			case "$"~lhs~":="~"new"~className~";"~Some(next) => new NewStmt(next, lhs, className)
			case "$"~lhs~":="~"new"~className~";"~None  => new NewStmt(null, lhs, className) 
	}	
	
	def invokestmt =  "$"~ident~":="~"invoke"~aexp~"."~ident~"("~opt(repsep(aexp,","))~")"~opt(stmt) ^^{ 
			case "$"~lhs~":="~"invoke"~obj~"."~methodName~"("~args~")"~Some(next) => 
			  	new InvokeStmt(next, lhs, obj, methodName, args.get.toArray)
			case "$"~lhs~":="~"invoke"~obj~"."~methodName~"("~args~")"~None => 
			  	new InvokeStmt(null, lhs, obj, methodName, args.get.toArray)
	}
	  
	def invokesuperstmt = "$"~ident~":="~"invoke"~"super"~"."~ident~"("~opt(repsep(aexp,","))~")"~opt(stmt) ^^{ 
			case "$"~lhs~":="~"invoke"~obj~"."~methodName~"("~args~")"~Some(next) => 
			  	new InvokeSuperStmt(next, lhs, methodName, args.get.toArray)
			case "$"~lhs~":="~"invoke"~obj~"."~methodName~"("~args~")"~None => 
			  	new InvokeSuperStmt(null, lhs, methodName, args.get.toArray)
		}
	
	def aexp = (  thisexp
		       |  booleanexp
		       |  nullexp
		       |  voidexp
		       |  registerexp
		       |  intexp
		       |  atomicopexp
		       |  instanceofexp
		       |  fieldexp )

	def thisexp = "this" ^^ { case _ => new ThisExp() }
	
	def booleanexp = ( "true" | "false" ) ^^ {
		case "true" => new BooleanExp(true)
		case "false" => new BooleanExp(false)
	}
	
	def nullexp = "null" ^^ { case _ => new NullExp() }
	
	def voidexp = "void" ^^ { case _ => new VoidExp() }
	
	def registerexp = "$"~ident ^^ { case "$"~register => new RegisterExp(register) }
	
	def intexp = wholeNumber ^^ { case num => new IntExp(num.toInt) }
	
	def atomicopexp:Parser[AtomicOpExp] = "atomic-op"~"("~repsep(aexp, ",")~")" ^^ {
		//TO DO: support more PrimOps defaulting to add
		case "atomic-op"~"("~args~")" => new AtomicOpExp(PrimOp.ADD, args.toArray)
	}
	
	def instanceofexp:Parser[InstanceOfExp] = "instanceof"~"("~aexp~","~ident~")" ^^ {
		case  "instanceof"~"("~aexpr~","~className~")" => new InstanceOfExp(aexpr, className)
	}
	
	def fieldexp:Parser[FieldExp] = aexp~"."~ident ^^ {
		case aexpr~"."~fieldName => new FieldExp(aexpr, fieldName)
	}
   
}
