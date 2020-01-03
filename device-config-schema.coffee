module.exports = {
  title: "pimatic-stats device config schemas"
  StatsDevice: {
    title: "Stats config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      show:
        description: "If 'all': variables will be shown in the GUI except the variables selected in Statistics. If 'none': nothing will be shown in the GUI, except the ones selected in Statistics."
        type: "string"
        enum: ["none", "all"]
      statistics:
        description: "Pimatic statistics that will be hidden (show=all) or shown (show=none) in the GUI."
        type: "array"
        format: "table"
        items:
          enum: [
            "devices", "rules", "variables",
            "pages", "groups", "plugins", "database",
            "index", "pluginsOutdated",  "pimaticVersion", "pimaticOutdated",
            "npmVersion", "nodeVersion"
          ]
    }
}
