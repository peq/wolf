package de.peeeq.wolf;

import java.util.List;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.naming.IQualifiedNameProvider;
import org.eclipse.xtext.naming.QualifiedName;
import org.eclipse.xtext.xbase.scoping.XbaseQualifiedNameProvider;

import com.google.common.collect.Lists;
import com.google.inject.Inject;

import de.peeeq.wolf.wolf.Constructor;
import de.peeeq.wolf.wolf.Model;


public class WolfQualifiedNameProvider extends XbaseQualifiedNameProvider implements IQualifiedNameProvider{

	
	@Override
	public QualifiedName apply(EObject input) {
		return getFullyQualifiedName(input);
	}

	@Override
	public QualifiedName getFullyQualifiedName(EObject obj) {
		if (obj instanceof Constructor) {
			Constructor constructor = (Constructor) obj;
			Model m = getModel(constructor);
			List<String> segments = Lists.newArrayList();
			for (String part : m.getName().split(".")) {
				segments.add(part);
			}
			segments.add(constructor.getName());
			return QualifiedName.create(segments);			
		}
		return super.getFullyQualifiedName(obj);
	}

	private Model getModel(EObject obj) {
		while (obj != null) {
			if (obj instanceof Model) {
				return (Model) obj;
			}
			obj = obj.eContainer();
		}
		return null;
	}
	
}