/*
 * generated by Xtext 2.24.0
 */
package dk.sdu.mmmi.mdsd.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import javax.swing.JOptionPane
import dk.sdu.mmmi.mdsd.mathAssignmentLanguage.MathExp
import dk.sdu.mmmi.mdsd.mathAssignmentLanguage.Plus
import dk.sdu.mmmi.mdsd.mathAssignmentLanguage.Minus
import dk.sdu.mmmi.mdsd.mathAssignmentLanguage.Mult
import dk.sdu.mmmi.mdsd.mathAssignmentLanguage.Div
import dk.sdu.mmmi.mdsd.mathAssignmentLanguage.Expression
import dk.sdu.mmmi.mdsd.mathAssignmentLanguage.NUM
import dk.sdu.mmmi.mdsd.mathAssignmentLanguage.PAR
import dk.sdu.mmmi.mdsd.mathAssignmentLanguage.VAR
import dk.sdu.mmmi.mdsd.mathAssignmentLanguage.SYM
import java.util.Map
import java.util.HashMap
import java.util.Stack
import dk.sdu.mmmi.mdsd.mathAssignmentLanguage.MathSystem
import dk.sdu.mmmi.mdsd.mathAssignmentLanguage.EXT
import dk.sdu.mmmi.mdsd.mathAssignmentLanguage.Declaration
import dk.sdu.mmmi.mdsd.mathAssignmentLanguage.External

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class MathAssignmentLanguageGenerator extends AbstractGenerator {

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val mathSystem = resource.allContents.filter(MathSystem).next
		//val result = math.compute
		//mathSystem.generateExternalInterface(fsa)
		mathSystem.mathExpresions.filter(MathExp).forEach[display]
		mathSystem.generateMathPy(fsa)
		//System.out.println(result as int)
		//System.out.println("Math expression = "+math.display)
		//JOptionPane.showMessageDialog(null, "result = "+result,"Math Language", JOptionPane.INFORMATION_MESSAGE)
	}

	def static int compute(MathExp math) {
		val myMap = new HashMap<String, Stack<Integer>>
		math.exp.computeExp(myMap)
	}
	
	def static int computeExp(Expression exp, Map<String, Stack<Integer>> map) {
		var return_exp_result_after_pop = 0 as int

		switch exp {
			Plus: exp.left.computeExp(map) + exp.right.computeExp(map)
			Minus: exp.left.computeExp(map) - exp.right.computeExp(map)
			Mult: exp.left.computeExp(map) * exp.right.computeExp(map)
			Div: exp.left.computeExp(map) / exp.right.computeExp(map)
			NUM: exp.value
			PAR: exp.innerExp.computeExp(map)
			VAR: 
			{
				// Get the current value of the variable
				map.get(exp.varName).peek()
			}
			SYM: 
			{
				// If the key exists, then expand upon the existing stack
				if (map.containsKey(exp.varName))
				{
					map.get(exp.varName).push(exp.value.computeExp(map))
				}
				// Otherwise create a new stack and push into it
				else
				{
					val newStack = new Stack<Integer>
					newStack.push(exp.value.computeExp(map))
					
					map.put(exp.varName, newStack)
				
				}
				// Delay returning the result until the pop have happened
				// But calculate before the pop
			    return_exp_result_after_pop = exp.innerExp.computeExp(map)
			    map.get(exp.varName).pop()
			    return_exp_result_after_pop
			}
			default: 0
		}
	}

	def String display(MathExp math) {
		val str = "Expression of " + math.tag + " is: " + math.exp.displayExp + " = " + Integer.toString(math.compute)
		System.out.println(str)
		str
	}
	
	def static String displayExp(Expression exp){
		switch exp {
			Plus: exp.left.displayExp + ' + ' + exp.right.displayExp
			Minus: exp.left.displayExp + ' - ' + exp.right.displayExp
			Mult: exp.left.displayExp + ' * ' + exp.right.displayExp
			Div: exp.left.displayExp + ' / ' + exp.right.displayExp
			NUM: Integer.toString(exp.value)
			PAR: "(" + exp.innerExp.displayExp + ")"
			VAR: exp.varName
			SYM: "let " + exp.varName + " be " + exp.value.displayExp + " in (" + exp.innerExp.displayExp + ")"
			EXT:
			 	{
			 		var str = ""
			 		for (par:exp.parameters)
			 		{
			 			str += par.displayExp + ", "
			 		}
			 		str = str.substring(0, str.length - 2)
			 		exp.target.name + "(" + str + ")"
		 		} 
			default: "0"
		}	
	}

	def static String displayExpPy(Expression exp){
		switch exp {
			Plus: exp.left.displayExpPy + ' + ' + exp.right.displayExpPy
			Minus: exp.left.displayExpPy + ' - ' + exp.right.displayExpPy
			Mult: exp.left.displayExpPy + ' * ' + exp.right.displayExpPy
			Div: exp.left.displayExpPy + ' / ' + exp.right.displayExpPy
			NUM: Integer.toString(exp.value)
			PAR: "(" + exp.innerExp.displayExpPy + ")"
			VAR: exp.varName
			SYM: "(lambda " + exp.varName + " = " + exp.value.displayExpPy + ": " + exp.innerExp.displayExpPy + ")()" 
			EXT:
			 	{
			 		var str = ""
			 		for (par:exp.parameters)
			 		{
			 			str += par.displayExpPy + ", "
			 		}
			 		str = str.substring(0, str.length - 2)
			 		exp.target.name + "(" + str + ")"
		 		} 
			default: "0"
		}	
	}

	def generateMathPy(MathSystem mathSystem, IFileSystemAccess2 fsa){
		fsa.generateFile("main.py", mathSystem.generateMain)
		val externals = mathSystem.mathExpresions.filter(External)

		mathSystem.mathExpresions.filter(MathExp).forEach[generateMathFile(fsa, externals)]
	}
	
	// Imports all the math expressions and calls them
	def CharSequence generateMain(MathSystem mathSystem)
	'''
	?FOR math:mathSystem.mathExpresions.filter(MathExp)?
	from src import ?math.tag?
	?ENDFOR?

	?FOR math:mathSystem.mathExpresions.filter(MathExp)?
	?math.tag?.call()
	?ENDFOR?
	'''
	
	def generateMathFile(MathExp math, IFileSystemAccess2 fsa, Iterable<External> externals){
		fsa.generateFile("src/" + math.tag + ".py", math.generateContent(externals))
	}
	
	def CharSequence generateContent(MathExp math, Iterable<External> externals)
	'''
	# Import external functions (these most be made manually in the external folder)
	?FOR external:externals?
	from .external.?external.name? import *
	?ENDFOR?

	def call():
		print("Expression of ?math.tag? is: ?math.exp.displayExp? = " + str(?math.exp.displayExpPy?))
	'''

}



