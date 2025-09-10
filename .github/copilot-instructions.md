# Copilot Instructions for SourcePawn Plugin Development

## Repository Overview
This repository contains the **AutoSilencer** SourcePawn plugin for SourceMod, which automatically silences M4A1 and USP weapons in Counter-Strike games. The plugin allows players to toggle auto-silencing functionality through client preferences.

## Technical Environment

### Core Technologies
- **Language**: SourcePawn (.sp files)
- **Platform**: SourceMod 1.11+ (minimum supported version)
- **Build System**: SourceKnight (modern SourceMod build tool)
- **Compiler**: SourcePawn compiler via SourceKnight
- **Dependencies**: 
  - sourcemod (core framework)
  - multicolors (chat coloring library)
  - clientprefs (client preference storage)
  - sdkhooks (SDK hooking functionality)

### Project Structure
```
addons/sourcemod/
├── scripting/
│   └── AutoSilencer.sp          # Main plugin source
├── translations/
│   └── autosilencer.phrases.txt # Translation strings
└── plugins/                     # Compiled output (generated)
    └── AutoSilencer.smx
```

## Development Guidelines

### Code Style Standards
- **Indentation**: Use tabs (4 spaces equivalent)
- **Variable Naming**:
  - Local variables and parameters: `camelCase`
  - Function names: `PascalCase` 
  - Global variables: `g_PascalCase` (prefix with `g_`)
- **Required Pragmas**:
  ```sourcepawn
  #pragma semicolon 1
  #pragma newdecls required
  ```
- **Include Order**: Standard SourceMod includes first, then third-party
- **Memory Management**: Always use `delete` for cleanup, never `.Clear()` on StringMaps/ArrayLists
- **String Operations**: Use format functions, avoid string concatenation in loops

### SourcePawn Best Practices

#### Essential Plugin Structure
```sourcepawn
public Plugin myinfo = {
    name = "Plugin Name",
    author = "Author Name",
    description = "Plugin Description", 
    version = "X.X.X",
    url = "Repository URL"
};

public void OnPluginStart() {
    // Initialize translations, commands, hooks
    LoadTranslations("pluginname.phrases.txt");
}

public void OnPluginEnd() {
    // Cleanup if necessary (usually not needed)
}
```

#### Client Handling
- Always validate clients: `IsFakeClient(client)`, `IsClientSourceTV(client)`
- Use `OnClientPutInServer()` for client setup
- Implement late loading support for plugin restarts
- Use ClientPrefs for persistent user settings

#### Memory and Performance
- Use `delete` directly without null checks (safe in SourcePawn)
- Avoid O(n) operations in frequently called functions (aim for O(1))
- Cache expensive operations
- Minimize timer usage
- Use methodmaps for structured data

#### Database Operations (if applicable)
- **ALL SQL queries MUST be asynchronous**
- Use prepared statements/parameter binding
- Implement proper SQL injection prevention
- Use transactions when appropriate
- Always handle SQL errors

## Build System

### SourceKnight Configuration
The project uses SourceKnight (`sourceknight.yaml`) for building:
- **Build Command**: Handled by GitHub Actions
- **Dependencies**: Auto-managed (SourceMod, MultiColors)
- **Output**: Compiled `.smx` files in plugins directory

### Local Development
```bash
# Install SourceKnight (if working locally)
pip install sourceknight

# Build plugin
sourceknight build

# The compiled plugin will be in .sourceknight/package/
```

### CI/CD Pipeline
- **Trigger**: Push/PR to any branch
- **Build**: Ubuntu 24.04 with SourceKnight
- **Artifacts**: Packaged plugin with translations
- **Release**: Auto-created for tags and main branch

## Translation System

### Adding New Phrases
1. Add entries to `addons/sourcemod/translations/autosilencer.phrases.txt`:
```
"Phrases"
{
    "Your New Phrase"
    {
        "#format"   "{1:s},{2:d}"
        "en"        "Your English text with {1} and {2}"
    }
}
```

2. Use in code:
```sourcepawn
char buffer[256];
FormatEx(buffer, sizeof(buffer), "%T", "Your New Phrase", client, stringVar, intVar);
```

## Plugin-Specific Architecture

### Core Functionality
- **Main Feature**: Auto-silences M4A1/USP weapons on equip
- **User Control**: Toggle via command or cookie menu
- **Persistence**: ClientPrefs cookies for user settings
- **Events**: SDKHook_WeaponEquip for weapon detection

### Key Components
1. **Client Preferences**: `g_bIsAutoSEnabled[]` array + cookies
2. **Weapon Tracking**: `primary[]` array to prevent double-processing
3. **Commands**: `sm_autosilencer` console command
4. **Menu System**: Cookie menu integration for settings

### Modification Guidelines
- Weapon detection logic is in `Hook_OnWeaponEquip()`
- Settings management in `UpdateSilencerStatus()` and menu handlers
- Client state managed through `OnClientCookiesCached()` 
- Always test weapon equip scenarios when modifying core logic

## Common Development Tasks

### Adding New Weapons
1. Modify weapon classname check in `Hook_OnWeaponEquip()`
2. Ensure proper weapon properties are set
3. Test with different weapon variants

### Extending User Interface
1. Add new translation phrases
2. Extend menu system in `AutoSilencerSetting()`
3. Update command handling if needed

### Configuration Options
- Consider adding ConVars for admin-configurable settings
- Use configuration files for complex settings
- Maintain backward compatibility

## Testing Considerations

### Manual Testing
- Test on Counter-Strike server with SourceMod
- Verify functionality with M4A1-S and USP-S weapons
- Test client preference persistence across reconnects
- Validate late loading scenarios
- Test menu navigation and command functionality

### Code Quality Checks
- Ensure no compiler warnings
- Verify proper client validation
- Check for memory leaks (use SourceMod profiler)
- Validate string handling and buffer sizes

## Troubleshooting

### Common Issues
- **Plugin not loading**: Check SourceMod version compatibility
- **Weapons not silencing**: Verify weapon classnames match game version
- **Settings not saving**: Ensure ClientPrefs is working
- **Translation errors**: Check phrase file syntax

### Development Environment
- Use SourceMod's error logging for debugging
- Monitor server console for SourcePawn errors
- Test with `sm plugins load/unload` for rapid iteration

## Version Management
- Follow semantic versioning (MAJOR.MINOR.PATCH)
- Update version in plugin info block
- Create Git tags for releases
- Document changes in commit messages

## Dependencies and Compatibility
- **Minimum SourceMod**: 1.11.0
- **Required Extensions**: SDKTools, ClientPrefs
- **Game Compatibility**: Counter-Strike games with silenced weapons
- **External Dependencies**: MultiColors plugin (auto-managed)

This repository uses modern SourcePawn practices and follows the SourceMod plugin development standards. When making changes, prioritize code clarity, performance, and user experience while maintaining compatibility with the existing plugin ecosystem.