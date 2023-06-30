---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

-- Load all relevant APIs for this module
--**************************************************************************

local availableAPIs = {}

local function loadAPIs()
  CSK_MultiRemoteLiDAR = require 'API.CSK_MultiRemoteLiDAR'

  Container = require 'API.Container'
  Engine = require 'API.Engine'
  Log = require 'API.Log'
  Log.Handler = require 'API.Log.Handler'
  Log.SharedLogger = require 'API.Log.SharedLogger'
  Object = require 'API.Object'
  Timer = require 'API.Timer'
  View = require 'API.View'
  View.PointCloudDecoration = require 'API.View.PointCloudDecoration'
  View.ScanDecoration = require 'API.View.ScanDecoration'

  -- Check if related CSK modules are available to be used
  local appList = Engine.listApps()
  for i = 1, #appList do
    if appList[i] == 'CSK_Module_PersistentData' then
      CSK_PersistentData = require 'API.CSK_PersistentData'
    elseif appList[i] == 'CSK_Module_UserManagement' then
      CSK_UserManagement = require 'API.CSK_UserManagement'
    end
  end
end

local function loadScannerAPIs()
  -- If you want to check for specific APIs/functions supported on the device the module is running, place relevant APIs here
  -- e.g.:
  PointCloud = require 'API.PointCloud'
  PointCloud.Collector = require 'API.PointCloud.Collector'
  Scan = require 'API.Scan'
  Scan.Provider = {}
  Scan.Provider.RemoteScanner = require 'API.Scan.Provider.RemoteScanner'
  Scan.Transform = require 'API.Scan.Transform'
end

local function loadEncoderAPIs()
  -- If you want to check for specific APIs/functions supported on the device the module is running, place relevant APIs here
  -- e.g.:
  CSK_Encoder = require 'API.CSK_Encoder'
  Encoder = require 'API.Encoder'
end

availableAPIs.default = xpcall(loadAPIs, debug.traceback) -- TRUE if all default APIs were loaded correctly
availableAPIs.scanner = xpcall(loadScannerAPIs, debug.traceback) -- TRUE if all scan specific APIs were loaded correctly
availableAPIs.encoder = xpcall(loadEncoderAPIs, debug.traceback) -- TRUE if all encoder feature specific APIs were loaded correctly

return availableAPIs
--**************************************************************************