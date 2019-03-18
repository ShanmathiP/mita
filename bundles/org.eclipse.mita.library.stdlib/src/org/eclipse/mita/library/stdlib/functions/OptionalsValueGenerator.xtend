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

package org.eclipse.mita.library.stdlib.functions

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.mita.base.expressions.ElementReferenceExpression
import org.eclipse.mita.library.stdlib.OptionalGenerator
import org.eclipse.mita.program.generator.AbstractFunctionGenerator
import org.eclipse.mita.program.generator.CodeFragment
import org.eclipse.mita.program.generator.StatementGenerator
import org.eclipse.mita.program.model.ModelUtils

class OptionalsValueGenerator extends AbstractFunctionGenerator {
	
	@Inject 
	protected extension StatementGenerator statementGenerator
	
	override generate(EObject target, CodeFragment resultVariableName, ElementReferenceExpression ref) {
		val args = ref.arguments;
		val optVarOrExpr = args.head.value;
				
		codeFragmentProvider.create('''
			if(«optVarOrExpr.code».«OptionalGenerator.OPTIONAL_FLAG_MEMBER» != «OptionalGenerator.enumOptional.Some.name») {
				«IF ModelUtils.isInTryCatchFinally(ref)»
				exception = EXCEPTION_NOVALUEEXCEPTION;
				break;
				«ELSE»
				return EXCEPTION_NOVALUEEXCEPTION;
				«ENDIF»
			}
			«IF target !== null»«resultVariableName» = «ENDIF»«optVarOrExpr.code».«OptionalGenerator.OPTIONAL_DATA_MEMBER»;
		''').addHeader('MitaGeneratedTypes.h', false);
	}
	
}