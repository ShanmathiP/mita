/********************************************************************************
 * Copyright (c) 2017, 2018 Bosch Connected Devices and Solutions GmbH.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * Contributors:
 *    Bosch Connected Devices and Solutions GmbH - initial contribution
 *
 * SPDX-License-Identifier: EPL-2.0
 ********************************************************************************/

/*
 * generated by Xtext 2.10.0
 */
package org.eclipse.mita.program.scoping

import com.google.common.base.Predicate
import com.google.inject.Inject
import java.util.Collections
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EcorePackage
import org.eclipse.mita.base.expressions.Argument
import org.eclipse.mita.base.expressions.ElementReferenceExpression
import org.eclipse.mita.base.expressions.ExpressionsPackage
import org.eclipse.mita.base.expressions.FeatureCall
import org.eclipse.mita.base.expressions.FeatureCallWithoutFeature
import org.eclipse.mita.base.scoping.TypeKindNormalizer
import org.eclipse.mita.base.scoping.TypesGlobalScopeProvider
import org.eclipse.mita.base.types.AnonymousProductType
import org.eclipse.mita.base.types.ComplexType
import org.eclipse.mita.base.types.EnumerationType
import org.eclipse.mita.base.types.Expression
import org.eclipse.mita.base.types.NamedProductType
import org.eclipse.mita.base.types.Operation
import org.eclipse.mita.base.types.PresentTypeSpecifier
import org.eclipse.mita.base.types.StructureType
import org.eclipse.mita.base.types.SumAlternative
import org.eclipse.mita.base.types.SumSubTypeConstructor
import org.eclipse.mita.base.types.SumType
import org.eclipse.mita.base.types.Type
import org.eclipse.mita.base.types.TypesPackage
import org.eclipse.mita.base.typesystem.types.AbstractType
import org.eclipse.mita.base.util.BaseUtils
import org.eclipse.mita.base.types.typesystem.ITypeSystem
import org.eclipse.mita.platform.AbstractSystemResource
import org.eclipse.mita.platform.Platform
import org.eclipse.mita.platform.PlatformPackage
import org.eclipse.mita.platform.Sensor
import org.eclipse.mita.platform.SystemResourceAlias
import org.eclipse.mita.program.ConfigurationItemValue
import org.eclipse.mita.program.IsDeconstructionCase
import org.eclipse.mita.program.IsDeconstructor
import org.eclipse.mita.program.Program
import org.eclipse.mita.program.ProgramPackage
import org.eclipse.mita.program.SignalInstance
import org.eclipse.mita.program.SystemEventSource
import org.eclipse.mita.program.SystemResourceSetup
import org.eclipse.mita.program.VariableDeclaration
import org.eclipse.mita.program.impl.VariableDeclarationImpl
import org.eclipse.mita.program.model.ModelUtils
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.naming.IQualifiedNameConverter
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes
import org.eclipse.xtext.scoping.impl.FilteringScope
import org.eclipse.xtext.scoping.impl.ImportNormalizer
import org.eclipse.xtext.scoping.impl.ImportScope
import org.eclipse.xtext.util.OnChangeEvictingCache
import static extension org.eclipse.mita.base.util.BaseUtils.force
import org.eclipse.mita.platform.SystemSpecification
import org.eclipse.mita.program.NewInstanceExpression

class ProgramDslScopeProvider extends AbstractProgramDslScopeProvider {

	@Inject
	IQualifiedNameConverter fqnConverter

	@Inject
	IQualifiedNameProvider qualifiedNameProvider

	override scope_Argument_parameter(Argument argument, EReference ref) {
		if (EcoreUtil2.getContainerOfType(argument, SystemResourceSetup) !== null) {
			return scopeInSetupBlock(argument, ref);
		} else {
			val ec = argument.eContainer;
			if (ec instanceof ElementReferenceExpression) {
				return scope_Argument_parameter(ec as ElementReferenceExpression, ref)
			} 
		}
		return IScope.NULLSCOPE;
	}

	override scope_Argument_parameter(ElementReferenceExpression exp, EReference ref) {
		if (EcoreUtil2.getContainerOfType(exp, SystemResourceSetup) !== null) {
			scopeInSetupBlock(exp, ref);
		} else {
			val txt = if(exp instanceof NewInstanceExpression) {
				val reference = ProgramPackage.Literals.NEW_INSTANCE_EXPRESSION__TYPE;
				BaseUtils.getText(exp, reference)
			} else {
				val reference = ExpressionsPackage.Literals.ELEMENT_REFERENCE_EXPRESSION__REFERENCE;
				BaseUtils.getText(exp, reference)	
			}
			if (txt.nullOrEmpty) {
				return super.scope_Argument_parameter(exp, ref);
			} else {
				return exp.getCandidateParameterScope(ref);
			}
		}
	}

	static class CombiningScope implements IScope {
		var Iterable<IScope> scopes;

		new(IScope s1, IScope s2) {
			scopes = #[s1, s2];
			if (s1 === null || s2 === null) {
				throw new NullPointerException;
			}
		}

		new(Iterable<IScope> scopes) {
			this.scopes = scopes.filterNull;
		}

		override getAllElements() {
			return scopes.flatMap[it.allElements];
		}

		override getElements(QualifiedName name) {
			return scopes.flatMap[it.getElements(name)];
		}

		override getElements(EObject object) {
			return scopes.flatMap[it.getElements(object)];
		}

		override getSingleElement(QualifiedName name) {
			// try s1 first, then s2
			val els = getElements(name);
			if (els.empty) {
				return null;
			}
			return els.head;
		}

		override getSingleElement(EObject object) {
			// try s1 first, then s2
			val els = getElements(object);
			if (els.empty) {
				return null;
			}
			return els.head;
		}

	}

	def protected IScope getCandidateParameterScope(EObject context) {
		val ref = ExpressionsPackage.Literals.ELEMENT_REFERENCE_EXPRESSION__REFERENCE;
		return getCandidateParameterScope(context, ref);
	}
	
	def protected IScope getCandidateParameterScope(EObject context, EReference ref) {
		return getCandidateParameterScope(context, getAllImportQualifiers(context), delegate.getScope(context, ref), ref);
	}
	
	def protected IScope getCandidateParameterScope(IScope globalScope, SumType superType, SumAlternative subType, String constructor) {
		return doGetCandidateParameterScope(subType, createConstructorScope(globalScope, superType, constructor));
	}
	
	def protected dispatch doGetCandidateParameterScope(SumAlternative type, IScope constructorScope) {
		// fall-back
		return IScope.NULLSCOPE;
	}
	
	def protected dispatch doGetCandidateParameterScope(NamedProductType subType, IScope constructorScope) {
		if (!subType.eIsProxy) {
			return Scopes.scopeFor(subType.parameters);
		} else {
			return constructorScope;
		}
	}
	
	def protected dispatch doGetCandidateParameterScope(AnonymousProductType subType, IScope constructorScope) {
		if (!subType.eIsProxy) {
			if (subType.typeSpecifiers.length == 1) {
				val maybeSType = subType.typeSpecifiers.head;
				if (!maybeSType.eIsProxy && maybeSType.type instanceof StructureType) {
					val sType = maybeSType.type as StructureType;
					return Scopes.scopeFor(sType.parameters);
				}
			}
		} 
		return constructorScope;
		
	}
	
	def protected dispatch IScope doGetCandidateParameterScope(SumSubTypeConstructor subType, IScope constructorScope) {
		return subType.eContainer.doGetCandidateParameterScope(constructorScope);
		
	}
	
	def protected createConstructorScope(IScope globalScope, Type type, String constructor) {
		val name = type.name + "." + constructor
		val qName = fqnConverter.toQualifiedName(name)
		return new ImportScope(#[new ImportNormalizer(qName, true, false)], globalScope, null,
			ExpressionsPackage.Literals.ELEMENT_REFERENCE_EXPRESSION__REFERENCE.EReferenceType, false) as IScope;
	}
	
	dispatch def protected QualifiedName getImportQualifier(ElementReferenceExpression obj) {
		val baseQN = obj.arguments.head?.value.getImportQualifier;
		val txt = BaseUtils.getText(obj, ExpressionsPackage.eINSTANCE.elementReferenceExpression_Reference);
		return baseQN.append(txt);
	}
	dispatch def protected QualifiedName getImportQualifier(NewInstanceExpression obj) {
		val typeName = BaseUtils.getText(obj, ProgramPackage.eINSTANCE.newInstanceExpression_Type);
		return QualifiedName.create(typeName, "con_" + typeName);
	}
	dispatch def protected QualifiedName getImportQualifier(EObject obj) {
		return QualifiedName.EMPTY;
	}
	dispatch def protected QualifiedName getImportQualifier(Void obj) {
		return QualifiedName.EMPTY;
	}
	
	def Iterable<QualifiedName> getAllImportQualifiers(EObject obj) {
		var qn = obj.getImportQualifier;
		val result = newArrayList;
		while(!qn.empty) {
			result.add(qn);
			qn = qn.skipFirst(1);
		}
		return result;
	}
	
	def protected IScope getCandidateParameterScope(EObject context, Iterable<QualifiedName> importNormalizerQNs, IScope globalScope, EReference ref) {
		// import by name, for named parameters of structs and functions
		val scopeDequalified = new ImportScope(
			importNormalizerQNs.map[new ImportNormalizer(it, true, false)].force,
			globalScope,
			null,
			ref.EReferenceType,
			false
		);
		return scopeDequalified
	}

	def IScope scope_VariableDeclarationImpl_feature(VariableDeclarationImpl context, EReference reference) {
		val typeSpecifier = context.getTypeSpecifier();
		val type = if(typeSpecifier instanceof PresentTypeSpecifier) {
			typeSpecifier.type;
		}
		if(!(type instanceof ComplexType)) return IScope.NULLSCOPE;

		return Scopes.scopeFor((type as ComplexType).allFeatures)
	}

	def IScope scope_FeatureValue_feature(VariableDeclaration context, EReference reference) {
		val typeSpecifier = context.getTypeSpecifier();
		val type = if(typeSpecifier instanceof PresentTypeSpecifier) {
			typeSpecifier.type;
		}
		if(!(type instanceof ComplexType)) return IScope.NULLSCOPE;

		return Scopes.scopeFor((type as ComplexType).allFeatures)
	}

	protected final OnChangeEvictingCache scope_FeatureCall_feature_cache = new OnChangeEvictingCache();

	protected def getExtensionMethodScope(Expression context, EReference reference, AbstractType type) {
		return new FilteringScope(delegate.getScope(context, reference), [ x |
			(x.EClass == ProgramPackage.Literals.FUNCTION_DEFINITION ||
				x.EClass == ProgramPackage.Literals.GENERATED_FUNCTION_DEFINITION) && x.isApplicableOn(type)
		]);
	}

	protected def isApplicableOn(IEObjectDescription operationDesc, AbstractType contextType) {
		var params = operationDesc.getUserData(ProgramDslResourceDescriptionStrategy.OPERATION_PARAM_TYPES);
		val paramArray = if (params === null) {
				if (operationDesc.EObjectOrProxy instanceof Operation) {
					/* Workaround for when we did not get a proper object description, i.e. the object description was not produced
					 * by a ProgramDslResourceDescriptionStrategy. In that case, if the description object is already resolved, we'll
					 * compute the parameter types ourselves.
					 */
					ProgramDslResourceDescriptionStrategy.getOperationParameterTypes(
						operationDesc.EObjectOrProxy as Operation);
				} else {
					#[] as String[]
				}
			} else {
				params.toArray
			}

		if (paramArray.size == 0) {
			return false
		}
		val paramTypeName = paramArray.get(0)
		return contextType.isSubtypeOf(paramTypeName)
	}

	protected def isSubtypeOf(AbstractType subType, String superTypeName) {
		return subType.name == superTypeName;
//		if (subType.name == superTypeName) {
//			return true
//		}
//		return typeSystem.getSuperTypes(subType).exists[name == superTypeName]
	}

	protected def toArray(String paramArrayAsString) {
		paramArrayAsString.replace("[", "").replace("]", "").split(", ")
	}

	dispatch protected def addFeatureScope(SumType owner, IScope scope) {
		Scopes.scopeFor(owner.alternatives, scope);
	}

	dispatch protected def addFeatureScope(StructureType owner, IScope scope) {
		Scopes.scopeFor(owner.parameters, scope);
	}

	dispatch protected def addFeatureScope(ComplexType owner, IScope scope) {
		Scopes.scopeFor(owner.getAllFeatures(), scope);
	}

	dispatch protected def addFeatureScope(EnumerationType owner, IScope scope) {
		Scopes.scopeFor(owner.getEnumerator(), scope);
	}

	dispatch protected def addFeatureScope(SystemResourceSetup owner, IScope scope) {
		Scopes.scopeFor(owner.signalInstances, scope)
	}

	dispatch protected def addFeatureScope(Sensor owner, IScope scope) {
		Scopes.scopeFor(owner.modalities, scope);
	}
	dispatch protected def addFeatureScope(Platform owner, IScope scope) {
		Scopes.scopeFor(owner.modalities, scope);
	}

	dispatch protected def IScope addFeatureScope(SystemResourceAlias owner, IScope scope) {
		return if(owner.delegate === null) scope else addFeatureScope(owner.delegate, scope)
	}

	dispatch protected def addFeatureScope(Object owner, IScope scope) {
		// fall-back
		scope
	}
	dispatch protected def addFeatureScope(Void owner, IScope scope) {
		// fall-back
		scope
	}

	def IScope scope_ConfigurationItemValue_item(SystemResourceSetup context, EReference reference) {
		val items = context.type?.configurationItems
		if(items === null) {
			return IScope.NULLSCOPE;
		}
		return Scopes.scopeFor(items);
	}

	def IScope scope_SystemResourceSetup_type(SystemResourceSetup context, EReference reference) {
		val result = getDelegate().getScope(context, reference);

		/*
		 * filter the result scope for system resources which need to be set up (i.e. have configuration items
		 * or variable configuration items).
		 */
		val configurableResourceTypes = #[
			PlatformPackage.Literals.BUS,
			PlatformPackage.Literals.CONNECTIVITY,
			PlatformPackage.Literals.INPUT_OUTPUT,
			PlatformPackage.Literals.SENSOR,
			PlatformPackage.Literals.PLATFORM
		]
		return new FilteringScope(result, [ x |
			val xobj = x.EObjectOrProxy;
			if (xobj instanceof SystemResourceAlias) {
				configurableResourceTypes.contains(xobj.delegate?.eClass)
			} else {
				configurableResourceTypes.contains(x.EClass)
			}
		]);
	}

	public static val Predicate<EClass> globalElementFilter = [ x |
		val inclusion = (ProgramPackage.Literals.SYSTEM_RESOURCE_SETUP.isSuperTypeOf(x)) ||
			(PlatformPackage.Literals.ABSTRACT_SYSTEM_RESOURCE.isSuperTypeOf(x)) ||
			(PlatformPackage.Literals.MODALITY.isSuperTypeOf(x)) ||
			(TypesPackage.Literals.PARAMETER.isSuperTypeOf(x)) ||
			(TypesPackage.Literals.OPERATION.isSuperTypeOf(x)) ||
			(TypesPackage.Literals.ENUMERATION_TYPE.isSuperTypeOf(x)) ||
			(TypesPackage.Literals.TYPE_KIND.isSuperTypeOf(x)) ||
			(ProgramPackage.Literals.SIGNAL_INSTANCE.isSuperTypeOf(x)) ||
			(TypesPackage.Literals.VIRTUAL_FUNCTION.isSuperTypeOf(x));

		val exclusion = 
			(PlatformPackage.Literals.SIGNAL.isSuperTypeOf(x)) ||
			(TypesPackage.Literals.NAMED_PRODUCT_TYPE.isSuperTypeOf(x))  ||
			(TypesPackage.Literals.ANONYMOUS_PRODUCT_TYPE.isSuperTypeOf(x)) ||
			(TypesPackage.Literals.SUM_TYPE.isSuperTypeOf(x)) ||
			(TypesPackage.Literals.SINGLETON.isSuperTypeOf(x)) ||
			(TypesPackage.Literals.STRUCTURE_TYPE.isSuperTypeOf(x)) ||
			(PlatformPackage.Literals.SIGNAL_PARAMETER.isSuperTypeOf(x)) 

		inclusion && !exclusion;
	]
	
	public static val Predicate<EClass> globalElementFilterInSetup = [ x |
		val inclusion = (ProgramPackage.Literals.SYSTEM_RESOURCE_SETUP.isSuperTypeOf(x)) ||
			(PlatformPackage.Literals.MODALITY.isSuperTypeOf(x)) ||
			(TypesPackage.Literals.PARAMETER.isSuperTypeOf(x)) ||
			(TypesPackage.Literals.OPERATION.isSuperTypeOf(x)) ||
			(TypesPackage.Literals.ENUMERATION_TYPE.isSuperTypeOf(x)) ||
			(TypesPackage.Literals.TYPE_KIND.isSuperTypeOf(x)) ||
			(ProgramPackage.Literals.SIGNAL_INSTANCE.isSuperTypeOf(x)) ||
			(TypesPackage.Literals.VIRTUAL_FUNCTION.isSuperTypeOf(x));

		val exclusion = 
			(TypesPackage.Literals.NAMED_PRODUCT_TYPE.isSuperTypeOf(x))  ||
			(TypesPackage.Literals.ANONYMOUS_PRODUCT_TYPE.isSuperTypeOf(x)) ||
			(TypesPackage.Literals.SUM_TYPE.isSuperTypeOf(x)) ||
			(TypesPackage.Literals.SINGLETON.isSuperTypeOf(x)) ||
			(TypesPackage.Literals.STRUCTURE_TYPE.isSuperTypeOf(x)) ||
			(PlatformPackage.Literals.SIGNAL_PARAMETER.isSuperTypeOf(x)) 

		inclusion && !exclusion;
	]

	public static val Predicate<EClass> globalTypeFilter = [ x |
		val inclusion = TypesPackage.Literals.TYPE.isSuperTypeOf(x);

		val exclusion = 
			PlatformPackage.Literals.SENSOR.isSuperTypeOf(x) ||
			PlatformPackage.Literals.CONNECTIVITY.isSuperTypeOf(x) ||
			PlatformPackage.Literals.ABSTRACT_SYSTEM_RESOURCE.isSuperTypeOf(x) ||
			TypesPackage.Literals.EXCEPTION_TYPE_DECLARATION.isSuperTypeOf(x) ||
			TypesPackage.Literals.TYPE_KIND.isSuperTypeOf(x) ||
			TypesPackage.Literals.TYPE_PARAMETER.isSuperTypeOf(x); // exclude global type parameters, local ones are added in TypeReferenceScope
		inclusion && !exclusion;
	]

	def scope_TypeSpecifier_type(EObject context, EReference ref) {
		val parentScope = delegate.getScope(context, ref)
		return new TypeReferenceScope(new FilteringScope(parentScope, [globalTypeFilter.apply(it.EClass)]), context);
	}
	def scope_PresentTypeSpecifier_type(EObject context, EReference ref) {
		return scope_TypeSpecifier_type(context, ref);
	}

	def scope_ElementReferenceExpression_reference(EObject context, EReference ref) {
		val setup = EcoreUtil2.getContainerOfType(context, SystemResourceSetup)
		if (setup !== null) {
			// we're in a setup block which has different scoping rules. Let's use those
			val scope = scopeInSetupBlock(context, ref);
			return new FilteringScope(scope, [globalElementFilterInSetup.apply(it.EClass)]);
		} else {
			val superScope = new FilteringScope(delegate.getScope(context, ref), [globalElementFilter.apply(it.EClass)]);
			val scope = (
			if(context instanceof FeatureCallWithoutFeature) {
				val normalizer = new ImportNormalizer(QualifiedName.create("<auto>"), true, false);
				new ImportScope(#[normalizer], superScope, null, null, false);
			} else if(context instanceof ElementReferenceExpression) {
				if(context.isOperationCall && context.arguments.size > 0) {
					val owner = context.arguments.head.value;
					
					val ownerText = BaseUtils.getText(owner, ref) ?: "";
					val normalizer = new ImportNormalizer(QualifiedName.create(ownerText), true, false);
					new ImportScope(#[normalizer], superScope, null, null, false);
					
				}
			}) ?: superScope;
			val typeKindNormalizer = new TypeKindNormalizer();
			return new ImportScope(#[typeKindNormalizer], new ElementReferenceScope(scope, context), null, null, false);
		}
	}

	dispatch def IScope scopeInSetupBlock(SignalInstance context, EReference reference) {
		if (reference == ExpressionsPackage.Literals.ELEMENT_REFERENCE_EXPRESSION__REFERENCE) {
			val systemResource = (context.eContainer as SystemResourceSetup).type
			if(systemResource !== null) {
				val result = Scopes.scopeFor(systemResource.signals)
				return result;
			}
		} else if (reference == ExpressionsPackage.Literals.ARGUMENT__PARAMETER) {
			val globalScope = getDelegate().getScope(context, ExpressionsPackage.Literals.ELEMENT_REFERENCE_EXPRESSION__REFERENCE);
			val enumTypes = context.instanceOf.parameters.map[BaseUtils.getType(it)?.origin].filter(EnumerationType)
			val enumeratorScope = filteredEnumeratorScope(globalScope, enumTypes)
			val paramScope = Scopes.scopeFor(context.instanceOf.parameters)
			val scope = new CombiningScope(paramScope, enumeratorScope)
			return scope
		} 
		return IScope.NULLSCOPE;
	}

	dispatch def IScope scopeInSetupBlock(ConfigurationItemValue context, EReference reference) {
		// configuration item values and unqualified enumerator values
		val originalScope = getDelegate().getScope(context, reference);
		if(context.item === null) {
			return originalScope;
		}
		return originalScope;
		
	}
	
	def filteredSumTypeScope(IScope originalScope, SumType itemType) {
		val itemTypeName = qualifiedNameProvider.getFullyQualifiedName(itemType);
		val normalizer = new ImportNormalizer(itemTypeName, true, false);
		val delegate = new ImportScope(Collections.singletonList(normalizer), originalScope, null,
			TypesPackage.Literals.COMPLEX_TYPE, false);
		return new FilteringScope(delegate, [
			(
				   TypesPackage.Literals.ANONYMOUS_PRODUCT_TYPE.isSuperTypeOf(it.EClass) 
				|| TypesPackage.Literals.NAMED_PRODUCT_TYPE.isSuperTypeOf(it.EClass) 
				|| TypesPackage.Literals.SINGLETON.isSuperTypeOf(it.EClass) 
			) && it.name.segmentCount == 1
		])	
	}

	def filteredEnumeratorScope(IScope originalScope, EnumerationType itemType) {
		return filteredEnumeratorScope(originalScope, Collections.singletonList(itemType));
	}
	
	def filteredEnumeratorScope(IScope originalScope, Iterable<EnumerationType> itemTypes) {
		val normalizers = itemTypes.map[new ImportNormalizer(qualifiedNameProvider.getFullyQualifiedName(it), true, false)].toList
		val delegate = new ImportScope(normalizers, originalScope, null, TypesPackage.Literals.ENUMERATOR, false);
		return new FilteringScope(delegate, [
			TypesPackage.Literals.ENUMERATOR.isSuperTypeOf(it.EClass) && it.name.segmentCount == 1
		]);
	}

	dispatch def IScope scopeInSetupBlock(Argument context, EReference reference) {
		val originalScope = getDelegate().getScope(context, reference);

		if (reference == ExpressionsPackage.Literals.ELEMENT_REFERENCE_EXPRESSION__REFERENCE) {
			if (context.parameter !== null) {
				val itemType = BaseUtils.getType(context.parameter);
				if (itemType instanceof EnumerationType) {
					// unqualified resolving of enumeration values
					return filteredEnumeratorScope(originalScope, itemType);
				}
				else {
					val typeName = BaseUtils.getText(context.parameter.typeSpecifier, TypesPackage.eINSTANCE.presentTypeSpecifier_Type);
					val normalizer = new ImportNormalizer(QualifiedName.create(typeName), true, false);
					return new ImportScope(#[normalizer], originalScope, null, EcorePackage.eINSTANCE.EObject, false);
				}
			} else {
				val signal = (context.eContainer() as ElementReferenceExpression).reference
				if (signal instanceof Operation) {
					// unqualified resolving of enumeration values
					val enumTypes = signal.parameters.map[BaseUtils.getType(it)?.origin].filter(EnumerationType)
					return filteredEnumeratorScope(originalScope, enumTypes)
				}
				else {
					return originalScope;
				}
			}
		} else if (reference == ExpressionsPackage.Literals.ARGUMENT__PARAMETER) {
			// unqualified resolving of parameter names
			val container = EcoreUtil2.getContainerOfType(context.eContainer, ElementReferenceExpression);
			if(container.reference === null) {
				val erefTxt = BaseUtils.getText(container, ExpressionsPackage.eINSTANCE.elementReferenceExpression_Reference);
				val systemResourceSetup = EcoreUtil2.getContainerOfType(container.eContainer, SystemResourceSetup);
				val systemResourceTxt = BaseUtils.getText(systemResourceSetup, ProgramPackage.eINSTANCE.systemResourceSetup_Type);
				val normalizers = newArrayList(QualifiedName.create(erefTxt), QualifiedName.create(systemResourceTxt, erefTxt));
				val mbSumTypeConstructor = if(container instanceof FeatureCallWithoutFeature) {
					"<auto>"
				} else {
					if(container.arguments.size > 0) {
						val firstArg = container.arguments.head;
						if(firstArg !== context) {
							val value = firstArg.value;
							if(value instanceof ElementReferenceExpression) {
								BaseUtils.getText(value, ExpressionsPackage.eINSTANCE.elementReferenceExpression_Reference);
							}
						}
					}
				}
				if(!mbSumTypeConstructor.nullOrEmpty) {
					normalizers.add(QualifiedName.create(mbSumTypeConstructor, erefTxt))
				}
				return new ImportScope(normalizers.map[new ImportNormalizer(it, true, false)], originalScope, null, TypesPackage.eINSTANCE.parameter, false);
			}
			return ModelUtils.getAccessorParameters(container.reference)
				.transform[parameters | Scopes.scopeFor(parameters)]
				.or(originalScope)		
		}
		return originalScope;
	}

	dispatch def IScope scopeInSetupBlock(ElementReferenceExpression context, EReference reference) {
		
		// Erefs should only be constructors or refs in arguments.
		val ref = context.eGet(ExpressionsPackage.Literals.ELEMENT_REFERENCE_EXPRESSION__REFERENCE, false) as EObject;
		if(ref === null || ref.eIsProxy){
			val container = context.eContainer;
			if (container !== null && container != context) {
				if(container instanceof ConfigurationItemValue) {
					val confItem = container.item;
					val typ = confItem?.type;
					if(typ instanceof SumType) {
						return Scopes.scopeFor(typ.alternatives.map[it.constructor]);
					} else if(typ instanceof StructureType) {
						return Scopes.scopeFor(#[typ]);
					}
				}
				else if(container instanceof Argument) {
					// context is a named parameter
					val constr = EcoreUtil2.getContainerOfType(container, ElementReferenceExpression);
					val typ = constr.reference;
					val parms = ModelUtils.getAccessorParameters(typ);
					if(parms.present) {
						// you can reference both argument parameters and things you can otherwise reference here
						return new CombiningScope(Scopes.scopeFor(parms.get), scopeInSetupBlock(container, reference));
					}
				}
				return scopeInSetupBlock(container, reference);
			} else {
				return IScope.NULLSCOPE;
			}
		}
		else {
			if(ref instanceof SumSubTypeConstructor) {
				if(reference == ExpressionsPackage.Literals.ARGUMENT__PARAMETER) {
					return doGetCandidateParameterScope(ref, IScope.NULLSCOPE);
				}
				return Scopes.scopeFor(#[ref]);
			}
			val container = context.eContainer;
			if (container !== null && container != context) {
				return scopeInSetupBlock(container, reference);
			} else {
				return IScope.NULLSCOPE;
			}
		}
	}

	dispatch def IScope scopeInSetupBlock(EObject context, EReference reference) {
		// we don't have a special in-setup block rule for this case. Let's see if we can get a scope for the container.
		val container = context.eContainer;
		if (container !== null && container != context) {
			return scopeInSetupBlock(container, reference);
		} else {
			return IScope.NULLSCOPE;
		}
	}

	def IScope scope_SystemEventSource_origin(Program context, EReference reference) {
		val originalScope = getDelegate().getScope(context, reference);

		return new FilteringScope(originalScope, [ x |
			val obj = x.EObjectOrProxy;
			if (obj instanceof AbstractSystemResource) {
				if (!obj.events.isNullOrEmpty && obj.eContainer instanceof SystemSpecification) {
					val sysSpec = (obj.eContainer as SystemSpecification).name
					return context.imports.exists[it.importedNamespace.equals(sysSpec)]
				}
			}
			return false;
		])
	}

	def IScope scope_SystemEventSource_source(SystemEventSource context, EReference reference) {
		return if (context === null || context.origin === null || context.origin.events.nullOrEmpty) {
			IScope.NULLSCOPE;
		} else {
			Scopes.scopeFor(context.origin.events);
		}
	}

	def IScope scope_IsDeconstructor_productMember(IsDeconstructor context, EReference reference) {
		val originalScope = getDelegate().getScope(context, reference);
		val deconstructorCase = context.eContainer as IsDeconstructionCase;
		val productType = deconstructorCase.productType;
		// structs can be here, they are anonymous (vec2d: v2d), and singular
		return ModelUtils.getAccessorParameters(productType)
			.transform[parameters | Scopes.scopeFor(parameters, [x|QualifiedName.create(productType.name, x.name)], originalScope)]
			.or(originalScope)
	}

	val cache = new OnChangeEvictingCache();

	override IScope getScope(EObject context, EReference reference) {
		// Performance improvement: hard-code well traveled routes
		
		val scope = //cache.get(context -> reference, context.eResource, [
			if (reference == TypesPackage.Literals.PRESENT_TYPE_SPECIFIER__TYPE) {
				scope_TypeSpecifier_type(context, reference);
			} else if (reference == ExpressionsPackage.Literals.ELEMENT_REFERENCE_EXPRESSION__REFERENCE) {
				val scope = scope_ElementReferenceExpression_reference(context, reference);
				//val normalizers = #[new ImportNormalizer(QualifiedName.create("_kinds"), true, false)];
				//return new ImportScope(normalizers, scope, null, EcorePackage.eINSTANCE.EObject, false);
				scope;
			} else if (reference == ProgramPackage.Literals.CONFIGURATION_ITEM_VALUE__ITEM &&
				context instanceof SystemResourceSetup) {
				scope_ConfigurationItemValue_item(context as SystemResourceSetup, reference);
			} else {
//				val methodName = "scope_" + reference.getEContainingClass().getName() + "_" + reference.getName();
//				println(methodName + ' -> ' + context.eClass.name);
				super.getScope(context, reference);
			}
//		]);
		return TypesGlobalScopeProvider.filterExportable(context.eResource, reference, scope);
	}

}
