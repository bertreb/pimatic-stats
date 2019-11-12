module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  types = env.require('decl-api').types


  class StatsPlugin extends env.plugins.Plugin
    init: (app, @framework, @config) =>

      deviceConfigDef = require('./device-config-schema')
      @framework.deviceManager.registerDeviceClass('StatsDevice', {
        configDef: deviceConfigDef.StatsDevice,
        createCallback: (config, lastState) => new StatsDevice(config, lastState, @framework)
      })

  plugin = new StatsPlugin

  class StatsDevice extends env.devices.Device

    constructor: (@config, lastState, @framework) ->

      @id = @config.id
      @name = @config.name
      @test = @config.test
      @stats = if @config.statistics? then @config.statistics else null
      @attributes = {}
      @attributeValues = {}

      for _attr in @stats
        do (_attr) =>
          @attributes[_attr] =
            description: _attr
            type: types.number
            label: _attr
            acronym: _attr
          @attributeValues[_attr] = 0
          @_createGetter(_attr, =>
            return Promise.resolve @attributeValues[_attr]
          )
      @attributes.pimaticOutdated.type = types.string
      @attributes.nodeVersion.type = types.string

      @attributeValues.devices = lastState?.devices?.value or 0
      @attributeValues.rules = lastState?.rules?.value or 0
      @attributeValues.variables = lastState?.variables?.value or 0
      @attributeValues.pages = lastState?.pages?.value or 0
      @attributeValues.groups = lastState?.groups?.value or 0
      @attributeValues.size = lastState?.size?.value or 0
      @attributeValues.plugins = lastState?.plugins?.value or 0
      @attributeValues.pluginsOutdated = lastState?.pluginsOutdated?.value or 0
      @attributeValues.pimaticOutdated = lastState?.pimaticOutdated?.value or 0
      @attributeValues.nodeVersion = lastState?.nodeVersion?.value or 0

      events = [
        "deviceAdded", "deviceRemoved", "ruleAdded",
        "ruleRemoved", "variableAdded", "variableRemoved",
        "pageAdded", "pageRemoved", "groupAdded", "groupRemoved"
      ]

      for _event in events
        @framework.on _event, () =>
          @refreshData()

      @framework.on 'after init', () =>
        @refreshData()

      @framework.pluginManager.getInstalledPluginsWithInfo()
        .then((data) =>
          @attributeValues.plugins = data.length
          @emit 'plugins', @attributeValues.plugins
        )
        .catch((err) ->
          env.logger.error err.message
        )
      
      checkOutdated = () => 
        @_updateTimeout = setTimeout =>
          if @_destroyed then return
          @framework.pluginManager.getOutdatedPlugins()
            #test
            .then((data) =>
              @attributeValues.pluginsOutdated = data.length
              @emit 'pluginsOutdated', @attributeValues.pluginsOutdated
              checkOutdated()
            )
            .catch((err) ->
              env.logger.error err.message
            )
        , 3600000 # 1 hour
      checkOutdated()

      @framework.pluginManager.isPimaticOutdated()
        .then((data) =>
          @attributeValues.pimaticOutdated = if data then "yes" else "no"
          @emit 'pimaticOutdated', @attributeValues.pimaticOutdated
        )
        .catch((err) ->
          env.logger.error err.message
        )
      @attributeValues.nodeVersion = String process.versions.node
      @emit 'nodeVersion', @attributeValues.nodeVersion

      super()

    refreshData: () =>
      @attributeValues.devices = Number (@framework.deviceManager.getDevices()).length
      @emit 'devices', @attributeValues.devices

      @attributeValues.rules = Number (@framework.ruleManager.getRules()).length
      @emit 'rules', @attributeValues.rules

      @attributeValues.variables = Number (@framework.variableManager.getVariables()).length
      @emit 'variables', @attributeValues.variables

      @attributeValues.groups = Number (@framework.groupManager.getGroups()).length
      @emit 'groups', @attributeValues.groups

      @_pages = @framework.pageManager.getPages()
      @attributeValues.pages = Number (@_pages).length
      @emit 'pages', @attributeValues.pages

      @attributeValues.size =
        @attributeValues.devices * 2 +
        @attributeValues.rules +
        @attributeValues.variables +
        @attributeValues.plugins * 5
      @emit 'size', @attributeValues.size


    destroy: ->
      clearTimeout(@_updateTimeout)
      super()

  return plugin
