/**
  easyproject helpers
 */
local EasyProject = {

  /**
   */
  flatten(source)::
    local flatten = function(source, target, x, y)
      local next = target { [x + '.' + y]: source[x][y] };

      if std.isObject(next[x + '.' + y]) then
        next + std.foldl(
          function(target, z) flatten(next, target, x + '.' + y, z),
          std.objectFields(source[x][y]),
          {}
        )
      else if std.isArray(next[x + '.' + y]) then
        next + std.foldl(
          function(target, z) flatten(next, target, x + '.' + y, z),
          std.range(0, std.length(source[x][y]) - 1),
          {}
        )
      else next;

    //
    std.foldl(
      function(target, x)
        local next = target { [x]: source[x] };

        if std.isObject(source[x]) then
          next + std.foldl(
            function(target, y) flatten(next, target, x, y),
            std.objectFields(source[x]),
            {}
          )
        else if std.isArray(source[x]) then
          next + std.foldl(
            function(target, y) flatten(next, target, x, y),
            std.range(0, std.length(source[x]) - 1),
            {}
          )
        else next,
      std.objectFields(source),
      {}
    ),

  /**
    helper for importing yaml documents with templating
   */
  yaml(str, params={})::
    local documents = std.parseYaml(str % EasyProject.flatten(params));

    // return single document as object instead of array
    if std.length(documents) == 1 then
      documents[0]
    else
      documents,

  /**
    helper for importing string documents with templating and includes
    automatically removes lines where includes were null to keep formatting
   */
  template(str, params={}, includes={})::
    local paramsWithIncludes = EasyProject.flatten(params {
      includes: std.mapWithKey(
        function(key, include)
          if include == null then '%(include)s' else include,
        includes
      ),
    });

    // split into lines for filtering
    local lines = std.split(str % paramsWithIncludes, '\n');

    // filter out includes that were not found
    std.lines(std.filter(function(line) std.length(std.findSubstr('%(include)s', line)) == 0, lines)),

  /**
    test if a given object is an EasyProject config
   */
  isConfig(target):: std.isObject(target) && std.objectHasAll(target, 'type') && std.isFunction(target.type) && target.type() == 'config',

  /**
    test if a given object is an EasyProject manifest
   */
  isManifest(target):: std.isObject(target) && std.objectHasAll(target, 'type') && std.isFunction(target.type) && target.type() == 'manifest',

  /**
    test if a given object is renderable
   */
  isRenderable(target):: std.isObject(target) && std.objectHasAll(target, 'render') && std.isFunction(target.render),

  /**
    test if a given object is resolvable
   */
  isResolvable(target):: std.isObject(target) && std.objectHasAll(target, 'resolveConfigs') && std.isFunction(target.resolveConfigs),

  /**
    convert an object or array to an EasyProject manifest
   */
  toManifest(target)::
    if self.isManifest(target) == false then
      self.manifest(
        render=(if self.isRenderable(target) then target.render else function(params, context) target),
        params=(if std.objectHas(target, 'params') then target.params else {}),
      )
    else
      target,


  /**
    convert an object to an EasyProject config
   */
  toConfig(target)::
    if self.isConfig(target) == false then
      self.config(
        render=(if self.isRenderable(target) then target.render else function(params, context) target),
        params=(if std.objectHas(target, 'params') then target.params else {}),
      )
    else
      target,

  /**
   */
  mapWithParams(fn, targets=[], params={})::
    std.map(
      function(target) (
        local result = fn(target, params);

        if std.type(result) == 'null' then
          target
        else
          result
      ),
      targets
    ),

  /**
    apply extensions to targets with params
   */
  mapWithExtensions(extensions, targets=[], params={})::
    self.mapWithParams(
      function(target, params)
        std.foldl(
          function(target, ext)
            local extParams = std.get(params, ext.name(), {});
            local mergedParams = EasyProject.resolveParams(ext, extParams);

            if ext.selector(target, mergedParams) then
              target.extend(
                function(target, params)
                  local extParams = std.get(params, ext.name(), {});
                  local mergedParams = EasyProject.resolveParams(ext, extParams);

                  // parent could return null if rendered with context
                  if std.isObject(target) then
                    ext.render(target, mergedParams)
              )
            else
              target,
          extensions,
          target
        ),
      targets,
      params
    ),

  /**
    creates a render context based on params and supplied config manifest
   */
  withContext(params, manifest=[]):: {
    /**
    find configs with a function
    */
    filter(func):: std.filter(function(config) func(config), manifest),

    /**
      find configs with a function and return the first result
     */
    find(test)::
      local result = self.filter(test);
      if std.length(result) > 0 then result[0],

    /**
     */
    has(kind, name=null):: self.find(
      function(config)
        if (std.objectHas(config, 'kind')) then
          if std.isString(name) then
            config.kind == kind && config.metadata.name == name
          else
            config.kind == kind
        else
          false
    ) != null,

    /**
      return current profile name or test if the profile name matches
     */
    profile(name=null)::
      if (name == null) then
        std.get(params, '_profile', false)
      else
        name == std.get(params, '_profile', ''),

    /**
     */
    maybe(test, patch, default={})::
      if std.isBoolean(test) && test then
        patch
      else if std.isString(test) && std.objectHas(params, test) then
        patch
      else
        default,

    /**
      get a specific config by kind and metadata name
     */
    get(kind, name=''):: self.find(function(config) config.kind == kind && config.metadata.name == name),
  },

  /**
    merge params with target defaults
   */
  resolveParams(target, params={})::
    local mergedParams = std.mergePatch(target.params(), params);

    // resolve with overrides
    if std.objectHasAll(target, 'overrides') then
      std.mergePatch(mergedParams, target.overrides(mergedParams))
    else
      mergedParams,

  /**
    merge supplied profile with params
  */
  resolveProfileParams(profile={}, params)::
    local config = self.toConfig(profile);
    local profileParams = config.render(self.withContext(params), params);

    std.mergePatch(profileParams, params),

  /**
    render configs with render context
   */
  renderWithContext(configs=[], params={})::
    std.foldl(
      function(context, config)
        local rendered = config.render(params, EasyProject.withContext(params, context));

        // filter out empty renders
        if rendered != null then
          context + [rendered]
        else
          context,
      configs,
      []
    ),

  /**
    creates an application with a given set of features
   */
  app(
    name,
    params={},
    profiles={},
    features=[],
    extensions=[],
    filter=function(config, params) true,
    map=function(config, params) config
  ):: {
    type():: 'application',

    // original filter & map used by extend
    local _filter = filter,
    local _map = map,

    // resolved and rendered configs used in preview and utility functions
    local renderedConfigs = self.render(params),
    local resolvedConfigs = self.resolveConfigs(params),
    local resolvedExtensions = self.resolveExtensions(params),

    // manifest preview
    manifest: renderedConfigs,

    // hidden fields
    name():: name,
    params():: params,
    profile(name):: if std.objectHas(profiles, name) then
      profiles[name] { _profile: name }
    else
      { _profile: name },
    profiles():: profiles,
    extensions():: extensions,
    features():: features,

    /**
      return a feature by name
     */
    feature(name, override=null)::
      local results = std.filter(function(feature) feature.name() == name, features);

      if std.length(results) > 0 then
        if std.isObject(override) || std.isFunction(override) then
          results[0].override(override)
        else
          results[0]
      else
        null,

    /**
      alias of renderWithProfile
     */
    init(profile='default', params={})::
      self.renderWithProfile(profile, params),

    /**
      render feature
     */
    render(params)::
      local appParams = EasyProject.resolveParams(self, params);

      //
      local configs = self.resolveConfigs(appParams);

      EasyProject.renderWithContext(configs, appParams),

    /**
     */
    renderWithProfile(profile='default', params={})::
      local paramsWithProfile = EasyProject.resolveProfileParams(self.profile(profile), params);
      local appParamsWithProfile = EasyProject.resolveParams(self, paramsWithProfile);

      local configs = self.resolveConfigsWithProfile(profile, appParamsWithProfile);

      EasyProject.renderWithContext(configs, appParamsWithProfile),

    /**
      resolve a flat array of configs from supplied features
     */
    resolveConfigs(params={})::
      local appParams = EasyProject.resolveParams(self, params);

      // convert all supplied configs to manifests and resolve individual configs without extensions applied
      local configs = std.flattenArrays(
        std.map(
          function(feature)
            feature.resolveConfigs(std.get(appParams, feature.name(), {}), false),
          self.resolveFeatures(appParams)
        )
      );

      // apply extensions and filter the configs with supplied filter
      local extended = EasyProject.mapWithExtensions(self.resolveExtensions(params), configs, appParams);
      local filtered = std.filter(function(config) filter(config, appParams), extended);

      // map the resulting configs
      EasyProject.mapWithParams(map, filtered, appParams),

    /**
     resolve a flat array of configs from supplied features
    */
    resolveConfigsWithProfile(profile='default', params={})::
      local paramsWithProfile = EasyProject.resolveProfileParams(self.profile(profile), params);
      local appParamsWithProfile = EasyProject.resolveParams(self, paramsWithProfile);

      // convert all supplied configs to manifests and resolve individual configs
      local configs = std.flattenArrays(
        std.map(
          function(feature)
            feature.resolveConfigsWithProfile(profile, std.get(appParamsWithProfile, feature.name(), {})),
          self.resolveFeatures(appParamsWithProfile)
        )
      );

      // apply extensions and filter the configs with supplied filter
      local extended = EasyProject.mapWithExtensions(self.resolveExtensions(params), configs, appParamsWithProfile);
      local filtered = std.filter(function(config) filter(config, appParamsWithProfile), extended);

      // map the resulting configs
      EasyProject.mapWithParams(map, filtered, appParamsWithProfile),

    /**
     */
    resolveFeatures(params)::
      local context = EasyProject.withContext(params, resolvedConfigs);

      std.filter(
        function(feature) std.type(feature) != 'null',
        std.flatMap(
          function(feature)
            local result = if std.isFunction(feature) then
              feature(params, context)
            else
              feature;

            if std.isArray(result) then result else [result],
          features
        )
      ),

    /**
      resolve a flat array of extensions from all manifests
    */
    resolveExtensions(params)::
      local context = EasyProject.withContext(params, resolvedConfigs);

      // app extensions
      std.filter(
        function(extension) std.type(extension) != 'null',
        std.map(
          function(extension)
            if std.isFunction(extension) then
              extension(params, context)
            else
              extension,
          extensions
        )
      )

      // feature extensions
      + std.flattenArrays(
        std.map(
          function(feature)
            local featureParams = EasyProject.resolveParams(feature, std.get(params, feature.name(), {}));
            feature.resolveExtensions(featureParams),
          self.resolveFeatures(params)
        )
      ),

    /**
      extend this application
    */
    extend(
      name=self.name(),
      params={},
      profiles={},
      features=[],
      extensions=[],

      //
      filter=function(config, params) true,
      map=function(config, params) config
    )::
      local mergedParams = std.mergePatch(self.params(), params);
      local mergedProfiles = std.mergePatch(self.profiles(), profiles);
      local mergedFeatures = self.features() + features;
      local mergedExtensions = self.extensions() + extensions;

      //
      local mergedFilter = function(config, params) _filter(config, params) && filter(config, params);
      local mergedMap = function(config, params) map(_map(config, params), params);

      //
      EasyProject.app(name, mergedParams, mergedProfiles, mergedFeatures, mergedExtensions, mergedFilter, mergedMap),

    /**
      find configs with a function
     */
    filter(func):: std.filter(function(config) func(config), resolvedConfigs),

    /**
      map configs
     */
    map(func):: EasyProject.mapWithParams(func, resolvedConfigs),

    /**
      find configs with a function and return the first result
     */
    find(test)::
      local result = self.filter(test);
      if std.length(result) > 0 then result[0],

    /**
      get a specific config by kind and metadata name
     */
    get(kind, name=''):: self.find(function(config) config.kind == kind && config.metadata.name == name),
  },

  /**
    configure a feature used by an easy project app
   */
  feature(
    name,
    params={},
    profiles={},
    configs=[],
    extensions=[],
    filter=function(config, params) true,
    map=function(config, params) config
  ):: {
    type():: 'feature',

    // original filter & map used by extend
    local _filter = filter,
    local _map = map,

    // create manifest preview
    local renderedConfigs = self.render(params),
    local resolvedConfigs = self.resolveConfigs(params, true),

    // manifest preview
    manifest: renderedConfigs,

    //
    name():: name,
    params():: params,
    profile(name):: if std.objectHas(profiles, name) then profiles[name] else {},
    profiles():: profiles,
    config(i):: configs[i],
    configs():: configs,
    extensions():: extensions,

    /**
      render feature
     */
    render(params)::
      local featureParams = EasyProject.resolveParams(self, params);

      // resolved configs
      local configs = self.resolveConfigs(featureParams, true);
      local context = EasyProject.withContext(featureParams, configs);

      EasyProject.renderWithContext(configs, featureParams),

    /**
     */
    renderWithProfile(profile='default', params={})::
      local paramsWithProfile = EasyProject.resolveProfileParams(self.profile(profile), params);
      local featureParamsWithProfile = EasyProject.resolveParams(self, paramsWithProfile);

      local configs = self.resolveConfigsWithProfile(profile, featureParamsWithProfile);

      EasyProject.renderWithContext(configs, featureParamsWithProfile),

    /**
      resolve a flat array of configs
     */
    resolveConfigs(params={}, withExtensions=false)::
      local featureParams = EasyProject.resolveParams(self, params);
      local context = EasyProject.withContext(featureParams);

      // allow conditional configs
      local configs = std.filter(
        function(config) std.type(config) != 'null',
        std.map(
          function(config)
            if std.isFunction(config) then
              config(featureParams, context)
            else
              config,
          self.configs()
        )
      );

      // convert all supplied configs to manifests and resolve individual configs
      local manifests = std.map(function(target) EasyProject.toManifest(target), configs);
      local configs = std.flattenArrays(std.map(function(manifest) manifest.resolveConfigs(featureParams), manifests));

      // maybe apply extensions
      local extended = if withExtensions then
        EasyProject.mapWithExtensions(self.resolveExtensions(featureParams), configs, params)
      else
        configs;

      // filter the configs with supplied filter
      local filtered = std.filter(function(config) filter(config, featureParams), extended);

      // map the resulting configs
      EasyProject.mapWithParams(map, filtered, featureParams),

    /**
     */
    resolveConfigsWithProfile(profile='default', params={}, withExtensions=false)::
      local paramsWithProfile = EasyProject.resolveProfileParams(self.profile(profile), params);
      local featureParamsWithProfile = EasyProject.resolveParams(self, paramsWithProfile);
      local context = EasyProject.withContext(featureParamsWithProfile);

      // allow conditional configs
      local configs = std.filter(
        function(config) std.type(config) != 'null',
        std.map(
          function(config)
            if std.isFunction(config) then
              config(featureParamsWithProfile, context)
            else
              config,
          self.configs()
        )
      );

      // convert all supplied configs to manifests and resolve individual configs
      local manifests = std.map(function(target) EasyProject.toManifest(target), configs);
      local configs = std.flattenArrays(std.map(function(manifest) manifest.resolveConfigs(featureParamsWithProfile), manifests));

      // maybe apply extensions
      local extended = if withExtensions then
        EasyProject.mapWithExtensions(self.resolveExtensions(featureParamsWithProfile), configs, params)
      else
        configs;

      // filter the configs with supplied filter
      local filtered = std.filter(function(config) filter(config, featureParamsWithProfile), extended);

      // map the resulting configs
      EasyProject.mapWithParams(map, filtered, featureParamsWithProfile),

    //
    resolveExtensions(params)::
      local context = EasyProject.withContext(params, resolvedConfigs);

      std.filter(
        function(extension) std.type(extension) != 'null',
        std.map(
          function(extension)
            if std.isFunction(extension) then
              extension(params, context)
            else
              extension,
          self.extensions()
        )
      ),


    /**
      extend this feature
     */
    extend(
      name=self.name(),
      params={},
      profiles={},
      configs=[],
      extensions=[],
      filter=function(config, params) true,
      map=function(config, params) config
    )::
      local mergedParams = std.mergePatch(self.params(), params);
      local mergedProfiles = std.mergePatch(self.profiles(), profiles);
      local mergedExtensions = self.extensions() + extensions;
      local mergedConfigs = self.configs() + configs;

      //
      local mergedFilter = function(config, params) _filter(config, params) && filter(config, params);
      local mergedMap = function(config, params) map(_map(config, params), params);

      EasyProject.feature(name, mergedParams, mergedProfiles, mergedConfigs, mergedExtensions, mergedFilter, mergedMap),

    /**
     */
    overrides(params):: params,

    /**
     */
    override(paramsOrFunction)::
      // original extension resolver
      local overrides = self.overrides;
      local resolveExtensions = self.resolveExtensions;

      // override with function and parent params
      local overrideWith = function(params)
        if std.isFunction(paramsOrFunction) then
          paramsOrFunction(params)
        else if std.isObject(paramsOrFunction) then
          paramsOrFunction;

      // supply override methods to be computed at render
      self {
        // add overrides to feature
        overrides(params):: std.mergePatch(overrides(params), overrideWith(params)),

        // override feature extensions
        resolveExtensions(params):: std.map(
          function(extension)
            extension.override(paramsOrFunction),
          resolveExtensions(params)
        ),
      },

    /**
      alias of override
     */
    configure(paramsOrFunction):: self.override(paramsOrFunction),

    /**
      find configs with a function
     */
    filter(func):: std.filter(function(config) func(config), resolvedConfigs),

    /**
      map configs
     */
    map(func):: EasyProject.mapWithParams(func, resolvedConfigs),

    /**
      find configs with a function and return the first result
     */
    find(test)::
      local result = self.filter(test);
      if std.length(result) > 0 then result[0],

    /**
      get a specific config by kind and metadata name
     */
    get(kind, name=''):: self.find(function(config) config.kind == kind && config.metadata.name == name),
  },

  /**
    a manifest of configs
   */
  manifest(
    render,
    params={},
    filter=function(config, params) true,
    map=function(config, params) config,
  ):: {
    type():: 'manifest',

    // render configs
    local resolvedConfigs = self.resolveConfigs(params),
    local renderedConfigs = self.render(params, EasyProject.withContext(params, resolvedConfigs)),

    // preview manifest
    manifest: renderedConfigs,

    //
    params():: params,

    /**
      resolve and render all configs into a standard manifest array
     */
    render(params, context)::
      local manifestParams = EasyProject.resolveParams(self, params);

      local configs = self.resolveConfigs(manifestParams);

      std.map(function(config) config.render(manifestParams, context), configs),

    /**
      resolves configs from supplied config data converting them to EasyProject configs
     */
    resolveConfigs(params={})::
      local manifestDefaults = self.params();
      local manifestParams = EasyProject.resolveParams(self, params);  // include manifest defaults in params
      local manifest = render(manifestParams, EasyProject.withContext(params));

      // resolve all configs
      local configs = std.mapWithIndex(
        function(i, target)
          // make configs from manifests renderable
          EasyProject.toConfig({
            // use manifest render function but only return the specific config
            render(params, context)::
              local manifest = render(manifestParams, context);

              if std.isArray(manifest) then
                manifest[i]
              else
                manifest,
            // inherit default params from manifest defaults
            params: manifestDefaults,
          }),
        if std.isArray(manifest) then manifest else [manifest]
      );

      // apply filter and remove empty configs
      local filtered = std.filter(
        function(config)
          if std.length(std.objectFields(config)) > 0 then
            filter(config, manifestParams)
          else
            false,
        configs
      );

      EasyProject.mapWithParams(map, filtered, manifestParams),

    //
    extend(
      render=function(manifest, params, ctx) manifest,
      params={},

      //
      filter=function(config, params) true,
      map=function(config, params) config
    )::
      EasyProject.manifest(
        render=function(params, ctx) (
          local configs = self.resolveConfigs(params);

          //
          local filtered = std.filter(function(config) filter(config, params), configs);
          local mapped = EasyProject.mapWithParams(map, filtered, params);

          render(mapped, params, ctx)
        ),
        params=EasyProject.resolveParams(self, params)
      ),

    /**
    */
    overrides(params):: params,

    /**
     */
    override(paramsOrFunction)::
      // original extension resolver
      local overrides = self.overrides;
      local resolveExtensions = self.resolveExtensions;

      // override with function and parent params
      local overrideWith = function(params)
        if std.isFunction(paramsOrFunction) then
          paramsOrFunction(params)
        else if std.isObject(paramsOrFunction) then
          paramsOrFunction;

      // supply override methods to be computed at render
      self {
        // add overrides to feature
        overrides(params):: std.mergePatch(overrides(params), overrideWith(params)),
      },

    /**
      alias of override
     */
    configure(paramsOrFunction):: self.override(paramsOrFunction),

    /**
      find configs with a function
     */
    filter(func):: std.filter(function(config) func(config), resolvedConfigs),

    /**
      map configs
     */
    map(func):: EasyProject.mapWithParams(map, resolvedConfigs),

    /**
      find configs with a function and return the first result
     */
    find(func)::
      local result = self.filter(func);
      if std.length(result) > 0 then result[0],

    /**
      get a specific config by kind and metadata name
     */
    get(kind, name=''):: self.find(function(config) config.kind == kind && config.metadata.name == name),
  },

  /**
    base config
  */
  config(render, params={})::
    render(params, EasyProject.withContext(params)) + {
      type():: 'config',

      //
      params():: params,

      //
      render(params, context)::
        local configParams = EasyProject.resolveParams(self, params);

        render(configParams, context),

      //
      extend(fn)::
        local render = function(params, context)
          local config = self.render(params, context);
          fn(config, params);

        EasyProject.config(render=render, params=params),

      // filter helper for kind + name
      is(kind, name=null)::
        local kinds = if std.isArray(kind) then kind else [kind];

        if std.type(name) != 'null' then
          local names = if std.isArray(name) then name else [name];

          std.count(kinds, self.kind) > 0 && std.count(names, self.metadata.name) > 0
        else
          std.count(kinds, self.kind) > 0,
    },

  /**
   config extension
  */
  extension(name, extends=null, selector=function(t, p) true, params={}, render=function(t, p) t)::
    local extension = {
      type():: 'extentsion',

      //
      name():: name,

      //
      params()::
        if EasyProject.isResolvable(extends) then
          std.mergePatch(extends.params(), params)
        else
          params,

      //
      overrides(params):: params,

      //
      override(paramsOrFunction)::
        local overrides = self.overrides;

        local overrideWith = function(params)
          if std.isFunction(paramsOrFunction) then
            paramsOrFunction(params)
          else if std.isObject(paramsOrFunction) then
            paramsOrFunction;

        // supply override methods to be computed at render
        self {
          // add overrides to feature
          overrides(params):: std.mergePatch(overrides(params), overrideWith(params)),
        },

      //
      configure(paramsOrFunction):: self.override(paramsOrFunction),

      //
      selector(target, params):: selector(target, params),

      //
      render(target, params):: render(target, params),
    };

    // preview using extended feature or manifest
    if EasyProject.isResolvable(extends) then
      local mergedParams = std.mergePatch(extends.params(), params);
      local resolvedConfigs = extends.resolveConfigs(params);
      local extendedConfigs = EasyProject.mapWithExtensions([extension], resolvedConfigs, mergedParams);

      extension {
        manifest: extendedConfigs,
      }
    else if EasyProject.isConfig(extends) then
      extension {
        manifest: render(extends.render(params, EasyProject.withContext(params)), params),
      }
    else if std.isObject(extends) then
      extension {
        manifest: render(extends, params),
      }
    else
      extension {
        manifest: render({}, params),
      },
};

EasyProject
