package de.peeeq.wolf.jvmmodel

import com.google.inject.Inject
import org.eclipse.xtext.xbase.jvmmodel.AbstractModelInferrer
import org.eclipse.xtext.xbase.jvmmodel.IJvmDeclaredTypeAcceptor
import org.eclipse.xtext.xbase.jvmmodel.JvmTypesBuilder
import de.peeeq.wolf.wolf.Model
import de.peeeq.wolf.wolf.AstSpec
import de.peeeq.wolf.wolf.Constructor
import de.peeeq.wolf.wolf.SumType
import de.peeeq.wolf.wolf.ListType
import de.peeeq.wolf.wolf.AstElement
import de.peeeq.wolf.wolf.AttributeDef
import de.peeeq.wolf.wolf.AstElement
import java.util.Map
import java.util.HashMap
import org.eclipse.emf.ecore.resource.Resource
import java.util.List
import java.util.ArrayList

/**
 * <p>Infers a JVM model from the source model.</p> 
 *
 * <p>The JVM model should contain all elements that would appear in the Java code 
 * which is generated from the source model. Other models link against the JVM model rather than the source model.</p>     
 */
class WolfJvmModelInferrer extends AbstractModelInferrer {
	/**
     * convenience API to build and initialize JVM types and their members.
     */
	@Inject extension JvmTypesBuilder


	var Map<Resource, Model> models = new HashMap
	
	


	def List<Model> getModels(String packageName) {
		val List<Model> l = new ArrayList
		for (model : models.values) {
			l.add(model)
		}
		return l
	}
	
	def List<AstSpec> getAstSpecs(Model m) {
		val List<AstSpec> l = new ArrayList
		for (s : m.specifications) {
			switch s {
				AstSpec: l.add(s)
			}
		}
		return l
	}
	
	def List<SumType> getSumTpes(String packageName) {
		val List<SumType> l = new ArrayList
		for (m : packageName.models) {
			for (spec : m.astSpecs) {
				for (e : spec.elements) {
					switch (e) {
						SumType: l.add(e)
					}
				}
			}
		}
		return l
	}
	
	def List<ListType> getListTpes(String packageName) {
		val List<ListType> l = new ArrayList
		for (m : packageName.models) {
			for (spec : m.astSpecs) {
				for (e : spec.elements) {
					switch (e) {
						ListType: l.add(e)
					}
				}
			}
		}
		return l
	}
	
	def List<Constructor> getConstructors(String packageName) {
		val List<Constructor> l = new ArrayList
		for (m : packageName.models) {
			for (spec : m.astSpecs) {
				for (e : spec.elements) {
					switch (e) {
						SumType: for (part : e.elements) {
							switch part.constr {
								Constructor: l.add(part.constr)
							}
						}
						Constructor: l.add(e)
					}
				}
			}
		}
		return l
	}
	
	/**
	 * The dispatch method {@code infer} is called for each instance of the
	 * given element's type that is contained in a resource.
	 * 
	 * @param element
	 *            the model to create one or more
	 *            {@link org.eclipse.xtext.common.types.JvmDeclaredType declared
	 *            types} from.
	 * @param acceptor
	 *            each created
	 *            {@link org.eclipse.xtext.common.types.JvmDeclaredType type}
	 *            without a container should be passed to the acceptor in order
	 *            get attached to the current resource. The acceptor's
	 *            {@link IJvmDeclaredTypeAcceptor#accept(org.eclipse.xtext.common.types.JvmDeclaredType)
	 *            accept(..)} method takes the constructed empty type for the
	 *            pre-indexing phase. This one is further initialized in the
	 *            indexing phase using the closure you pass to the returned
	 *            {@link org.eclipse.xtext.xbase.jvmmodel.IJvmDeclaredTypeAcceptor.IPostIndexingInitializing#initializeLater(org.eclipse.xtext.xbase.lib.Procedures.Procedure1)
	 *            initializeLater(..)}.
	 * @param isPreIndexingPhase
	 *            whether the method is called in a pre-indexing phase, i.e.
	 *            when the global index is not yet fully updated. You must not
	 *            rely on linking using the index if isPreIndexingPhase is
	 *            <code>true</code>.
	 */
	def dispatch void infer(Model element, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		
		models.put(element.eResource, element)
				
		// Here you explain how your model is mapped to Java elements, by writing the actual translation code.
		val packageName = element.name

		// An implementation for the initial hello world example could look like this:
		for (spec : element.specifications) {
			switch spec {
				AstSpec:
					for (elem : spec.elements) {
						inferForElement(elem, packageName, acceptor, element)
					}
//				AttributeDef:
//					createAttribute(spec, packageName)
			}
		}

		//   		acceptor.accept(element.toClass("my.company.greeting.MyGreetings"))
		//   			.initializeLater([
		//   				for (greeting : element.greetings) {
		//   					members += greeting.toMethod("hello" + greeting.name, greeting.newTypeRef(typeof(String))) [
		//   						body = [
		//   							append('''return "Hello «greeting.name»";''')
		//   						]
		//   					]
		//   				}
		//   			])
		}

		def createAttribute(AttributeDef attr, String packageName) {
			if (attr.receiver != null) {
				val c = classForConstr(attr.receiver, packageName)
				c.members += attr.toMethod(attr.name, attr.returnType) [
					body = attr.body
				]
			}
		}

		def void inferForElement(AstElement elem, String packageName, IJvmDeclaredTypeAcceptor acceptor, Model model) {
			println("infer for Element " + elem)
			switch elem {
				Constructor: {
					println("	constructor " + elem.name)
					acceptor.accept(classForConstr(elem, packageName)).initializeLater[
						for (e : model.specifications) {
							switch e {
								AttributeDef:
									if (e.receiver == elem) {
										members += e.toMethod(e.name, e.returnType) [
											for (p : e.params) {
												parameters += p.toParameter(p.name, p.parameterType)
											} 
											body = e.body
										]
									}
							}
						}
						
						
					]
				}
				SumType: {
					println("	sumType " + elem.name)
					acceptor.accept(elem.toClass(packageName + "." + elem.name))
					for (child : elem.elements) {
						switch child.constr {
							Constructor: inferForElement(child.constr, packageName, acceptor, model)
						}
					}
				}
				ListType: {
					println("	listType " + elem.name)
					acceptor.accept(elem.toClass(packageName + "." + elem.name))
				}
			}
		}

		def classForConstr(Constructor elem, String packageName) {
			elem.toClass(packageName + "." + elem.name)
		}
	}
	