---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find the module definition
-- including its parameters and functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************
local nameOfModule = 'CSK_MultiRemoteLiDAR'

-- Create kind of "class"
local multiRemoteLiDAR = {}
multiRemoteLiDAR.__index = multiRemoteLiDAR

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--- Function to create new instance
---@param multiRemoteLiDARInstanceNo int Number of instance
---@return table[] self Instance of multiRemoteLiDAR
function multiRemoteLiDAR.create(multiRemoteLiDARInstanceNo)

  local self = {}
  setmetatable(self, multiRemoteLiDAR)

  -- Check if CSK_PersistentData module can be used if wanted
  self.persistentModuleAvailable = CSK_PersistentData ~= nil or false

  -- Check if CSK_UserManagement module can be used if wanted
  self.userManagementModuleAvailable = CSK_UserManagement ~= nil or false

  self.multiRemoteLiDARInstanceNo = multiRemoteLiDARInstanceNo -- Number of this instance
  self.multiRemoteLiDARInstanceNoString = tostring(self.multiRemoteLiDARInstanceNo) -- Number of this instance as string
  self.helperFuncs = require('Sensors/MultiRemoteLiDAR/helper/funcs') -- Load helper functions

  if _G.availableAPIs.scanner then

    -- Creation of LiDAR sensor TIM
    self.lidarProvider = Scan.Provider.RemoteScanner.create()

    -- Create parameters etc. for this module instance
    self.activeInUI = false -- Check if this instance is currently active in UI

    -- Default values for persistent data
    -- If available, following values will be updated from data of CSK_PersistentData module (check CSK_PersistentData module for this)
    self.parametersName = 'CSK_MultiRemoteLiDAR_Parameter' .. self.multiRemoteLiDARInstanceNoString -- name of parameter dataset to be used for this module
    self.parameterLoadOnReboot = false -- Status if parameter dataset should be loaded on app/device reboot

    -- Parameters to be saved permanently if wanted
    self.parameters = {}
    self.parameters.interface = 'ETHERNET' -- Interface connection type to the sensor
    self.parameters.ipAddress = '192.168.1.10' ..  self.multiRemoteLiDARInstanceNoString -- IP of the LiDAR sensor
    self.parameters.sensorType = 'LMSX00' --'LMSX00' -- LiDAR type
    self.parameters.processingFile = 'CSK_MultiRemoteLiDAR_Processing' -- which file to use for processing (will be started in own thread)
    self.parameters.internalProcessing = true -- should incoming scans be processed within this module or just provided for others
    self.parameters.viewerType = 'Scan' -- 'Scan' / 'PointCloud' - type of viewer to show data
    self.parameters.viewerActive = true -- Should the scan be shown in viewer
    self.parameters.encoderMode = false -- Combine scan data with encoder data to create point cloud
    self.parameters.encoderTriggerEvent = '' -- Event to start the encoder scan measurement
    self.parameters.encoderModeLoop = false -- Should it retrigger the encoder measurement automatically
    self.parameters.encoderDurationMode = 'TICKS' -- Encoder duration mode 'TICKS' (maybe add in future 'DISTANCE', 'TIME', 'CONVEYOR_TIMEOUT')
    self.parameters.encoderDurationModeValue = 200 -- Related to encoderDurationMode, value to determine how long LiDAR data should be collected combined with encoder data before providing PointCloud

    self.lidarProvider:setInterface(self.parameters.interface)
    self.lidarProvider:setIPAddress(self.parameters.ipAddress)
    self.lidarProvider:setSensorType(self.parameters.sensorType)

    Script.serveEvent("CSK_MultiRemoteLiDAR.OnRegisterLiDARSensor" .. self.multiRemoteLiDARInstanceNoString, "MultiRemoteLiDAR_OnRegisterLiDARSensor" .. self.multiRemoteLiDARInstanceNoString, 'handle:1:Scan.Provider.RemoteScanner')
    Script.serveEvent("CSK_MultiRemoteLiDAR.OnDeregisterLiDARSensor" .. self.multiRemoteLiDARInstanceNoString, "MultiRemoteLiDAR_OnDeregisterLiDARSensor" .. self.multiRemoteLiDARInstanceNoString, 'handle:1:Scan.Provider.RemoteScanner')

    -- Parameters to give to the processing script
    self.multiRemoteLiDARProcessingParams = Container.create()
    self.multiRemoteLiDARProcessingParams:add('multiRemoteLiDARInstanceNumber', self.multiRemoteLiDARInstanceNo, "INT")
    self.multiRemoteLiDARProcessingParams:add('viewerType', self.parameters.viewerType, "STRING")
    self.multiRemoteLiDARProcessingParams:add('viewerActive', self.parameters.viewerActive, "BOOL")
    self.multiRemoteLiDARProcessingParams:add('sensorType', self.parameters.sensorType, "STRING")
    self.multiRemoteLiDARProcessingParams:add('encoderMode', self.parameters.encoderMode, "BOOL")
    self.multiRemoteLiDARProcessingParams:add('encoderModeLoop', self.parameters.encoderModeLoop, "BOOL")
    self.multiRemoteLiDARProcessingParams:add('encoderDurationMode', self.parameters.encoderDurationMode, "STRING")
    self.multiRemoteLiDARProcessingParams:add('encoderDurationModeValue', self.parameters.encoderDurationModeValue, "INT")
    self.multiRemoteLiDARProcessingParams:add('encoderTriggerEvent', self.parameters.encoderTriggerEvent, "STRING")

    -- Handle processing
    Script.startScript(self.parameters.processingFile, self.multiRemoteLiDARProcessingParams)

  else
    _G.logger:warning(nameOfModule .. ": Module not supported as related CROWNs are not available.")
  end

  return self
end

--- Function to configure the LiDAR scanner
function multiRemoteLiDAR:setConfig()
  self.lidarProvider:stop()

  Script.releaseObject(self.lidarProvider)
  self.lidarProvider = nil

  self.lidarProvider = Scan.Provider.RemoteScanner.create()

  self.lidarProvider:setInterface(self.parameters.interface)

  if self.parameters.interface == 'ETHERNET' then
    self.lidarProvider:setIPAddress(self.parameters.ipAddress)
  elseif self.parameters.interface == 'SERIAL' then
    self.lidarProvider:setSerialConfiguration("SER1", "RS232", 460800, 8, "N", 1)
  end
  if self.parameters.sensorType == 'MRS1000' then
    self.lidarProvider:setSensorType('LMSX00')
  else
    self.lidarProvider:setSensorType(self.parameters.sensorType)
  end

  self.lidarProvider:start()
end

--- Function to start the LiDAR scanner
function multiRemoteLiDAR:startLiDARSensor()
  self:setConfig()
  if self.parameters.internalProcessing then
    Script.notifyEvent("MultiRemoteLiDAR_OnRegisterLiDARSensor" .. self.multiRemoteLiDARInstanceNoString, self.lidarProvider)
  end
end

--- Function to stop the LiDAR scanner
function multiRemoteLiDAR:stopLiDARSensor()
  self.lidarProvider:stop()
  Script.notifyEvent("MultiRemoteLiDAR_OnDeregisterLiDARSensor" .. self.multiRemoteLiDARInstanceNoString, self.lidarProvider)
end

return multiRemoteLiDAR

--*************************************************************************
--********************** End Function Scope *******************************
--*************************************************************************