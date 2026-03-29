package macros;

#if macro
import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.ds.Map;
import sys.io.File;
import sys.FileSystem;

using StringTools;
using haxe.macro.TypeTools;

class CPPIAClassesMacro
{
	/**
	 * An array of metas that will define a type to be excluded.
	 */
	static final SKIP_META = [":noCPPIA"];

	/**
	 * An array of metas that should be stripped when stubbing the type.
	 * Most of these are excluded because they either don't work on CPPIA
	 * Or they're pre-proccessed by the compiler before we got them stubbed.
	 */
	static final META_STRIP = [
		":native",
		":include",
		":cppInclude",
		":buildXml",
		":sourceFile",
		":cppFileCode",
		":cppNamespaceCode",
		":headerCode",
		":headerClassCode",
		":functionCode",
		":fileXml",
		":noDebug",
		":bitmap",
		":file"
	];

	/**
	 * An Array of :build/:autoBuild macros to KILL off when creating the stubs.
	 */
	static final BUILD_MACROS_STRIP = [
		"hscript.",
		"sscript.",
		"openfl.utils._internal.AssetsMacro",
		"lime._internal.macros.AssetsMacro",
		"openfl.utils._internal.ShaderMacro"
	];

	/**
	 * An array of classpaths to exclude from the stubs.
	 */
	static final LIBS_SKIP = ['sscript', 'hscript', 'hxluajit'];

	static var outputDir:String;

	static var copiedModules = new Map<String, Bool>();

	/**
	 * A macro that goes through every compiled file in all the defined classpaths and generates stubs of them in `stubOutputDir`.
	 * The stubs only contain descriptions, variables definition and functions definition (with empty bodies) to reduce their size.
	 * If a type is declared with any of the metadatas in `SKIP_META` array it will not get stubbed.
	 * Any type/field with a meta from `META_STRIP` will have it removed.
	 * Any type/field with a :build/:autoBuild macro from `BUILD_MACROS_STRIP` will have it removed.
	 *  
	 * @param stubOutputDir The output folder of the stubs.
	 * @param filesToCopy 	File to copy directly from their source as-is without stubbing them.
	 */
	public static function generate(stubOutputDir:String = "cppia/stubs/src", ?filesToCopy:Array<String>)
	{
		outputDir = stubOutputDir;
		var classPaths = getClassPaths();

		// Copy specified source files verbatim before stub generation
		if (filesToCopy != null)
		{
			for (path in filesToCopy)
				copySourceFile(path, classPaths);
		}

		Context.onAfterTyping(function(modules)
		{
			var validTypes = (modules : Array<ModuleType>).filter(t -> isInClassPaths(t, classPaths));

			var byModule = new Map<String, Array<ModuleType>>();
			for (t in validTypes)
			{
				var mod = getModule(t);
				if (!byModule.exists(mod))
					byModule.set(mod, []);
				byModule.get(mod).push(t);
			}

			var moduleList = [for (mod => types in byModule) {mod: mod, types: types}];
			var total = moduleList.length;

			for (i => entry in moduleList)
			{
			    processModule(entry.mod, entry.types);
			    Sys.print('\rGenerating CPPIA stubs... ${i + 1}/$total modules');
			}

			Sys.println('\rFinished generating CPPIA stubs! ($total modules)');
		});
	}

	/**
	 * Copies a source file verbatim into the stub output directory.
	 * Used for files that contain macros or macro-generated runtime classes
	 * that cannot be reconstructed from the typed AST (e.g. FlxSignal, ShaderMacro).
	 * Any types in the copied file are registered in `copiedModules` so the
	 * stub generator skips them and doesn't overwrite the verbatim copy.
	 * 
	 * @param sourcePath The classpath-relative or absolute path to the source file.
	 * @param classPaths The resolved classpaths to search when the path is relative.
	 */
	static function copySourceFile(sourcePath:String, classPaths:Array<String>)
	{
		var resolvedPath:Null<String> = null;

		if (FileSystem.exists(sourcePath))
			resolvedPath = sourcePath;
		else
		{
			for (cp in classPaths)
			{
				var full = Path.join([cp, sourcePath]);
				if (FileSystem.exists(full))
				{
					resolvedPath = full;
					break;
				}
			}
		}

		if (resolvedPath == null)
		{
			Context.warning('CPPIAClassesMacro: could not find $sourcePath in any classpath', Context.currentPos());
			return;
		}

		var content = File.getContent(resolvedPath);

		var pack:Array<String> = [];
		for (line in content.split("\n"))
		{
			var trimmed = line.trim();
			if (trimmed.startsWith("package "))
			{
				var packStr = trimmed.substr("package ".length).replace(";", "").trim();
				if (packStr.length > 0)
					pack = packStr.split(".");
				break;
			}
			if (trimmed.length > 0 && !trimmed.startsWith("//") && !trimmed.startsWith("/*"))
				break;
		}

		var name = Path.withoutExtension(Path.withoutDirectory(resolvedPath));
		writeFile(pack, name, content);

		var packStr = pack.join(".");
		for (line in content.split("\n"))
		{
			var trimmed = line.trim();
			for (keyword in ["class ", "interface ", "abstract ", "enum ", "typedef "])
			{
				if (trimmed.startsWith(keyword) || trimmed.startsWith("private " + keyword) || trimmed.startsWith("extern " + keyword))
				{
					var rest = trimmed.substr(trimmed.indexOf(keyword) + keyword.length);
					var typeName = ~/^([A-Za-z_][A-Za-z0-9_]*)/.map(rest, r -> r.matched(0));
					var fullModule = packStr.length > 0 ? '$packStr.$typeName' : typeName;
					copiedModules.set(packStr.length > 0 ? '$packStr.$name' : name, true);
					break;
				}
			}
		}
	}

	/**
 	 * Groups all types that belong to the same source file and writes them together.
 	 * In Haxe, multiple types can live in one file (sharing a module). The primary type
 	 * (whose name matches the last segment of the module path) is emitted first,
 	 * and secondary types follow with their redundant package declarations stripped.
 	 * The output path is derived from the module string, not the type's pack field,
 	 * so that private types in underscore subpackages (e.g. `openfl._Vector`) still
 	 * land in the correct file alongside their public counterparts.
	 * 
 	 * @param module The dot-separated module path (e.g. `flixel.util.FlxColor`).
 	 * @param types  All ModuleTypes that belong to this module.
 	 */
	static function processModule(module:String, types:Array<ModuleType>)
	{
		var mainName = module.split(".").pop();
		var modulePack = module.split(".");
		modulePack.pop();

		types.sort((a, b) -> (getTypeName(a) == mainName ? 0 : 1) - (getTypeName(b) == mainName ? 0 : 1));

		var buf = new StringBuf();
		var wrotePackage = false;

		for (t in types)
		{
			var src = generateType(t);
			if (src == null)
				continue;

			if (!wrotePackage)
			{
				buf.add(src);
				wrotePackage = true;
			}
			else
			{
				var lines = src.split("\n");
				var start = 0;
				if (lines[0].startsWith("package "))
				{
					start = 1;
					if (start < lines.length && lines[start].trim() == "")
						start++;
				}
				buf.add("\n" + lines.slice(start).join("\n"));
			}
		}

		var content = buf.toString();
		if (content.trim().length == 0)
			return;

		writeFile(modulePack, mainName, content);
	}

	/**
	 * Dispatches a ModuleType to the appropriate generator.
	 * Also applies all skip conditions — metadata-based exclusion, hscript impl classes,
	 * and modules that were already copied verbatim.
	 * 
	 * @param t The ModuleType to generate.
	 * @return  The generated Haxe source string, or null if the type should be skipped.
	 */
	static function generateType(t:ModuleType):Null<String>
	{
		if (copiedModules.exists(getModule(t)))
			return null;

		return switch (t)
		{
			case TClassDecl(_.get() => cl):
				if (shouldSkip(cl.meta.get())) null; else if (cl.meta.has(":impl")) null; else if (cl.name.endsWith("_HSC")) null; else
					if (isModulePrivate(cl.pack, cl.name)) null; else generateClass(cl);

			case TEnumDecl(_.get() => en):
				if (shouldSkip(en.meta.get())) null; else if (isModulePrivate(en.pack, en.name)) null; else generateEnum(en);

			case TTypeDecl(_.get() => td):
				if (shouldSkip(td.meta.get())) null; else if (isModulePrivate(td.pack, td.name)) null; else generateTypedef(td);

			case TAbstract(_.get() => ab):
				if (shouldSkip(ab.meta.get())) null; else if (isModulePrivate(ab.pack, ab.name)) null; else generateAbstract(ab);
		};
	}

	/**
	 * Generates a stub for a class or interface.
	 * Emits the class declaration with type parameters (including constraints),
	 * superclass, interfaces, doc comment, metadata, constructor, instance fields,
	 * and static fields. Private classes get the `private` keyword. Extern classes
	 * have their extern-specific metadata stripped. Interface method bodies are
	 * replaced with semicolons. All method bodies are stubbed with a type-appropriate
	 * default return value.
	 * 
	 * @param cl The ClassType to generate.
	 * @return   The generated Haxe source string.
	 */
	static function generateClass(cl:ClassType):String
	{
		var buf = new StringBuf();

		var overrideSet = new Map<String, Bool>();
		for (f in cl.overrides)
			overrideSet.set(f.get().name, true);

		var pack = modulePackage(cl.module);

		if (pack.length > 0)
			buf.add('package ${pack.join(".")};\n\n');

		if (cl.doc != null && cl.doc.trim().length > 0)
			buf.add('/** ${cl.doc.trim()} **/\n');

		writeMetas(buf, cl.meta.get());

		var privacy = cl.isPrivate ? "private " : "";
		var keyword = cl.isInterface ? "interface" : "class";
		var decl = '$privacy$keyword ${cl.name}';

		if (cl.params.length > 0)
		{
			var params = cl.params.map(p -> switch (p.t)
			{
				case TInst(_.get() => c, _):
					switch (c.kind)
					{
						case KTypeParameter(constraints):
							switch (constraints.length)
							{
								case 0: p.name;
								case 1: '${p.name}:${typeToString(constraints[0])}';
								case _: '${p.name}:${constraints.map(c -> typeToString(c)).join(" & ")}';
							};
						case _: p.name;
					};
				case _: p.name;
			});
			decl += '<${params.join(", ")}>';
		}

		if (cl.superClass != null)
		{
			var sc = cl.superClass.t.get();
			var path = moduleAwarePath(sc.pack, sc.name, sc.module);
			if (cl.superClass.params.length > 0)
				path += '<${cl.superClass.params.map(p -> typeToString(p)).join(", ")}>';
			decl += " extends " + path;
		}

		for (iface in cl.interfaces)
		{
			var ic = iface.t.get();
			var ifaceKeyword = cl.isInterface ? "extends" : "implements";
			var ifacePath = moduleAwarePath(ic.pack, ic.name, ic.module);
			if (iface.params.length > 0)
				ifacePath += '<${iface.params.map(p -> typeToString(p)).join(", ")}>';
			decl += ' $ifaceKeyword $ifacePath';
		}

		buf.add('$decl\n{\n');

		if (cl.constructor != null)
			buf.add(generateClassField(cl.constructor.get(), false, cl.isInterface, overrideSet, cl));

		for (field in cl.fields.get())
		{
			if (field.meta.has(":generic") && (field.params == null || field.params.length == 0))
				continue;
			buf.add(generateClassField(field, false, cl.isInterface, overrideSet));
		}
		for (field in cl.statics.get())
		{
			if (field.meta.has(":generic") && (field.params == null || field.params.length == 0))
				continue;
			buf.add(generateClassField(field, true, cl.isInterface, overrideSet));
		}

		buf.add("}\n");
		return buf.toString();
	}

	/**
	 * Generates a stub for a single class field (variable or method).
	 * Handles property accessors, inline vars, inline methods, dynamic methods,
	 * overrides, final fields, default values, and method type parameters with constraints.
	 * For constructors (`new`), emits a super() call with type-appropriate default
	 * arguments if the superclass has a constructor.
	 * For interface fields, methods are emitted with a semicolon instead of a body.
	 * 
	 * @param field            The ClassField to generate.
	 * @param isStatic         Whether the field is static.
	 * @param isInterface      Whether the owning type is an interface (affects method emit).
	 * @param overrides        Set of field names that have override status in the owning class.
	 * @param owner            The owning ClassType, used to resolve super constructor args.
	 * @param fieldExtraStrip  Additional metadata names to strip from this field specifically.
	 * @return                 The generated Haxe source string for this field.
	 */
	static function generateClassField(field:ClassField, isStatic:Bool, isInterface:Bool = false, ?overrides:Map<String, Bool>, ?owner:ClassType,
			?extraStrip:Array<String>):String
	{
		if (extraStrip == null)
			extraStrip = [];

		var buf = new StringBuf();

		writeMetas(buf, field.meta.get(), "\t", extraStrip);

		if (field.doc != null && field.doc.trim().length > 0)
			buf.add('\t/** ${field.doc.trim()} **/\n');

		var access = buildAccess(field, isStatic, overrides != null && overrides.exists(field.name));

		switch (field.kind)
		{
			case FVar(read, write):
				var keyword = field.isFinal ? "final" : "var";
				var prop = field.isFinal ? null : isProperty(read, write);
				var decl = prop != null ? '$access $keyword ${field.name}($prop):${typeToString(field.type)}' : '$access $keyword ${field.name}:${typeToString(field.type)}';
				var defaultVal = isInterface ? null : getDefaultValue(field);
				if (defaultVal == null && !isInterface)
				{
					var hasValueMeta = Lambda.exists(field.meta.get(), m -> m.name == ":value");
					if (field.isFinal || hasValueMeta)
						defaultVal = defaultReturnValue(field.type);
				}
				buf.add(defaultVal != null ? '\t$decl = $defaultVal;\n' : '\t$decl;\n');

			case FMethod(_):
				var ft = switch (field.type)
				{
					case TFun(_, _): field.type;
					case _: Context.follow(field.type);
				};
				switch (ft)
				{
					case TFun(args, ret):
						var localParams = new Map<String, Bool>();
						if (field.params != null)
							for (p in field.params)
								localParams.set(p.name, true);

						var paramStr = "";
						if (field.params != null && field.params.length > 0)
						{
							var params = field.params.map(p ->
							{
								var constraintStr = switch (p.t)
								{
									case TInst(_.get() => cl, _):
										switch (cl.kind)
										{
											case KTypeParameter(constraints):
												switch (constraints.length)
												{
													case 0: null;
													case 1: typeToStringWithLocals(constraints[0], localParams);
													case _: constraints.map(c -> typeToStringWithLocals(c, localParams)).join(" & ");
												};
											case _: null;
										};
									case _: null;
								};
								return constraintStr != null ? '${p.name}:$constraintStr' : p.name;
							});
							paramStr = '<${params.join(", ")}>';
						}

						var argsStr = args.map(a -> (a.opt ? "?" : "") + a.name + ":" + typeToStringWithLocals(a.t, localParams)).join(", ");
						var retStr = typeToStringWithLocals(ret, localParams);

						if (field.name == "new")
						{
							var superCall = "";
							if (owner != null && owner.superClass != null)
							{
								var superCtor = owner.superClass.t.get().constructor;
								if (superCtor != null)
								{
									switch (Context.follow(superCtor.get().type))
									{
										case TFun(superArgs, _):
											var requiredArgs = superArgs.filter(a -> !a.opt);
											var superArgStr = requiredArgs.map(a ->
											{
												var d = defaultReturnValue(a.t);
												return d == "" ? "null" : d;
											}).join(", ");
											superCall = '\t\tsuper($superArgStr);\n';
										case _:
									}
								}
							}
							buf.add('\t$access function new($argsStr)\n\t{\n$superCall\t}\n');
						}
						else if (isInterface) buf.add('\t$access function ${field.name}$paramStr($argsStr):$retStr;\n'); else
						{
							var retVal = defaultReturnValue(ret);
							var body = retVal == "" ? "{}" : '{ return $retVal; }';
							buf.add('\t$access function ${field.name}$paramStr($argsStr):$retStr $body\n');
						}
					case _:
				}
		}
		buf.add("\n");
		return buf.toString();
	}

	/**
	 * Generates a stub for an enum type.
	 * Emits all enum constructors with their argument types. Parameterized enums
	 * include their type parameters with constraints.
	 * 
	 * @param en The EnumType to generate.
	 * @return   The generated Haxe source string.
	 */
	static function generateEnum(en:EnumType):String
	{
		var buf = new StringBuf();

		var pack = modulePackage(en.module);

		if (pack.length > 0)
			buf.add('package ${pack.join(".")};\n\n');

		if (en.doc != null && en.doc.trim().length > 0)
			buf.add('/** ${en.doc.trim()} **/\n');

		writeMetas(buf, en.meta.get());

		buf.add('enum ${en.name}');

		if (en.params.length > 0)
		{
			var params = en.params.map(p -> switch (p.t)
			{
				case TInst(_.get() => en, _):
					switch (en.kind)
					{
						case KTypeParameter(constraints):
							switch (constraints.length)
							{
								case 0: p.name;
								case 1: '${p.name}:${typeToString(constraints[0])}';
								case _: '${p.name}:${constraints.map(c -> typeToString(c)).join(" & ")}';
							};
						case _: p.name;
					};
				case _: p.name;
			});
			buf.add('<${params.join(", ")}>');
		}

		buf.add('\n{\n');

		for (name => field in en.constructs)
		{
			if (field.doc != null && field.doc.trim().length > 0)
				buf.add('\t/** ${field.doc.trim()} **/\n');
			writeMetas(buf, field.meta.get(), "\t");

			switch (field.type)
			{
				case TFun(args, _):
					var argsStr = args.map(a -> a.name + ":" + typeToString(a.t)).join(", ");
					buf.add('\t$name($argsStr);\n');
				case _:
					buf.add('\t$name;\n');
			}
		}

		buf.add("}\n");
		return buf.toString();
	}

	/**
	 * Generates a stub for a typedef.
	 * Anonymous struct typedefs are formatted across multiple indented lines.
	 * Named typedef references are preserved rather than inlined (i.e. if a field
	 * type is a typedef, we emit the typedef name, not its expanded structure).
	 * 
	 * @param td The DefType to generate.
	 * @return   The generated Haxe source string.
	 */
	static function generateTypedef(td:DefType):String
	{
		var buf = new StringBuf();

		var pack = modulePackage(td.module);

		if (pack.length > 0)
			buf.add('package ${pack.join(".")};\n\n');

		if (td.doc != null && td.doc.trim().length > 0)
			buf.add('/** ${td.doc.trim()} **/\n');

		writeMetas(buf, td.meta.get());

		buf.add('typedef ${td.name}');

		if (td.params.length > 0)
		{
			var params = td.params.map(p -> switch (p.t)
			{
				case TInst(_.get() => td, _):
					switch (td.kind)
					{
						case KTypeParameter(constraints):
							switch (constraints.length)
							{
								case 0: p.name;
								case 1: '${p.name}:${typeToString(constraints[0])}';
								case _: '${p.name}:${constraints.map(c -> typeToString(c)).join(" & ")}';
							};
						case _: p.name;
					};
				case _: p.name;
			});
			buf.add('<${params.join(", ")}>');
		}

		buf.add(' =\n');
		buf.add(typeToStringForTypedef(td.type));
		buf.add(';\n');

		return buf.toString();
	}

	/**
	 * Generates a stub for an abstract type.
	 * Handles enum abstracts, extern abstracts, `@:coreType` abstracts, and `@:multiType`
	 * abstracts. For enum abstracts, values are emitted as plain vars. For regular
	 * abstracts, instance fields are distinguished from static fields by detecting
	 * the implicit `this` argument the compiler injects on impl class methods.
	 * Property vars whose getter/setter is an instance method are also treated as
	 * instance fields. `@:from` and `@:to` conversions that are backed by explicit
	 * functions are omitted from the declaration (they appear as fields instead).
	 * 
	 * @param ab The AbstractType to generate.
	 * @return   The generated Haxe source string.
	 */
	static function generateAbstract(ab:AbstractType):String
	{
		var buf = new StringBuf();

		var pack = modulePackage(ab.module);

		if (pack.length > 0)
			buf.add('package ${pack.join(".")};\n\n');

		if (ab.doc != null && ab.doc.trim().length > 0)
			buf.add('/** ${ab.doc.trim()} **/\n');

		writeMetas(buf, ab.meta.get(), "", [":enum"]);

		var isEnumAbstract = ab.meta.has(":enum");
		var isCoreType = ab.meta.has(":coreType");
		var keyword = isEnumAbstract ? "enum abstract" : (isCoreType ? "extern abstract" : "abstract");

		buf.add('$keyword ${ab.name}');

		if (ab.params.length > 0)
		{
			var params = ab.params.map(p -> switch (p.t)
			{
				case TInst(_.get() => ab, _):
					switch (ab.kind)
					{
						case KTypeParameter(constraints):
							switch (constraints.length)
							{
								case 0: p.name;
								case 1: '${p.name}:${typeToString(constraints[0])}';
								case _: '${p.name}:${constraints.map(c -> typeToString(c)).join(" & ")}';
							};
						case _: p.name;
					};
				case _: p.name;
			});
			buf.add('<${params.join(", ")}>');
		}

		if (!isCoreType)
		{
			buf.add('(${typeToString(ab.type)})');

			var fromFuncTypes = new Map<String, Bool>();
			var toFuncTypes = new Map<String, Bool>();

			if (ab.impl != null)
			{
				for (field in ab.impl.get().statics.get())
				{
					if (field.meta.has(":from"))
					{
						switch (Context.follow(field.type))
						{
							case TFun(args, _):
								if (args.length > 0)
									fromFuncTypes.set(typeToString(args[0].t), true);
							case _:
						}
					}
					if (field.meta.has(":to"))
					{
						switch (Context.follow(field.type))
						{
							case TFun(_, ret):
								toFuncTypes.set(typeToString(ret), true);
							case _:
						}
					}
				}
			}

			for (from in ab.from)
			{
				var fromStr = typeToString(from.t);
				if (!fromFuncTypes.exists(fromStr))
					buf.add(' from $fromStr');
			}
			for (to in ab.to)
			{
				var toStr = typeToString(to.t);
				if (!toFuncTypes.exists(toStr))
					buf.add(' to $toStr');
			}
		}

		buf.add('\n{\n');

		if (ab.impl != null)
		{
			var implStatics = ab.impl.get().statics.get();

			implStatics.sort((a, b) ->
			{
				if (a.name == "_new")
					return -1;
				if (b.name == "_new")
					return 1;
				return 0;
			});

			for (field in implStatics)
			{
				if (field.name.startsWith("_") && field.name != "_new")
					continue;
				if (field.meta.has(":generic") && (field.params == null || field.params.length == 0))
					continue;

				if (field.name == "_new")
				{
					switch (Context.follow(field.type))
					{
						case TFun(args, _):
							var realArgs = args.filter(a -> a.name != "this" && a.name != "t");
							var argsStr = realArgs.map(a -> (a.opt ? "?" : "") + a.name + ":" + typeToString(a.t)).join(", ");
							if (ab.meta.has(":multiType"))
								buf.add('\tpublic function new($argsStr);\n\n');
							else
								buf.add('\tpublic function new($argsStr) {}\n\n');
						case _:
					}
					continue;
				}

				var isEnumValue = isEnumAbstract && field.meta.has(":enum");

				if (isEnumValue)
				{
					if (field.doc != null && field.doc.trim().length > 0)
						buf.add('\t/** ${field.doc.trim()} **/\n');
					var defaultVal = getDefaultValue(field);
					buf.add(defaultVal != null ? '\tvar ${field.name} = $defaultVal;\n\n' : '\tvar ${field.name};\n\n');
				}
				else
				{
					var hasImplicitThis = switch (Context.follow(field.type))
					{
						case TFun(args, _): args.length > 0 && args[0].name == "this";
						case _: false;
					};

					var isInstanceProperty = switch (field.kind)
					{
						case FVar(AccCall, _) | FVar(_, AccCall):
							var getterName = 'get_${field.name}';
							var setterName = 'set_${field.name}';
							Lambda.exists(implStatics, f -> (f.name == getterName || f.name == setterName)
								&& switch (Context.follow(f.type))
								{
									case TFun(args, _): args.length > 0 && args[0].name == "this";
									case _: false;
								});
						case _: false;
					};

					buf.add((hasImplicitThis || isInstanceProperty) ? generateAbstractInstanceField(field) : generateClassField(field, true, false, null,
						null, [":multiType"]));
				}
			}
		}

		buf.add("}\n");
		return buf.toString();
	}

	/**
	 * Generates a stub for an abstract instance field, stripping the implicit
	 * `this` argument the compiler injects on all instance methods in the impl class.
	 * This is necessary because abstract instance methods are lowered to static
	 * functions on the impl class with `this` as their first argument, which is
	 * not valid syntax in the abstract's source representation.
	 * 
	 * @param field The ClassField from the abstract's impl class.
	 * @return      The generated Haxe source string for this field.
	 */
	static function generateAbstractInstanceField(field:ClassField):String
	{
		var buf = new StringBuf();

		writeMetas(buf, field.meta.get(), "\t", [":multiType"]);

		if (field.doc != null && field.doc.trim().length > 0)
			buf.add('\t/** ${field.doc.trim()} **/\n');

		var access = field.isPublic ? "public" : "private";

		switch (field.kind)
		{
			case FVar(read, write):
				var keyword = field.isFinal ? "final" : "var";
				var prop = field.isFinal ? null : isProperty(read, write);
				var decl = prop != null ? '$access $keyword ${field.name}($prop):${typeToString(field.type)}' : '$access $keyword ${field.name}:${typeToString(field.type)}';
				var defaultVal = getDefaultValue(field);
				buf.add(defaultVal != null ? '\t$decl = $defaultVal;\n\n' : '\t$decl;\n\n');

			case FMethod(_):
				switch (Context.follow(field.type))
				{
					case TFun(args, ret):
						var realArgs = args.slice(1);
						var argsStr = realArgs.map(a -> (a.opt ? "?" : "") + a.name + ":" + typeToString(a.t)).join(", ");
						var retStr = typeToString(ret);
						var retVal = defaultReturnValue(ret);
						var body = retVal == "" ? "{}" : '{ return $retVal; }';
						buf.add('\t$access function ${field.name}($argsStr):$retStr $body\n\n');
					case _:
				}
		}

		return buf.toString();
	}

	/**
	 * Converts a Type to its Haxe source string representation.
	 * Preserves named typedef references instead of inlining their structure.
	 * Transparent import aliases (e.g. `import X as Y`) are followed through to
	 * their real type. Type parameters are emitted by name only (not as full paths).
	 * Primitive abstracts (`Void`, `Bool`, `Int`, `Float`) fall through to printComplexType.
	 * `StdTypes.X` references are stripped to just `X`.
	 * 
	 * @param t The Type to convert.
	 * @return  The Haxe source string for this type.
	 */
	static function typeToString(t:Type):String
	{
		switch (t)
		{
			case TType(_.get() => td, params):
				var followed = Context.follow(t);
				switch (followed)
				{
					case TType(_):
						var name = moduleAwarePath(td.pack, td.name, td.module);
						if (params.length > 0)
							name += '<${params.map(p -> typeToString(p)).join(", ")}>';
						return stripStd(name);
					case TAnonymous(_) | TFun(_, _):
						var name = moduleAwarePath(td.pack, td.name, td.module);
						if (params.length > 0)
							name += '<${params.map(p -> typeToString(p)).join(", ")}>';
						return stripStd(name);
					case _:
						return typeToString(followed);
				}

			case TInst(_.get() => cl, params):
				switch (cl.kind)
				{
					case KTypeParameter(_):
						return stripStd(cl.name);
					case _:
				}
				var name = moduleAwarePath(cl.pack, cl.name, cl.module);
				if (params.length > 0)
					name += '<${params.map(p -> typeToString(p)).join(", ")}>';
				return stripStd(name);

			case TEnum(_.get() => en, params):
				var name = moduleAwarePath(en.pack, en.name, en.module);
				if (params.length > 0)
					name += '<${params.map(p -> typeToString(p)).join(", ")}>';
				return stripStd(name);

			case TAbstract(_.get() => ab, params) if (ab.name != "Void" && ab.name != "Bool" && ab.name != "Int" && ab.name != "Float"):
				if (ab.name == "Null" && params.length == 1)
					return 'Null<${typeToString(params[0])}>';
				var name = moduleAwarePath(ab.pack, ab.name, ab.module);
				if (params.length > 0)
					name += '<${params.map(p -> typeToString(p)).join(", ")}>';
				return stripStd(name);

			case TFun(args, ret):
				var retStr = typeToString(ret);
				if (args.length == 0)
					return '() -> $retStr';
				if (args.length == 1)
				{
					var a = args[0];
					var argStr = typeToString(a.t);
					return '$argStr -> $retStr';
				}
				var argsStr = args.map(a -> typeToString(a.t)).join(", ");
				return '($argsStr) -> $retStr';

			case _:
		}

		var followed = Context.follow(t);
		var ct = Context.toComplexType(followed);
		var str = if (ct == null) "Dynamic" else switch (followed)
		{
			case TMono(_): "Dynamic";
			case _: new haxe.macro.Printer().printComplexType(ct);
		};

		return stripStd(str);
	}

	/**
	 * Converts a Type to its Haxe source string with special handling for typedef bodies.
	 * Unlike typeToString, this preserves anonymous struct types (`TAnonymous`) by name
	 * when they are referenced via a named typedef, and formats them across multiple
	 * indented lines when they appear inline. Used when printing typedef right-hand sides.
	 * 
	 * @param t      The Type to convert.
	 * @param indent The current indentation string (used for nested struct formatting).
	 * @return       The Haxe source string for this type.
	 */
	static function typeToStringForTypedef(t:Type, indent:String = ""):String
	{
		switch (t)
		{
			case TType(_.get() => td, params):
				var followed = Context.follow(t);
				switch (followed)
				{
					case TType(_) | TAnonymous(_) | TFun(_, _):
						var moduleParts = td.module.split(".");
						var lastName = moduleParts[moduleParts.length - 1];
						var name = td.name != lastName ? td.module + "." + td.name : dotPath(td.pack, td.name);
						if (params.length > 0)
							name += '<${params.map(p -> typeToStringForTypedef(p, indent)).join(", ")}>';
						return name;
					case _:
						return typeToStringForTypedef(followed, indent);
				}
			case _:
		}

		return switch (Context.follow(t))
		{
			case TAnonymous(_.get() => anon): printAnonStruct(anon, indent);
			case TFun(args, ret):
				var argsStr = args.map(a -> (a.opt ? "?" : "") + (a.name != "" ? a.name + ":" : "") + typeToStringForTypedef(a.t, indent)).join(", ");
				'($argsStr) -> ${typeToStringForTypedef(ret, indent)}';
			case _: typeToString(t);
		};
	}

	/**
	 * Converts a Type to its Haxe source string, substituting method-local type
	 * parameter names (e.g. `T`, `K`, `V`) instead of resolving them to their full paths.
	 * Used when printing method argument and return types so that generic methods
	 * emit `Array<T>` instead of `Array<some.module.ConcreteType>`.
	 * 
	 * @param t           The Type to convert.
	 * @param localParams A map of type parameter names that are in scope for this method.
	 * @return            The Haxe source string for this type.
	 */
	static function typeToStringWithLocals(t:Type, localParams:Map<String, Bool>):String
	{
		switch (t)
		{
			case TInst(_.get() => cl, params):
				switch (cl.kind)
				{
					case KTypeParameter(_):
						return stripStd(cl.name);
					case _:
				}
				if (params.length > 0)
				{
					var name = moduleAwarePath(cl.pack, cl.name, cl.module);
					return stripStd('$name<${params.map(p -> typeToStringWithLocals(p, localParams)).join(", ")}>');
				}
				return typeToString(t);

			case TType(_.get() => td, params):
				var followed = Context.follow(t);
				switch (followed)
				{
					case TType(_):
						var name = moduleAwarePath(td.pack, td.name, td.module);
						if (params.length > 0)
							name += '<${params.map(p -> typeToStringWithLocals(p, localParams)).join(", ")}>';
						return stripStd(name);
					case TAnonymous(_) | TFun(_, _):
						var name = moduleAwarePath(td.pack, td.name, td.module);
						if (params.length > 0)
							name += '<${params.map(p -> typeToStringWithLocals(p, localParams)).join(", ")}>';
						return stripStd(name);
					case _:
						return typeToStringWithLocals(followed, localParams);
				}

			case TAbstract(_.get() => ab, params):
				if (localParams.exists(ab.name))
					return stripStd(ab.name);
				if (ab.name == "Null" && params.length == 1)
					return 'Null<${typeToStringWithLocals(params[0], localParams)}>';
				if (params.length > 0)
				{
					var name = moduleAwarePath(ab.pack, ab.name, ab.module);
					return '$name<${params.map(p -> typeToStringWithLocals(p, localParams)).join(", ")}>';
				}
				return typeToString(t);

			case TFun(args, ret):
				var retStr = typeToStringWithLocals(ret, localParams);
				if (args.length == 0)
					return '() -> $retStr';
				if (args.length == 1)
				{
					var a = args[0];
					var argStr = typeToStringWithLocals(a.t, localParams);
					return '$argStr -> $retStr';
				}
				var argsStr = args.map(a -> typeToStringWithLocals(a.t, localParams)).join(", ");
				return '($argsStr) -> $retStr';

			case _:
		}
		return typeToString(t);
	}

	/**
	 * Formats an anonymous struct type (`TAnonymous`) across multiple indented lines.
	 * Optional fields are prefixed with `?` and their `Null<T>` wrapper is unwrapped
	 * back to plain `T`. Nested anonymous structs are recursively formatted with
	 * increased indentation.
	 * 
	 * @param anon   The AnonType to format.
	 * @param indent The current indentation string.
	 * @return       The formatted anonymous struct string.
	 */
	static function printAnonStruct(anon:AnonType, indent:String):String
	{
		var buf = new StringBuf();
		var inner = indent + "\t";
		var fields = anon.fields;

		buf.add("{\n");
		for (i => field in fields)
		{
			var isOptional = field.meta.has(":optional");

			var fieldType = if (isOptional) switch (Context.follow(field.type))
			{
				case TAbstract(_.get() => ab, [inner]) if (ab.name == "Null"): inner;
				case t: t;
			}
			else field.type;

			buf.add(inner);
			if (isOptional)
				buf.add("?");
			buf.add(field.name + ":");
			buf.add(typeToStringForTypedef(fieldType, inner));
			if (i < fields.length - 1)
				buf.add(",");
			buf.add("\n");
		}
		buf.add('${indent}}');
		return buf.toString();
	}

	/**
	 * Returns a type-appropriate default return value expression for use in stub bodies.
	 * Unwraps `Null<T>` before checking. Returns `""` for `Void` (no return statement needed).
	 * Returns primitive literals for `Int`/`UInt`/`Float`/`Bool`/`String`/`Array`/`Map`.
	 * Returns `cast null` for everything else, which satisfies the type checker
	 * while bypassing null safety checks.
	 * 
	 * @param t The return type.
	 * @return  A Haxe expression string suitable for use as a stub return value.
	 */
	static function defaultReturnValue(t:Type):String
	{
		var unwrapped = switch (t)
		{
			case TAbstract(_.get() => ab, [inner]) if (ab.name == "Null"): inner;
			case t: t;
		};

		return switch (Context.follow(unwrapped))
		{
			case TAbstract(_.get() => ab, _): switch (ab.name)
				{
					case "Int", "UInt": "0";
					case "Float": "0.0";
					case "Bool": "false";
					case "Void": "";
					case "Map": "[]";
					case _: "cast null";
				};
			case TInst(_.get() => cl, _): switch (cl.name)
				{
					case "String": '""';
					case "Array": "[]";
					case _: "cast null";
				};
			case _: "cast null";
		};
	}

	/**
	 * Writes filtered metadata entries into the output buffer.
	 * Skips duplicate entries, entries in `META_STRIP`, entries in extraStrip,
	 * build macros listed in `BUILD_MACROS_STRIP`, and the internal :value meta
	 * (which is emitted as a field initializer instead).
	 * 
	 * @param buf        The StringBuf to write into.
	 * @param metas      The metadata entries to filter and emit.
	 * @param indent     Indentation prefix for each emitted meta (e.g. `\t` for fields).
	 * @param extraStrip Additional metadata names to strip beyond `META_STRIP`.
	 */
	static function writeMetas(buf:StringBuf, metas:Metadata, indent:String = "", ?extraStrip:Array<String>)
	{
		if (extraStrip == null)
			extraStrip = [];

		var seen = new Map<String, Bool>();
		for (m in metas)
		{
			if (seen.exists(m.name))
				continue;
			if (META_STRIP.contains(m.name))
				continue;
			if (extraStrip.contains(m.name))
				continue;
			if (shouldStripBuildMeta(m))
				continue;
			if (m.name == ":value")
				continue;
			seen.set(m.name, true);
			buf.add('$indent${metaToString(m)}\n');
		}
	}

	/**
	 * Returns true if a :build or :autoBuild metadata entry references a macro
	 * listed in `BUILD_MACROS_STRIP` and should therefore be stripped from the stub.
	 * 
	 * @param m The metadata entry to check.
	 * @return  Whether this build macro should be stripped.
	 */
	static function shouldStripBuildMeta(m:MetadataEntry):Bool
	{
		if (m.name != ":build" && m.name != ":autoBuild")
			return false;
		var paramStr = m.params != null ? m.params.map(p -> haxe.macro.ExprTools.toString(p)).join("") : "";
		return Lambda.exists(BUILD_MACROS_STRIP, prefix -> paramStr.contains(prefix));
	}

	/**
	 * Converts a MetadataEntry to its Haxe source string representation.
	 * @param m The metadata entry to convert.
	 * @return  The metadata string (e.g. `@:meta` or `@:meta(param1, param2)`).
	 */
	static function metaToString(m:MetadataEntry):String
	{
		if (m.params == null || m.params.length == 0)
			return '@${m.name}';
		var params = m.params.map(p -> haxe.macro.ExprTools.toString(p)).join(", ");
		return '@${m.name}($params)';
	}

	/**
	 * Builds the access modifier string for a class field.
	 * Combines public/private, static, override, inline, and dynamic modifiers.
	 * Note: `final` is not included here — it replaces `var` as a keyword, not
	 * an access modifier, and is handled separately in field emission.
	 * 
	 * @param field      The field whose access to build.
	 * @param isStatic   Whether the field is static.
	 * @param isOverride Whether the field has override status.
	 * @return           The space-joined access modifier string.
	 */
	static function buildAccess(field:ClassField, isStatic:Bool, isOverride:Bool = false):String
	{
		var parts = [field.isPublic ? "public" : "private"];

		if (isStatic)
			parts.push("static");
		if (isOverride)
			parts.push("override");

		switch (field.kind)
		{
			case FMethod(MethInline):
				parts.push("inline");
			case FMethod(MethDynamic):
				parts.push("dynamic");
			case FVar(AccInline, _):
				parts.push("inline");
			case _:
		}
		return parts.join(" ");
	}

	/**
	 * Returns the property accessor string (e.g. `(get, set)`) for a field, or null
	 * if the field is a plain var. Inline vars return null since they use the
	 * `inline var` syntax rather than property syntax. Final fields also return null
	 * since `final` already implies (default, never).
	 * 
	 * @param read  The read VarAccess of the field.
	 * @param write The write VarAccess of the field.
	 * @return      The property string or null for plain vars.
	 */
	static function isProperty(read:VarAccess, write:VarAccess):Null<String>
	{
		if (read.match(AccInline))
			return null;
		var r = varAccessName(read, "get");
		var w = varAccessName(write, "set");
		return (r == "default" && w == "default") ? null : '$r, $w';
	}

	/**
	 * Converts a VarAccess to its Haxe source keyword.
	 * AccCall maps to the provided callKeyword (`get` or `set` depending on which
	 * side is being printed). AccInline also maps to the callKeyword since inlined
	 * accessors are still expressed as `get`/`set` in source syntax.
	 * 
	 * @param va          The VarAccess to convert.
	 * @param callKeyword The keyword to use for AccCall/AccInline (`get` or `set`).
	 * @return            The Haxe source keyword for this access.
	 */
	static function varAccessName(va:VarAccess, callKeyword:String):String
	{
		return switch (va)
		{
			case AccNormal: "default";
			case AccNo: "null";
			case AccNever: "never";
			case AccCall: callKeyword;
			case AccInline: callKeyword;
			case AccRequire(_, _): callKeyword;
			case _: "default";
		};
	}


	/**
	 * Returns the dot-separated module path for a ModuleType.
	 * Used to group types by their source file (multiple types can share a module).
	 * 
	 * @param t The ModuleType.
	 * @return  The module string (e.g. `flixel.util.FlxColor`).
	 */
	static function getModule(t:ModuleType):String
	{
		return switch (t)
		{
			case TClassDecl(_.get() => c): c.module;
			case TEnumDecl(_.get() => e): e.module;
			case TTypeDecl(_.get() => d): d.module;
			case TAbstract(_.get() => a): a.module;
		};
	}

	/**
	 * Builds the correct fully-qualified path for a type, accounting for secondary
	 * types that live inside a module whose primary type has a different name.
	 * For example, IFlxDestroyable lives in module flixel.util.FlxDestroyUtil, so
	 * its path is `flixel.util.FlxDestroyUtil.IFlxDestroyable` not `flixel.util.IFlxDestroyable`.
	 * 
	 * @param pack   The type's package segments.
	 * @param name   The type's name.
	 * @param module The type's module path.
	 * @return       The fully-qualified path string.
	 */
	static function moduleAwarePath(pack:Array<String>, name:String, module:String):String
	{
		var moduleParts = module.split(".");
		var lastName = moduleParts[moduleParts.length - 1];

		return name != lastName ? module + "." + name : dotPath(pack, name);
	}

	/**
	 * Derives the package array from a module string by dropping the last segment
	 * (the type name). Used to determine the output directory for a module's file,
	 * ensuring that private types in underscore subpackages (e.g. openfl._Vector)
	 * are written to the correct location alongside their public module types.
	 * 
	 * @param module The dot-separated module path.
	 * @return       The package segments (all but the last segment of the module).
	 */
	static function modulePackage(module:String):Array<String>
	{
		var parts = module.split(".");
		parts.pop();
		return parts;
	}

	/**
	 * Returns the simple type name for a ModuleType.
	 * 
	 * @param t The ModuleType.
	 * @return  The type name string.
	 */
	static function getTypeName(t:ModuleType):String
	{
		return switch (t)
		{
			case TClassDecl(_.get() => c): c.name;
			case TEnumDecl(_.get() => e): e.name;
			case TTypeDecl(_.get() => d): d.name;
			case TAbstract(_.get() => a): a.name;
		};
	}

	/**
	 * Checks if the type's metas contain any of `SKIP_META` to skip it.
	 * 
	 * @param metas The type's metas.
	 * @return 		Wether it should be skipped.
	 */
	static function shouldSkip(metas:Metadata):Bool
	{
		return Lambda.exists(metas, m -> SKIP_META.contains(m.name));
	}

	/**
	 * Used to filter out types generated by the HScript AbtractHandler macro.
	 */
	static function isModulePrivate(pack:Array<String>, name:String):Bool
	{
		var hasUnderscorePack = Lambda.exists(pack, segment -> segment.startsWith("_"));
		var isImplClass = name.endsWith("_Impl_");
		return hasUnderscorePack && isImplClass;
	}

	/**
	 * Checks if a module exists in our resolved class paths.
	 * 
	 * @param t 		 The module to check.
	 * @param classPaths Our resolved class paths.
	 * @return Wether the module exists in our class paths or not.
	 */
	static function isInClassPaths(t:ModuleType, classPaths:Array<String>):Bool
	{
		var pos = switch (t)
		{
			case TClassDecl(_.get() => c): c.pos;
			case TEnumDecl(_.get() => e): e.pos;
			case TTypeDecl(_.get() => d): d.pos;
			case TAbstract(_.get() => a): a.pos;
		};
		var file = Context.getPosInfos(pos).file;
		return Lambda.exists(classPaths, cp -> file.startsWith(cp));
	}

	/**
	 * Extracts the default value expression from a field's :value metadata.
	 * The :value meta is how Haxe stores field initializers in the typed AST.
	 * Regex literals are re-escaped since control characters get interpreted when
	 * stored. Cast expressions are stripped since enum abstract values are implicitly
	 * typed. Complex expressions (macro calls, field access, etc.) return null and
	 * fall back to defaultReturnValue at the call site.
	 * 
	 * @param field The field whose default value to extract.
	 * @return      The default value expression string, or null if unavailable.
	 */
	static function getDefaultValue(field:ClassField):Null<String>
	{
		var valueMeta = Lambda.find(field.meta.get(), m -> m.name == ":value");
		if (valueMeta == null || valueMeta.params == null || valueMeta.params.length == 0)
			return null;
		var expr = valueMeta.params[0];
		switch (expr.expr)
		{
			case EConst(CRegexp(pattern, flags)):
				pattern = pattern.split("\t").join("\\t");
				pattern = pattern.split("\r").join("\\r");
				pattern = pattern.split("\n").join("\\n");
				pattern = pattern.split("/").join("\\/");
				return '~/$pattern/$flags';
			case EConst(_):
				return haxe.macro.ExprTools.toString(expr);
			case EArrayDecl(_):
				return haxe.macro.ExprTools.toString(expr);
			case ECast(inner, _):
				return haxe.macro.ExprTools.toString(inner);
			case EUnop(_, _, _):
				return haxe.macro.ExprTools.toString(expr);
			case EBinop(_, _, _):
				return haxe.macro.ExprTools.toString(expr);
			case _:
				return null;
		}
	}

	/**
	 * Joins a package array and type name into a dot-separated path string.
	 * 
	 * @param pack The package segments.
	 * @param name The type name.
	 * @return     The dot-separated path (e.g. "flixel.util.FlxColor").
	 */
	static function dotPath(pack:Array<String>, name:String):String
	{
		return pack.length > 0 ? '${pack.join(".")}.$name' : name;
	}

	/**
	 * Write a type into it's correct path
	 * 
	 * @param pack 	  The package of this type which is used as it's path.
	 * @param name 	  The name of this type which is used as the file name.
	 * @param content The content of this type.
	 */
	static function writeFile(pack:Array<String>, name:String, content:String)
	{
		var dir = Path.join([outputDir].concat(pack));
		if (!FileSystem.exists(dir))
			FileSystem.createDirectory(dir);
		File.saveContent(Path.join([dir, '$name.hx']), content);
	}

	/**
	 * Get all the class paths defined in the compiler.
	 * Any class path that resides in the output folder is excluded.
	 * Classpaths listed in `LIBS_SKIP` array are excluded.
	 * 
	 * @return Array<String>
	 */
	static function getClassPaths():Array<String>
	{
		var buildArgs:Array<String> = Compiler.getConfiguration().args;
		var classPaths = [for (i => a in buildArgs) if (a == "-cp") buildArgs[i + 1] else continue];
		classPaths = classPaths.filter(f -> !f.startsWith(Path.directory(Compiler.getOutput())));

		for (lib in LIBS_SKIP)
			classPaths = classPaths.filter(f -> !f.replace("\\", "/").contains('/$lib/'));
		return classPaths;
	}

	/**
	 * When writing types they're resolved through their absolute type.
	 * String, Int, Void, Bool... and many standard types are come from StdTypes.
	 * You don't need to resolve these types through StdTypes to use them so we strip them through this.
	 * 
	 * @param  typeName 
	 * @return String
	 */
	static function stripStd(typeName:String):String
	{
		if (typeName.startsWith("StdTypes."))
			typeName = typeName.substr("StdTypes.".length);

		return typeName;
	}
}
#end
