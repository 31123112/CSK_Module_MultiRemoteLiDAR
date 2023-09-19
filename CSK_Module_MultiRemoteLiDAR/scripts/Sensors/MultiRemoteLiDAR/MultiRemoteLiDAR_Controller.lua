---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

--***************************************************************
-- Inside of this script, you will find the necessary functions,
-- variables and events to communicate with the multiRemoteLiDAR_Model and _Instances
--***************************************************************

--**************************************************************************
--************************ Start Global Scope ******************************
--**************************************************************************
local nameOfModule = 'CSK_MultiRemoteLiDAR'

local funcs = {}

-- Timer to update UI via events after page was loaded
local tmrMultiRemoteLiDAR = Timer.create()
tmrMultiRemoteLiDAR:setExpirationTime(300)
tmrMultiRemoteLiDAR:setPeriodic(false)

-- Timer to wait for sensor bootUp
local tmrSensorBootUp = Timer.create()
tmrSensorBootUp:setExpirationTime(25000)
tmrSensorBootUp:setPeriodic(false)

local multiRemoteLiDAR_Model -- Reference to model handle
local multiRemoteLiDAR_Instances -- Reference to instances handle
local selectedInstance = 1 -- Which instance is currently selected
local helperFuncs = require('Sensors/MultiRemoteLiDAR/helper/funcs')
local bootUpStatus = false -- Is app curently waiting for sensor bootUp
local disableStartStopOnUI = true
-- ************************ UI Events Start ********************************
-- Only to prevent WARNING messages, but these are only examples/placeholders for dynamically created events/functions
----------------------------------------------------------------
local function emptyFunction()
end
Script.serveFunction("CSK_MultiRemoteLiDAR.processInstanceNUM", emptyFunction)

Script.serveEvent("CSK_MultiRemoteLiDAR.OnNewResultNUM", "MultiRemoteLiDAR_OnNewResultNUM")
Script.serveEvent("CSK_MultiRemoteLiDAR.OnNewValueToForwardNUM", "MultiRemoteLiDAR_OnNewValueToForwardNUM")
Script.serveEvent("CSK_MultiRemoteLiDAR.OnNewValueUpdateNUM", "MultiRemoteLiDAR_OnNewValueUpdateNUM")

Script.serveEvent("CSK_MultiRemoteLiDAR.OnRegisterLiDARSensorNUM", "MultiRemoteLiDAR_OnRegisterLiDARSensorNUM")
Script.serveEvent("CSK_MultiRemoteLiDAR.OnDeregisterLiDARSensorNUM", "MultiRemoteLiDAR_OnDeregisterLiDARSensorNUM")

Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewEncoderScanNUM', 'MultiRemoteLiDAR_OnNewEncoderScanNUM')

----------------------------------------------------------------

-- Real events
--------------------------------------------------

Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewResult', 'MultiRemoteLiDAR_OnNewResult')

Script.serveEvent("CSK_MultiRemoteLiDAR.OnNewStatusLoadParameterOnReboot", "MultiRemoteLiDAR_OnNewStatusLoadParameterOnReboot")
Script.serveEvent("CSK_MultiRemoteLiDAR.OnPersistentDataModuleAvailable", "MultiRemoteLiDAR_OnPersistentDataModuleAvailable")
Script.serveEvent("CSK_MultiRemoteLiDAR.OnNewParameterName", "MultiRemoteLiDAR_OnNewParameterName")

Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusViewerType', 'MultiRemoteLiDAR_OnNewStatusViewerType')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusViewerActive', 'MultiRemoteLiDAR_OnNewStatusViewerActive')

Script.serveEvent("CSK_MultiRemoteLiDAR.OnNewViewerID", "MultiRemoteLiDAR_OnNewViewerID")
Script.serveEvent("CSK_MultiRemoteLiDAR.OnNewScanViewerID", "MultiRemoteLiDAR_OnNewScanViewerID")
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusInterface', 'MultiRemoteLiDAR_OnNewStatusInterface')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusSensorIP', 'MultiRemoteLiDAR_OnNewStatusSensorIP')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusSensorType', 'MultiRemoteLiDAR_OnNewStatusSensorType')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusInternalProcessing', 'MultiRemoteLiDAR_OnNewStatusInternalProcessing')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusEncoderMode', 'MultiRemoteLiDAR_OnNewStatusEncoderMode')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusEncoderModeLoop', 'MultiRemoteLiDAR_OnNewStatusEncoderModeLoop')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusEncoderTriggerEvent', 'MultiRemoteLiDAR_OnNewStatusEncoderTriggerEvent')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusEncoderDurationMode', 'MultiRemoteLiDAR_OnNewStatusEncoderDurationMode')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusEncoderDurationModeValue', 'MultiRemoteLiDAR_OnNewStatusEncoderDurationModeValue')

Script.serveEvent("CSK_MultiRemoteLiDAR.OnNewInstanceList", "MultiRemoteLiDAR_OnNewInstanceList")
Script.serveEvent("CSK_MultiRemoteLiDAR.OnNewProcessingParameter", "MultiRemoteLiDAR_OnNewProcessingParameter")
Script.serveEvent("CSK_MultiRemoteLiDAR.OnNewSelectedInstance", "MultiRemoteLiDAR_OnNewSelectedInstance")
Script.serveEvent("CSK_MultiRemoteLiDAR.OnDataLoadedOnReboot", "MultiRemoteLiDAR_OnDataLoadedOnReboot")

Script.serveEvent("CSK_MultiRemoteLiDAR.OnUserLevelOperatorActive", "MultiRemoteLiDAR_OnUserLevelOperatorActive")
Script.serveEvent("CSK_MultiRemoteLiDAR.OnUserLevelMaintenanceActive", "MultiRemoteLiDAR_OnUserLevelMaintenanceActive")
Script.serveEvent("CSK_MultiRemoteLiDAR.OnUserLevelServiceActive", "MultiRemoteLiDAR_OnUserLevelServiceActive")
Script.serveEvent("CSK_MultiRemoteLiDAR.OnUserLevelAdminActive", "MultiRemoteLiDAR_OnUserLevelAdminActive")

Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusIPError', 'MultiRemoteLiDAR_OnNewStatusIPError')

Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusInstanceAmount', 'MultiRemoteLiDAR_OnNewStatusInstanceAmount')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnActivateStartAndStopLiDAROnUI', 'MultiRemoteLiDAR_OnActivateStartAndStopLiDAROnUI')

-- filtering
-- AngleFilter
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusAngleFilter', 'MultiRemoteLiDAR_OnNewStatusAngleFilter')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewValueAngleFilterStartAngle', 'MultiRemoteLiDAR_OnNewValueAngleFilterStartAngle')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewValueAngleFilterStopAngle', 'MultiRemoteLiDAR_OnNewValueAngleFilterStopAngle')

-- MeanFilter
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusMeanFilterScans', 'MultiRemoteLiDAR_OnNewStatusMeanFilterScans')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusMeanFilterBeams', 'MultiRemoteLiDAR_OnNewStatusMeanFilterBeams')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewValueMeanFilterScans', 'MultiRemoteLiDAR_OnNewValueMeanFilterScans')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewValueMeanFilterBeams', 'MultiRemoteLiDAR_OnNewValueMeanFilterBeams')

-- Resolution-halving
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusResolutionHalving', 'MultiRemoteLiDAR_OnNewStatusResolutionHalving')

-- measuring
-- edgeDetection
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusEdgeDetection', 'MultiRemoteLiDAR_OnNewStatusEdgeDetection')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewValueGabThreshold', 'MultiRemoteLiDAR_OnNewValueGabThreshold')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewValueGradientThreshold', 'MultiRemoteLiDAR_OnNewValueGradientThreshold')

Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewValueEdgeDetectionGabUI', 'MultiRemoteLiDAR_OnNewValueEdgeDetectionGabUI')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewValueEdgeDetectionHeightUI', 'MultiRemoteLiDAR_OnNewValueEdgeDetectionHeightUI')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewValueEdgeDetectionAngleUI', 'MultiRemoteLiDAR_OnNewValueEdgeDetectionAngleUI')


-- fixedPoint
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewStatusFixedPoint', 'MultiRemoteLiDAR_OnNewStatusFixedPoint')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewValuePointA', 'MultiRemoteLiDAR_OnNewValuePointA')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewValuePointB', 'MultiRemoteLiDAR_OnNewValuePointB')

Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewValueFixedPointHeightUI', 'MultiRemoteLiDAR_OnNewValueFixedPointHeightUI')


--results
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewEdgeDetectionResults', 'MultiRemoteLiDAR_OnNewEdgeDetectionResults')
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewFixedPointResults', 'MultiRemoteLiDAR_OnNewFixedPointResults')








-- ************************ UI Events End **********************************

--- Function to check if inserted string is a valid IP
---@param ip string Text to check for IP
---@return boolean status Result if IP is valid
local function checkIP(ip)
  if not ip then return false end
  local a,b,c,d=ip:match("^(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)$")
  a=tonumber(a)
  b=tonumber(b)
  c=tonumber(c)
  d=tonumber(d)
  if not a or not b or not c or not d then return false end
  if a<0 or 255<a then return false end
  if b<0 or 255<b then return false end
  if c<0 or 255<c then return false end
  if d<0 or 255<d then return false end
  return true
end

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--- 
---@param instanceNumber int 
---@param gab float 
---@param height float 
---@param angle float 
local function handleOnNewEdgeDetectionResults(instanceNumber, gab, height, angle)
  if instanceNumber == selectedInstance then
    Script.notify('MultiRemoteLiDAR_OnNewValueEdgeDetectionGabUI',string.format("%0.0f mm", gab))
    Script.notify('MultiRemoteLiDAR_OnNewValueEdgeDetectionHeightUI',string.format("%0.0f mm", height))
    Script.notify('MultiRemoteLiDAR_OnNewValueEdgeDetectionAngleUI',string.format("%0.0f °", angle))
  end
end
Script.register('CSK_MultiRemoteLiDAR.OnNewEdgeDetectionResults', handleOnNewEdgeDetectionResults)


--- 
---@param instance int 
---@param height float 
local function handleOnNewFixedPointResults(instance, height)
  if instanceNumber == selectedInstance then
    Script.notify('MultiRemoteLiDAR_OnNewValueFixedPointHeightUI',string.format("%0.0f mm", height))
  end
end
Script.register('CSK_MultiRemoteLiDAR.OnNewFixedPointResults', handleOnNewFixedPointResults)




-- Functions to forward logged in user roles via CSK_UserManagement module (if available)
-- ***********************************************
--- Function to react on status change of Operator user level
---@param status boolean Status if Operator level is active
local function handleOnUserLevelOperatorActive(status)
  Script.notifyEvent("MultiRemoteLiDAR_OnUserLevelOperatorActive", status)
end

--- Function to react on status change of Maintenance user level
---@param status boolean Status if Maintenance level is active
local function handleOnUserLevelMaintenanceActive(status)
  Script.notifyEvent("MultiRemoteLiDAR_OnUserLevelMaintenanceActive", status)
end

--- Function to react on status change of Service user level
---@param status boolean Status if Service level is active
local function handleOnUserLevelServiceActive(status)
  Script.notifyEvent("MultiRemoteLiDAR_OnUserLevelServiceActive", status)
end

--- Function to react on status change of Admin user level
---@param status boolean Status if Admin level is active
local function handleOnUserLevelAdminActive(status)
  Script.notifyEvent("MultiRemoteLiDAR_OnUserLevelAdminActive", status)
end
-- ***********************************************

--- Function to forward data updates from instance threads to Controller part of module
---@param eventname string Eventname to use to forward value
---@param value auto Value to forward
local function handleOnNewValueToForward(eventname, value)
  Script.notifyEvent(eventname, value)
end

--- Function to get access to the multiRemoteLiDAR_Model
---@param handle handle Handle of multiRemoteLiDAR_Model object
local function setMultiRemoteLiDAR_Model_Handle(handle)
  multiRemoteLiDAR_Model = handle
  Script.releaseObject(handle)
end
funcs.setMultiRemoteLiDAR_Model_Handle = setMultiRemoteLiDAR_Model_Handle

--- Function to get access to the multiRemoteLiDAR_Instances
---@param handle handle Handle of multiRemoteLiDAR_Instances object
local function setMultiRemoteLiDAR_Instances_Handle(handle)
  multiRemoteLiDAR_Instances = handle
  if multiRemoteLiDAR_Instances[selectedInstance].userManagementModuleAvailable then
    -- Register on events of CSK_UserManagement module if available
    Script.register('CSK_UserManagement.OnUserLevelOperatorActive', handleOnUserLevelOperatorActive)
    Script.register('CSK_UserManagement.OnUserLevelMaintenanceActive', handleOnUserLevelMaintenanceActive)
    Script.register('CSK_UserManagement.OnUserLevelServiceActive', handleOnUserLevelServiceActive)
    Script.register('CSK_UserManagement.OnUserLevelAdminActive', handleOnUserLevelAdminActive)
  end
  Script.releaseObject(handle)

  for i = 1, #multiRemoteLiDAR_Instances do
    Script.register("CSK_MultiRemoteLiDAR.OnNewValueToForward" .. tostring(i) , handleOnNewValueToForward)
  end

end
funcs.setMultiRemoteLiDAR_Instances_Handle = setMultiRemoteLiDAR_Instances_Handle

--- Function to update user levels
local function updateUserLevel()
  if multiRemoteLiDAR_Instances[selectedInstance].userManagementModuleAvailable then
    -- Trigger CSK_UserManagement module to provide events regarding user role
    CSK_UserManagement.pageCalled()
  else
    -- If CSK_UserManagement is not active, show everything
    Script.notifyEvent("MultiRemoteLiDAR_OnUserLevelAdminActive", true)
    Script.notifyEvent("MultiRemoteLiDAR_OnUserLevelMaintenanceActive", true)
    Script.notifyEvent("MultiRemoteLiDAR_OnUserLevelServiceActive", true)
    Script.notifyEvent("MultiRemoteLiDAR_OnUserLevelOperatorActive", true)
  end
end

--- Function to send all relevant values to UI on resume
local function handleOnExpiredTmrMultiRemoteLiDAR()

  updateUserLevel()

  Script.notifyEvent('MultiRemoteLiDAR_OnNewSelectedInstance', selectedInstance)
  Script.notifyEvent('MultiRemoteLiDAR_OnNewStatusInstanceAmount', #multiRemoteLiDAR_Instances)

  Script.notifyEvent("MultiRemoteLiDAR_OnNewInstanceList", helperFuncs.createStringListBySize(#multiRemoteLiDAR_Instances))

  Script.notifyEvent('MultiRemoteLiDAR_OnNewStatusViewerType', multiRemoteLiDAR_Instances[selectedInstance].parameters.viewerType)
  Script.notifyEvent('MultiRemoteLiDAR_OnNewStatusViewerActive', multiRemoteLiDAR_Instances[selectedInstance].parameters.viewerActive)
  Script.notifyEvent('MultiRemoteLiDAR_OnNewViewerID', 'multiRemoteLiDARViewer' .. tostring(selectedInstance))
  Script.notifyEvent('MultiRemoteLiDAR_OnNewScanViewerID', 'multiRemoteLiDARScanViewer' .. tostring(selectedInstance))

  Script.notifyEvent('MultiRemoteLiDAR_OnNewStatusInterface', multiRemoteLiDAR_Instances[selectedInstance].parameters.interface)
  Script.notifyEvent('MultiRemoteLiDAR_OnNewStatusSensorIP', multiRemoteLiDAR_Instances[selectedInstance].parameters.ipAddress)
  Script.notifyEvent('MultiRemoteLiDAR_OnNewStatusSensorType', multiRemoteLiDAR_Instances[selectedInstance].parameters.sensorType)
  Script.notifyEvent('MultiRemoteLiDAR_OnNewStatusInternalProcessing', multiRemoteLiDAR_Instances[selectedInstance].parameters.internalProcessing)

  Script.notifyEvent('MultiRemoteLiDAR_OnNewStatusEncoderMode', multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderMode)
  Script.notifyEvent('MultiRemoteLiDAR_OnNewStatusEncoderModeLoop', multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderModeLoop)
  Script.notifyEvent('MultiRemoteLiDAR_OnNewStatusEncoderTriggerEvent', multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderTriggerEvent)
  Script.notifyEvent('MultiRemoteLiDAR_OnNewStatusEncoderDurationMode', multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderDurationMode)
  Script.notifyEvent('MultiRemoteLiDAR_OnNewStatusEncoderDurationModeValue', multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderDurationModeValue)
  Script.notifyEvent("MultiRemoteLiDAR_OnNewStatusLoadParameterOnReboot", multiRemoteLiDAR_Instances[selectedInstance].parameterLoadOnReboot)
  Script.notifyEvent("MultiRemoteLiDAR_OnPersistentDataModuleAvailable", multiRemoteLiDAR_Instances[selectedInstance].persistentModuleAvailable)
  Script.notifyEvent("MultiRemoteLiDAR_OnNewParameterName", multiRemoteLiDAR_Instances[selectedInstance].parametersName)

  Script.notifyEvent("MultiRemoteLiDAR_OnNewStatusIPError", false)

  
  Script.notifyEvent('MultiRemoteLiDAR_OnActivateStartAndStopLiDAROnUI', disableStartStopOnUI)

  --filtering
  -- AngleFilter
  Script.notifyEvent("MultiRemoteLiDAR_OnNewStatusAngleFilter", multiRemoteLiDAR_Instances[selectedInstance].parameters.filtering.angleFilter.enable)
  Script.notifyEvent("MultiRemoteLiDAR_OnNewValueAngleFilterStartAngle", tostring(multiRemoteLiDAR_Instances[selectedInstance].parameters.filtering.angleFilter.startAngle))
  Script.notifyEvent("MultiRemoteLiDAR_OnNewValueAngleFilterStopAngle", tostring(multiRemoteLiDAR_Instances[selectedInstance].parameters.filtering.angleFilter.stopAngle))

  -- MeanFilter
  Script.notifyEvent("MultiRemoteLiDAR_OnNewStatusMeanFilterScans", multiRemoteLiDAR_Instances[selectedInstance].parameters.filtering.meanFilter.enableScanDepth)
  Script.notifyEvent("MultiRemoteLiDAR_OnNewStatusMeanFilterBeams", multiRemoteLiDAR_Instances[selectedInstance].parameters.filtering.meanFilter.enableBeamsWidth)
  Script.notifyEvent("MultiRemoteLiDAR_OnNewValueMeanFilterScans", tostring(multiRemoteLiDAR_Instances[selectedInstance].parameters.filtering.meanFilter.scanDepth))
  Script.notifyEvent("MultiRemoteLiDAR_OnNewValueMeanFilterBeams", tostring(multiRemoteLiDAR_Instances[selectedInstance].parameters.filtering.meanFilter.beamsWidth))

  -- Resolution-halving
  Script.notifyEvent("MultiRemoteLiDAR_OnNewStatusResolutionHalving", multiRemoteLiDAR_Instances[selectedInstance].parameters.filtering.resolutionHalving.enable)

  -- measuring
  -- edgeDetection
  Script.notifyEvent('MultiRemoteLiDAR_OnNewStatusEdgeDetection', multiRemoteLiDAR_Instances[selectedInstance].parameters.measuring.edgeDetection.enable)
  Script.notifyEvent('MultiRemoteLiDAR_OnNewValueGabThreshold', tostring(multiRemoteLiDAR_Instances[selectedInstance].parameters.measuring.edgeDetection.gabThreshold))
  Script.notifyEvent('MultiRemoteLiDAR_OnNewValueGradientThreshold', tostring(multiRemoteLiDAR_Instances[selectedInstance].parameters.measuring.edgeDetection.gradientThreshold))

  -- fixedPoint
  Script.notifyEvent('MultiRemoteLiDAR_OnNewStatusFixedPoint', multiRemoteLiDAR_Instances[selectedInstance].parameters.measuring.fixedPoint.enable)
  Script.notifyEvent('MultiRemoteLiDAR_OnNewValuePointA', tostring(multiRemoteLiDAR_Instances[selectedInstance].parameters.measuring.fixedPoint.scanAngleA))
  Script.notifyEvent('MultiRemoteLiDAR_OnNewValuePointB', tostring(multiRemoteLiDAR_Instances[selectedInstance].parameters.measuring.fixedPoint.scanAngleB))

  -- fixedPoint

end
Timer.register(tmrMultiRemoteLiDAR, "OnExpired", handleOnExpiredTmrMultiRemoteLiDAR)

-- ********************* UI Setting / Submit Functions Start ********************

local function pageCalled()
  updateUserLevel() -- try to hide user specific content asap
  tmrMultiRemoteLiDAR:start()
  return ''
end
Script.serveFunction("CSK_MultiRemoteLiDAR.pageCalled", pageCalled)

local function setSelectedInstance(instance)
  selectedInstance = instance
  _G.logger:info(nameOfModule .. ": New selected instance = " .. tostring(selectedInstance))
  multiRemoteLiDAR_Instances[selectedInstance].activeInUI = true
  Script.notifyEvent('MultiRemoteLiDAR_OnNewProcessingParameter', selectedInstance, 'activeInUI', true)
  tmrMultiRemoteLiDAR:start()
end
Script.serveFunction("CSK_MultiRemoteLiDAR.setSelectedInstance", setSelectedInstance)

local function getInstancesAmount ()
  return #multiRemoteLiDAR_Instances
end
Script.serveFunction("CSK_MultiRemoteLiDAR.getInstancesAmount", getInstancesAmount)

local function addInstance()
  _G.logger:info(nameOfModule .. ": Add instance")
  table.insert(multiRemoteLiDAR_Instances, multiRemoteLiDAR_Model.create(#multiRemoteLiDAR_Instances+1))
  Script.deregister("CSK_MultiRemoteLiDAR.OnNewValueToForward" .. tostring(#multiRemoteLiDAR_Instances) , handleOnNewValueToForward)
  Script.register("CSK_MultiRemoteLiDAR.OnNewValueToForward" .. tostring(#multiRemoteLiDAR_Instances) , handleOnNewValueToForward)
  handleOnExpiredTmrMultiRemoteLiDAR()
end
Script.serveFunction('CSK_MultiRemoteLiDAR.addInstance', addInstance)

local function resetInstances()
  _G.logger:info(nameOfModule .. ": Reset instances.")
  setSelectedInstance(1)
  local totalAmount = #multiRemoteLiDAR_Instances
  while totalAmount > 1 do
    Script.releaseObject(multiRemoteLiDAR_Instances[totalAmount])
    multiRemoteLiDAR_Instances[totalAmount] =  nil
    totalAmount = totalAmount - 1
  end
  handleOnExpiredTmrMultiRemoteLiDAR()
end
Script.serveFunction('CSK_MultiRemoteLiDAR.resetInstances', resetInstances)

local function getLiDARHandle(instanceNo)
  if multiRemoteLiDAR_Instances[instanceNo].lidarProvider then
    return multiRemoteLiDAR_Instances[instanceNo].lidarProvider
  else
    return nil
  end
end
Script.serveFunction('CSK_MultiRemoteLiDAR.getLiDARHandle', getLiDARHandle)

local function setViewerType(viewerType)
  _G.logger:info(nameOfModule .. ": Set viewer type to " .. viewerType)
  multiRemoteLiDAR_Instances[selectedInstance].parameters.viewerType = viewerType
  Script.notifyEvent('MultiRemoteLiDAR_OnNewStatusViewerType', multiRemoteLiDAR_Instances[selectedInstance].parameters.viewerType)
  Script.notifyEvent('MultiRemoteLiDAR_OnNewProcessingParameter', selectedInstance, 'viewerType', viewerType)
end
Script.serveFunction('CSK_MultiRemoteLiDAR.setViewerType', setViewerType)

local function setViewerActive(status)
  _G.logger:info(nameOfModule .. ": Set viewer active to " .. tostring(status))
  multiRemoteLiDAR_Instances[selectedInstance].parameters.viewerActive = status
  Script.notifyEvent('MultiRemoteLiDAR_OnNewProcessingParameter', selectedInstance, 'viewerActive', status)
end
Script.serveFunction('CSK_MultiRemoteLiDAR.setViewerActive', setViewerActive)

local function setInterface(interface)
  _G.logger:info(nameOfModule .. ": Set interface to " .. interface)
  multiRemoteLiDAR_Instances[selectedInstance].parameters.interface = interface
  Script.notifyEvent('MultiRemoteLiDAR_OnNewStatusInterface', multiRemoteLiDAR_Instances[selectedInstance].parameters.interface)
end
Script.serveFunction('CSK_MultiRemoteLiDAR.setInterface', setInterface)

local function setIP(ip)
  local suc = checkIP(ip)

  if suc then
    Script.notifyEvent("MultiRemoteLiDAR_OnNewStatusIPError", false)
    _G.logger:info(nameOfModule .. ": Set IP to " .. ip)
    multiRemoteLiDAR_Instances[selectedInstance].parameters.ipAddress = ip
  else
    _G.logger:info(nameOfModule .. ": IP is not valid: " .. tostring(ip))
    Script.notifyEvent("MultiRemoteLiDAR_OnNewStatusIPError", true)
  end
end
Script.serveFunction('CSK_MultiRemoteLiDAR.setIP', setIP)

local function setSensorType(sensorType)
  _G.logger:info(nameOfModule .. ": Set sensor type to " .. sensorType)
  multiRemoteLiDAR_Instances[selectedInstance].parameters.sensorType = sensorType
  Script.notifyEvent('MultiRemoteLiDAR_OnNewProcessingParameter', selectedInstance, 'sensorType', multiRemoteLiDAR_Instances[selectedInstance].parameters.sensorType)
end
Script.serveFunction('CSK_MultiRemoteLiDAR.setSensorType', setSensorType)

local function setInternalProcessing(status)
  _G.logger:info(nameOfModule .. ": Set internal processing to " .. tostring(status))
  multiRemoteLiDAR_Instances[selectedInstance].parameters.internalProcessing = status
  if multiRemoteLiDAR_Instances[selectedInstance].parameters.internalProcessing then
    Script.notifyEvent("MultiRemoteLiDAR_OnRegisterLiDARSensor" .. tostring(selectedInstance), multiRemoteLiDAR_Instances[selectedInstance].lidarProvider)
  else
    Script.notifyEvent("MultiRemoteLiDAR_OnDeregisterLiDARSensor" .. tostring(selectedInstance), multiRemoteLiDAR_Instances[selectedInstance].lidarProvider)
  end
end
Script.serveFunction('CSK_MultiRemoteLiDAR.setInternalProcessing', setInternalProcessing)

local function setEncoderMode(status)
  if _G.availableAPIs.encoder then
    _G.logger:info(nameOfModule .. ": Set encoder mode of sensor no. " .. tostring(selectedInstance) .. "to " .. tostring(status))
    multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderMode = status

    if status then
      setViewerType('PointCloud')
    end

    Script.notifyEvent('MultiRemoteLiDAR_OnNewProcessingParameter', selectedInstance, 'encoderMode', status)
  else
    _G.logger:warning(nameOfModule .. ": Related CROWNs for encoder mode not available.")
  end
end
Script.serveFunction('CSK_MultiRemoteLiDAR.setEncoderMode', setEncoderMode)

local function setEncoderTriggerEvent(event)
  _G.logger:info(nameOfModule .. ": Set encoderTriggerEvent to " .. event)
  multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderTriggerEvent = event
  Script.notifyEvent('MultiRemoteLiDAR_OnNewProcessingParameter', selectedInstance, 'encoderTriggerEvent', multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderTriggerEvent)
end
Script.serveFunction('CSK_MultiRemoteLiDAR.setEncoderTriggerEvent', setEncoderTriggerEvent)

local function setEncoderModeLoop(status)
  _G.logger:info(nameOfModule .. ": Set encoder loop mode to " .. tostring(status))
  multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderModeLoop = status
  Script.notifyEvent('MultiRemoteLiDAR_OnNewProcessingParameter', selectedInstance, 'encoderModeLoop', multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderModeLoop)
  Script.notifyEvent('MultiRemoteLiDAR_OnNewStatusEncoderModeLoop', multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderModeLoop)
end
Script.serveFunction('CSK_MultiRemoteLiDAR.setEncoderModeLoop', setEncoderModeLoop)

local function setEncoderDurationMode(mode)
  _G.logger:info(nameOfModule .. ": Set encoderDurationMode to " .. mode)
  multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderDurationMode = mode
  Script.notifyEvent('MultiRemoteLiDAR_OnNewProcessingParameter', selectedInstance, 'encoderDurationMode', multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderDurationMode)
end
Script.serveFunction('CSK_MultiRemoteLiDAR.setEncoderDurationMode', setEncoderDurationMode)

local function setEncoderDurationModeValue(value)
  _G.logger:info(nameOfModule .. ": Set encoderDurationModeValue to " .. value)
  multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderDurationModeValue = value
  Script.notifyEvent('MultiRemoteLiDAR_OnNewProcessingParameter', selectedInstance, 'encoderDurationModeValue', multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderDurationModeValue)
end
Script.serveFunction('CSK_MultiRemoteLiDAR.setEncoderDurationModeValue', setEncoderDurationModeValue)

local function triggerEncoderMeasurement()
  Script.notifyEvent('MultiRemoteLiDAR_OnNewProcessingParameter', selectedInstance, 'triggerEncoderMeasurement', true)
end
Script.serveFunction('CSK_MultiRemoteLiDAR.triggerEncoderMeasurement', triggerEncoderMeasurement)

--------------------------------------------------------------------------------------------

local function startLiDARSensor()
  _G.logger:info(nameOfModule .. ": Start LiDAR sensor no. " .. tostring(selectedInstance))
  multiRemoteLiDAR_Instances[selectedInstance]:startLiDARSensor()
end
Script.serveFunction('CSK_MultiRemoteLiDAR.startLiDARSensor', startLiDARSensor)

local function stopLiDARSensor()
  _G.logger:info(nameOfModule .. ": Stop LiDAR sensor no. " .. tostring(selectedInstance))
  multiRemoteLiDAR_Instances[selectedInstance]:stopLiDARSensor()
end
Script.serveFunction('CSK_MultiRemoteLiDAR.stopLiDARSensor', stopLiDARSensor)

--- Function to update processing parameters within the processing threads
local function updateProcessingParameters()

  Script.notifyEvent('MultiRemoteLiDAR_OnNewProcessingParameter', selectedInstance, 'activeInUI', true)
  Script.notifyEvent('MultiRemoteLiDAR_OnNewProcessingParameter', selectedInstance, 'viewerType', multiRemoteLiDAR_Instances[selectedInstance].parameters.viewerType)
  Script.notifyEvent('MultiRemoteLiDAR_OnNewProcessingParameter', selectedInstance, 'sensorType', multiRemoteLiDAR_Instances[selectedInstance].parameters.sensorType)
  if availableAPIs.encoder then
    Script.notifyEvent('MultiRemoteLiDAR_OnNewProcessingParameter', selectedInstance, 'encoderMode', multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderMode)
    Script.notifyEvent('MultiRemoteLiDAR_OnNewProcessingParameter', selectedInstance, 'encoderModeLoop', multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderModeLoop)
    Script.notifyEvent('MultiRemoteLiDAR_OnNewProcessingParameter', selectedInstance, 'encoderDurationMode', multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderDurationMode)
    Script.notifyEvent('MultiRemoteLiDAR_OnNewProcessingParameter', selectedInstance, 'encoderDurationModeValue', multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderDurationModeValue)
    Script.notifyEvent('MultiRemoteLiDAR_OnNewProcessingParameter', selectedInstance, 'encoderTriggerEvent', multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderTriggerEvent)
  else
    if multiRemoteLiDAR_Instances[selectedInstance].parameters.encoderMode == true then
      _G.logger:warning(nameOfModule .. ": Related CROWNs for encoder mode not available.")
    else
      _G.logger:info(nameOfModule .. ": Related CROWNs for encoder mode not available.")      
    end
  end
end

-- *****************************************************************
-- Following function can be adapted for CSK_PersistentData module usage
-- *****************************************************************

local function setParameterName(name)
  _G.logger:info(nameOfModule .. ": Set parameter name = " .. tostring(name))
  multiRemoteLiDAR_Instances[selectedInstance].parametersName = name
end
Script.serveFunction("CSK_MultiRemoteLiDAR.setParameterName", setParameterName)

local function sendParameters()
  if multiRemoteLiDAR_Instances[selectedInstance].persistentModuleAvailable then
    CSK_PersistentData.addParameter(helperFuncs.convertTable2Container(multiRemoteLiDAR_Instances[selectedInstance].parameters), multiRemoteLiDAR_Instances[selectedInstance].parametersName)

    -- Check if CSK_PersistentData version is >= 3.0.0
    if tonumber(string.sub(CSK_PersistentData.getVersion(), 1, 1)) >= 3 then
      CSK_PersistentData.setModuleParameterName(nameOfModule, multiRemoteLiDAR_Instances[selectedInstance].parametersName, multiRemoteLiDAR_Instances[selectedInstance].parameterLoadOnReboot, tostring(selectedInstance), #multiRemoteLiDAR_Instances)
    else
      CSK_PersistentData.setModuleParameterName(nameOfModule, multiRemoteLiDAR_Instances[selectedInstance].parametersName, multiRemoteLiDAR_Instances[selectedInstance].parameterLoadOnReboot, tostring(selectedInstance))
    end
    _G.logger:info(nameOfModule .. ": Send MultiRemoteLiDAR parameters with name '" .. multiRemoteLiDAR_Instances[selectedInstance].parametersName .. "' to CSK_PersistentData module.")
    CSK_PersistentData.saveData()
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
end
Script.serveFunction("CSK_MultiRemoteLiDAR.sendParameters", sendParameters)

local function loadParameters()
  if multiRemoteLiDAR_Instances[selectedInstance].persistentModuleAvailable then
    local data = CSK_PersistentData.getParameter(multiRemoteLiDAR_Instances[selectedInstance].parametersName)
    if data then
      _G.logger:info(nameOfModule .. ": Loaded parameters for multiRemoteLiDARObject " .. tostring(selectedInstance) .. " from CSK_PersistentData module.")
      multiRemoteLiDAR_Instances[selectedInstance].parameters = helperFuncs.convertContainer2Table(data)

      -- If something needs to be configured/activated with new loaded data
      updateProcessingParameters()

      CSK_MultiRemoteLiDAR.pageCalled()
    else
      _G.logger:warning(nameOfModule .. ": Loading parameters from CSK_PersistentData module did not work.")
    end
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
  tmrMultiRemoteLiDAR:start()
end
Script.serveFunction("CSK_MultiRemoteLiDAR.loadParameters", loadParameters)

local function setLoadOnReboot(status)
  multiRemoteLiDAR_Instances[selectedInstance].parameterLoadOnReboot = status
  _G.logger:info(nameOfModule .. ": Set new status to load setting on reboot: " .. tostring(status))
end
Script.serveFunction("CSK_MultiRemoteLiDAR.setLoadOnReboot", setLoadOnReboot)

--- Function to setup sensors after bootup
local function setupSensorsAfterBootUp()
  _G.logger:info(nameOfModule .. ': Setup sensors after bootUp.')
  local isOneConnected = false
  for i = 1, #multiRemoteLiDAR_Instances do

    if multiRemoteLiDAR_Instances[i].parameterLoadOnReboot then
      CSK_MultiRemoteLiDAR.setSelectedInstance(i)
      CSK_MultiRemoteLiDAR.loadParameters()
      CSK_MultiRemoteLiDAR.startLiDARSensor()
      isOneConnected = true
    end
    disableStartStopOnUI = false
    Script.notifyEvent('MultiRemoteLiDAR_OnActivateStartAndStopLiDAROnUI', disableStartStopOnUI)
  end
  bootUpStatus = false
  Script.notifyEvent('MultiRemoteLiDAR_OnDataLoadedOnReboot')
  CSK_MultiRemoteLiDAR.pageCalled()
end
Timer.register(tmrSensorBootUp, 'OnExpired', setupSensorsAfterBootUp)

--- Function to react on initial load of persistent parameters
local function handleOnInitialDataLoaded()

  _G.logger:info(nameOfModule .. ': Try to initially load parameter from CSK_PersistentData module.')
  if string.sub(CSK_PersistentData.getVersion(), 1, 1) == '1' then

    _G.logger:warning(nameOfModule .. ': CSK_PersistentData module is too old and will not work. Please update CSK_PersistentData module.')

    for j = 1, #multiRemoteLiDAR_Instances do
      multiRemoteLiDAR_Instances[j].persistentModuleAvailable = false
    end
  else

    local bootUpBreak = false

    -- Check if CSK_PersistentData version is >= 3.0.0
    if tonumber(string.sub(CSK_PersistentData.getVersion(), 1, 1)) >= 3 then
      local parameterName, loadOnReboot, totalInstances = CSK_PersistentData.getModuleParameterName(nameOfModule, '1')
      -- Check for amount if instances to create
      if totalInstances then
        local c = 2
        while c <= totalInstances do
          addInstance()
          c = c+1
        end
      end
    end

    for i = 1, #multiRemoteLiDAR_Instances do
      local parameterName, loadOnReboot = CSK_PersistentData.getModuleParameterName(nameOfModule, tostring(i))

      if parameterName then
        multiRemoteLiDAR_Instances[i].parametersName = parameterName
        multiRemoteLiDAR_Instances[i].parameterLoadOnReboot = loadOnReboot
      end

      if multiRemoteLiDAR_Instances[i].parameterLoadOnReboot then
        bootUpBreak = true
      end
    end

    if bootUpBreak then
      _G.logger:info(nameOfModule .. ": Wait for sensor(s) power bootUp")

      tmrSensorBootUp:start()
      bootUpStatus = true

    else
      setupSensorsAfterBootUp()
    end
  end
end
Script.register("CSK_PersistentData.OnInitialDataLoaded", handleOnInitialDataLoaded)

return funcs

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************

