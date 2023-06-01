{
  lib,
  attrAttr  ? "attrsOf",
  listAttr  ? "listOf",
  nullAttr  ? "nullOr",
  subMAttr  ? "options",
  typeAttr  ? "type",
  debug     ? false,
  ...
}:
module:
let
  inherit (builtins) attrNames concatStringsSep mapAttrs throw trace typeOf;
  inherit (lib.types) lazyAttrsOf listOf submodule anything attrs bool float int nullOr package path str;
  mkOptionW = breadcrumb: optName: optDef:
    let result = lib.mkOption (toOption breadcrumb optName optDef);
    in
      if debug then
        trace ''
          function: simple-options.mkOptionWrapper
          args:
            breadcrumb: ${concatStringsSep "." breadcrumb};
            optName: ${optName}
            optDef: ${concatStringsSep " " (attrNames optDef)}
          result: ${concatStringsSep " " (attrNames result)}
          result.type: ${typeOf result.type._type}
        ''
        result
      else result;

  toOptions = breadcrumb: options: { options = mapAttrs (mkOptionW breadcrumb) options; };

  toType    = breadcrumb: type:
    let result =
      if typeOf breadcrumb != "list"
        then throw ''breadcrumb must be a list, instead it is a ${typeOf breadcrumb}'' else
      if typeOf type       != "set"
        then throw ''type must be a attrset, instead it is a ${typeOf type}, breadcrumb: ${concatStringsSep "." breadcrumb}'' else
      if type ? _type
        then type else
      if type ? ${typeAttr}
        then type.type else
      if type ? ${attrAttr}
        then lazyAttrsOf (toType    (breadcrumb ++ [attrAttr]) type."${attrAttr}") else
      if type ? ${listAttr}
        then listOf      (toType    (breadcrumb ++ [listAttr]) type."${listAttr}") else
      if type ? ${nullAttr}
        then nullOr      (toType    (breadcrumb ++ [nullAttr]) type."${nullAttr}") else
      if type ? ${subMAttr}
        then submodule   (toOptions (breadcrumb ++ [subMAttr]) type."${subMAttr}") else
      if type ? default && (lib.isDerivation type.default)
        then package else
      if type ? default && typeOf type.default == "set" && type.default ? _type
        then type.default._type else
      if type ? default && typeOf type.default == "set"
        then lazyAttrsOf anything else
      if type ? default && typeOf type.default == "bool"
        then bool else
      if type ? default && typeOf type.default == "float"
        then float else
      if type ? default && typeOf type.default == "int"
        then int else
      if type ? default && typeOf type.default == "list"
        then listOf anything else
      if type ? default && typeOf type.default == "null"
        then nullOr anything else
      if type ? default && typeOf type.default == "string"
        then str else
      throw ''${concatStringsSep "." breadcrumb} has no attr _type|${typeAttr}|${attrAttr}|${listAttr}|${nullAttr}|${subMAttr}'';
    in
      if debug then
        trace ''
          function: simple-options.toType
          args:
            breadcrumb: ${concatStringsSep "." breadcrumb}
            type: ${concatStringsSep " " (attrNames type)}
          result: ${concatStringsSep " " (attrNames result)}
          result.type: ${result._type}
        ''
        result
      else result;

  toOption  = breadcrumb: optName: optDef:
    let result =
      if typeOf breadcrumb != "list"
        then throw ''breadcrumb must be a list, instead it is a ${typeOf breadcrumb}'' else
      if typeOf optName    != "string"
        then throw ''optName must be a string, instead it is a ${typeOf optName}, breadcrumb: ${concatStringsSep "." breadcrumb}'' else
      if typeOf optDef     != "set"
        then throw ''optDef must be a attrset, instead it is a ${typeOf optDef}, breadcrumb: ${concatStringsSep "." breadcrumb}, optName: ${optName}'' else
      if optDef ? ${typeAttr}
        then removeAttrs optDef [typeAttr] // { type = optDef.${typeAttr}; } else
      if optDef ? ${attrAttr}
        then removeAttrs optDef [attrAttr] // { type = lazyAttrsOf (toType    (breadcrumb ++ [optName attrAttr]) optDef.${attrAttr}); } else
      if optDef ? ${listAttr}
        then removeAttrs optDef [listAttr] // { type = listOf      (toType    (breadcrumb ++ [optName listAttr]) optDef.${listAttr}); } else
      if optDef ? ${nullAttr}
        then removeAttrs optDef [nullAttr] // { type = nullOr      (toType    (breadcrumb ++ [optName nullAttr]) optDef.${nullAttr}); } else
      if optDef ? ${subMAttr}
        then removeAttrs optDef [subMAttr] // { type = submodule   (toOptions (breadcrumb ++ [optName subMAttr]) optDef.${subMAttr}); } else
      if optDef ? default
        then             optDef            // { type = toType                 (breadcrumb ++ [optName]         ) optDef             ; } else
      throw ''${concatStringsSep "." (breadcrumb ++ optName)} has no attr _type|${typeAttr}|${attrAttr}|${listAttr}|${nullAttr}|${subMAttr}'';
    in
      if debug then
        trace ''
          function: simple-options.toOption
          args:
            breadcrumb: ${concatStringsSep "." breadcrumb}
            optName: ${optName}
            optDef: ${concatStringsSep " " (attrNames optDef)}
          result: ${concatStringsSep " " (attrNames result)}
          result.type: ${result.type._type}
        ''
        result
      else result;
in  module // toOptions [subMAttr] module."${subMAttr}"
