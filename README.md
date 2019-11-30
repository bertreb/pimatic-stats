pimatic-stats
===================

Getting statistics from a Pimatic home automation system.
This plugin provides information on the configuration of your Pimatic system. This information is normally only available via the api. The number of devices, rules, variables, pages and groups can be selected and will be available as a variable and visible via the GUI. For comparison the 'size' of Pimatic is added. The size shows how big the configuration is. The higher the size the more devices and rules are used.

Installation
------------
To enable the Stats plugin add this to the plugins section via the GUI or add it in the config.json file.

```
...
{
  "plugin": "Stats"
}
...
```

Stats device
-----------------
When the plugin is installed (including restart) a Stats device can be added. Below the settings, with the items that are available.

```
{
  "id": "<stats-device-id>",
  "class": "StatsDevice",
  "statistics":
    "items": [
       "devices", "rules", "variables", "pages", "groups", "plugins", "index", "database", "pluginsOutdated", "pimaticOutdated",
       "nodeVersion"
     ]
}
```
### Usage

The following variables are available to you in Pimatic for the StatsDevice. All variables are initially visible. In the device config you can remove/add them.

* ${stats device id}.devices          - number of devices
* ${stats device id}.rules            - number of rules
* ${stats device id}.variables        - number of variables. Devices specific and custom
* ${stats device id}.pages            - number of pages
* ${stats device id}.groups           - number of groups
* ${stats device id}.index      	    - the size of the Pimatic system,  based on total number of devices and rules
* ${stats device id}.pluginsOutdated  - number of outdated Plugins. This is checked every day at midnight.
* ${stats device id}.database         - number of errors in the pimatic database. The number of errors is shown or if none "ok". This is checked every day at midnight.
* ${stats device id}.pimaticOutdated  - whether Pimatic is outdated. This is checked every day at midnight.
* ${stats device id}.nodeVersion      - actual Node version Pimatic is using


All variables are available and can be used without adding the variable to the GUI. In the GUI an variable becomes visible when added in the device config. After changing the config, reload the page to make the change visible.
When you remove errors in the database the number of errors shown in this device is not updated until midnight.

---------

The plugin is Node v10 compatible and in development. You could backup Pimatic before you are using this plugin!
