module.exports = {
  title: "pimatic-stats device config schemas"
  StatsDevice: {
    title: "Stats config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      statistics:
        description: "Pimatic statistics that will be exposed in the device."
        type: "array"
        format: "table"
        items:
          enum: [
            "devices", "rules", "variables",
            "pages", "groups", "plugins", "database",
            "index", "pluginsOutdated", "pimaticOutdated",
            "nodeVersion"
          ]
  }
}
