class Utils:
    """Utility functions."""
    @staticmethod
    def fill_dict_with_none(d):
        for key in d:
            if isinstance(d[key], dict):
                Utils.fill_dict_with_none(d[key])  # Recursive call for nested dictionaries
            else:
                d[key] = None
        return d
    
    @staticmethod
    def update_config_with_default(configDict, defaultDict):
        """Recursively update configDict with values from defaultDict."""
        for key, default_value in defaultDict.items():
            if key not in configDict:
                try:
                    configDict[key] = eval(str(default_value))
                except:
                    configDict[key] = default_value
            elif isinstance(default_value, dict):
                configDict[key] = Utils.update_config_with_default(configDict.get(key, {}), default_value)
        return configDict