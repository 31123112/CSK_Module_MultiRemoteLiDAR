# Changelog
All notable changes to this project will be documented in this file.

## Release 0.4.0

### Improvements
- Renamed abbreviations (Lidar - LiDAR, Id-ID, Ip-IP)
- Using recursive helper functions to convert Container <-> Lua table

## Release 0.3.0

### Improvements
- Update to EmmyLua annotations
- Usage of lua diagnostics
- Documentation updates

## Release 0.2.0

### New features
- "setEncoderMode" and additional features / events to merge incoming scanner data with encoder data
- Configure if viewer of module should show content or not ("setViewerActive")
- Check if APIs are available on device

### Improvements
- Loading only required APIs ('LuaLoadAllEngineAPI = false') -> less time for GC needed
- Docu updates

## Release 0.1.0
- Initial commit