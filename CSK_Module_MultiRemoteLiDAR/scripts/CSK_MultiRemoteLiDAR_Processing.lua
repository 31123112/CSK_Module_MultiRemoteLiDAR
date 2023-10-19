---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

-- If App property "LuaLoadAllEngineAPI" is FALSE, use this to load and check for required APIs
-- This can improve performance of garbage collection
local availableAPIs = require('Sensors/MultiRemoteLiDAR/helper/checkAPIs') -- check for available APIs
-----------------------------------------------------------
local nameOfModule = 'CSK_MultiRemoteLiDAR'
--Logger
_G.logger = Log.SharedLogger.create('ModuleLogger')

local scriptParams = Script.getStartArgument() -- Get parameters from model

local lidarInstanceNumber = scriptParams:get('multiRemoteLiDARInstanceNumber') -- number of this instance
local lidarInstanceNumberString = tostring(lidarInstanceNumber) -- number of this instance as string
local viewerID = 'multiRemoteLiDARViewer' .. lidarInstanceNumberString --scriptParams:get('viewerID')
local scanViewerID = 'multiRemoteLiDARScanViewer' .. lidarInstanceNumberString --scriptParams:get('viewerID')
local profileViewerID = 'multiRemoteLiDARProfileViewer' .. lidarInstanceNumberString --scriptParams:get('viewerID')
local beamCounter = 1
local fullPc
local encoderCycle = false

-- Event to notify result of processing
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewResult' .. lidarInstanceNumberString,'MultiRemoteLiDAR_OnNewResult' .. lidarInstanceNumberString,'bool') -- Edit this accordingly
-- Event to forward content from this thread to Controler to show e.g. on UI
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewValueToForward' .. lidarInstanceNumberString,'MultiRemoteLiDAR_OnNewValueToForward' .. lidarInstanceNumberString,'string, auto')
-- Event to forward update of e.g. parameter update to keep data in sync between threads
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewValueUpdate' .. lidarInstanceNumberString,'MultiRemoteLiDAR_OnNewValueUpdate' .. lidarInstanceNumberString,'int, string, auto, int:?')
-- Event to forward collected scan data merged with encoder info
Script.serveEvent('CSK_MultiRemoteLiDAR.OnNewEncoderScan' .. lidarInstanceNumberString,'MultiRemoteLiDAR_OnNewEncoderScan' .. lidarInstanceNumberString,'object:1:PointCloud')

local processingParams = {}
processingParams.activeInUI = false -- Is this instance currently selected in UI
processingParams.viewerActive = scriptParams:get('viewerActive') -- Should the scan be shown in viewer
processingParams.viewerType = scriptParams:get('viewerType') -- What kind of data type to use for the scans
processingParams.sensorType = scriptParams:get('sensorType') -- What kind of LiDAR sensor type
processingParams.encoderMode = scriptParams:get('encoderMode') -- Combine scan data with encoder data to create point cloud
processingParams.encoderModeLoop = scriptParams:get('encoderModeLoop') -- Should it retrigger the encoder measurement automatically
processingParams.encoderDurationMode = scriptParams:get('encoderDurationMode') -- Encoder trigger mode
processingParams.encoderDurationModeValue =
  scriptParams:get('encoderDurationModeValue') -- Related to encoderDurationMode, value to determine how long LiDAR data should be collected combined with encoder data before providing PointCloud
processingParams.encoderTriggerEvent = scriptParams:get('encoderTriggerEvent') -- Event to start encoder scan if notified

-- NEW
processingParams.filter = {}

processingParams.filter.angleFilter = {}
processingParams.filter.angleFilter.enable =
  scriptParams:get('angleFilterEnable')
processingParams.filter.angleFilter.startAngle =
  scriptParams:get('angleFilterStartAngle')
processingParams.filter.angleFilter.stopAngle =
  scriptParams:get('angleFilterStopAngle')

processingParams.filter.meanFilter = {}
processingParams.filter.meanFilter.enableScanDepth =
  scriptParams:get('meanFilterEnableScanDepth')
processingParams.filter.meanFilter.enableBeamsWidth =
  scriptParams:get('meanFilterEnableBeamsWidth')
processingParams.filter.meanFilter.scanDepth =
  scriptParams:get('meanFilterScanDepth')
processingParams.filter.meanFilter.beamsWidth =
  scriptParams:get('meanFilterBeamsWidth')

processingParams.filter.resolutionHalving = {}
processingParams.filter.resolutionHalving.enable =
  scriptParams:get('resolutionHalvingEnable')

processingParams.measuring = {}
processingParams.measuring.edgeDetection = {}
processingParams.measuring.edgeDetection.enable =
  scriptParams:get('edgeDetectionEnable')
processingParams.measuring.edgeDetection.gabThreshold =
  scriptParams:get('edgeDetectionGabThreshold')
processingParams.measuring.edgeDetection.gradientThreshold =
  scriptParams:get('edgeDetectionGradientThreshold')

processingParams.measuring.fixedPoint = {}
processingParams.measuring.fixedPoint.enable =
  scriptParams:get('fixedPointEnable')
processingParams.measuring.fixedPoint.scanAngleA =
  scriptParams:get('fixedPointScanAngleA')
processingParams.measuring.fixedPoint.scanAngleB =
  scriptParams:get('fixedPointScanAngleB')

local viewer = View.create() -- Viewer to show scan as PointCloud
viewer:setID(viewerID)

local profileViewer = View.create()
profileViewer:setID("Profile")

local scanViewer = View.create() -- Viewer to show Scan
scanViewer:setID(scanViewerID)

local scanQueue = Script.Queue.create() -- Queue to stop processing if increasing too much
scanQueue:setPriority('MID')
scanQueue:setMaxQueueSize(1)

local scanDecos = {}

for i = 1, 4 do
  local deco = View.ScanDecoration.create()
  deco:setPointSize(4)
  deco:setColor(i * 50, i * 50, i * 50)
  table.insert(scanDecos, deco)
end

local transformer = Scan.Transform.create()

local mergedPointCloud = PointCloud.create('INTENSITY')
local encoderScanTrans = Scan.Transform.create()
local doEncoderMeasurement = false
local encoderHandle = nil

local incOffset = 0
local latestInc = 0

local pcDeco = View.PointCloudDecoration.create()
pcDeco:setPointSize(5)

local pcCollector = PointCloud.Collector.create()

local profileDecoRed = View.GraphDecoration.create()
profileDecoRed:setGridVisible(true)
profileDecoRed:setDrawSize(10)
profileDecoRed:setAxisVisible(true)
profileDecoRed:setGraphColor(255,0,0,255)

local filter = {}

filter.angleFilter = Scan.AngleRangeFilter.create()
filter.angleFilter:setThetaRange(math.rad(tonumber(processingParams.filter.angleFilter.startAngle)), math.rad(tonumber(processingParams.filter.angleFilter.stopAngle)))
filter.angleFilter:setEnabled(true)


--- Function to trigger new scan measurement merged with encoder data
local function triggerEncoderMeasurement()
  viewer:clear()
  viewer:present()
  mergedPointCloud = PointCloud.create('INTENSITY')
  incOffset = encoderHandle:getCurrentIncrement()
  encoderCycle = false
  doEncoderMeasurement = true
end

local function encoderMode(scan)
  if doEncoderMeasurement then
    -- Continue encoder measurement
    local actualInc = encoderHandle:getCurrentIncrement()
    -- Check if inc differs
    if actualInc ~= latestInc then
      -- Check if encoder counter was reset after full cycle
      if latestInc >= 4294900000 and actualInc <= 100000 then
        encoderCycle = true
      end
      latestInc = actualInc
      local incPos
      if encoderCycle then
        incPos = (actualInc + 4294967295) - incOffset
      else
        incPos = actualInc - incOffset
      end
      if processingParams.encoderDurationMode == 'TICKS' then
        if incPos >= processingParams.encoderDurationModeValue then
          doEncoderMeasurement = false
          Script.notifyEvent(
            'MultiRemoteLiDAR_OnNewEncoderScan' .. lidarInstanceNumberString,
            mergedPointCloud
          )
          if processingParams.encoderModeLoop then
            triggerEncoderMeasurement()
          end
          return
        end

        encoderScanTrans:setPosition(0, 0, incPos)
        local pc = encoderScanTrans:transformToPointCloud(scan)
        PointCloud.mergeInplace(mergedPointCloud, pc)

        local pcSize = PointCloud.getSize(mergedPointCloud)

        if processingParams.viewerActive then
          viewer:addPointCloud(mergedPointCloud, pcDeco, 'pc')
          viewer:present('LIVE')
        end
      end
    end
  end
end
--- Function to process scans
---@param scan Scan Incoming scan to process
local function handleOnNewProcessing(scan)
  _G.logger:info(nameOfModule .. ': Check scan on instance No.' .. lidarInstanceNumberString) -- for debugging
  
  -------------
  --filtering

  if processingParams.filter.angleFilter.enable then
    scan = filter.angleFilter:filter(scan)
    print("anglefilter active")
  end
  -----------

  if processingParams.encoderMode then
    encoderMode(scan)

  elseif processingParams.viewerType == 'PointCloud' then
    local pc = transformer:transformToPointCloud(scan)
    if processingParams.sensorType == 'MRS1000' then
      if beamCounter <= 4 then
        pcCollector:collect(pc, true)
        beamCounter = beamCounter + 1
      else
        fullPc = pcCollector:collect(pc, false)
        if processingParams.viewerActive then
          viewer:addPointCloud(fullPc, pcDeco)
          viewer:present()
        end
        beamCounter = 1
      end
    else
      if processingParams.viewerActive then
        print("test")
        viewer:addPointCloud(pc, pcDeco, 'pc1')
        viewer:present()
      end
    end
  elseif processingParams.viewerType == 'Scan' then
    if processingParams.sensorType == 'MRS1000' then
      if processingParams.viewerActive then
        scanViewer:addScan(scan,scanDecos[beamCounter],'scan' .. tostring(beamCounter))
        scanViewer:present()
      end
      beamCounter = beamCounter + 1
      if beamCounter >= 5 then
        beamCounter = 1
      end
    else
      if processingParams.viewerActive then
        print("Test scan")
        scanViewer:addScan(scan, scanDecos[1], 'scan1')
        scanViewer:present()
      end
    end
  else --Profile
    print("profile")
    local profile = Scan.toProfile(scan, 'DISTANCE', 0)
    
    profileViewer:addProfile(profile, profileDecoRed, "profile")
    profileViewer:present()
  end

  -- Insert processing part
  -- E.g.
  --[[

  local result = someProcessingFunctions(scan)

  -- ...

  Script.notifyEvent("MultiRemoteLiDAR_OnNewValueUpdate" .. lidarInstanceNumberString, lidarInstanceNumber, 'valueName', result, processingParams.selectedObject)

  --_G.logger:info(nameOfModule .. ": Processing on MultiRemoteLiDAR" .. lidarInstanceNumberString .. " was = " .. tostring(result))
  --Script.notifyEvent('MultiRemoteLiDAR_OnNewResult'.. lidarInstanceNumberString, true)

  --Script.notifyEvent("MultiRemoteLiDAR_OnNewValueToForward" .. lidarInstanceNumberString, 'MultiColorSelection_CustomEventName', 'content')
  ]]
end
--Script.serveFunction("CSK_MultiRemoteLiDAR.processInstance"..lidarInstanceNumberString, handleOnNewProcessing, 'object:?:Alias', 'bool:?') -- Edit this according to this function

--- Function to register on "OnNewScan"-event of LiDAR provider
---@param lidarSensor handle Scan Provider
local function registerLiDARSensor(lidarSensor)
  _G.logger:info(
    nameOfModule .. ': Register LiDAR sensor ' .. lidarInstanceNumberString
  )

  -- Make sure to not double registering to OnNewScan event
  Scan.Provider.RemoteScanner.deregister(
    lidarSensor,
    'OnNewScan',
    handleOnNewProcessing
  )
  Scan.Provider.RemoteScanner.register(
    lidarSensor,
    'OnNewScan',
    handleOnNewProcessing
  )

  scanQueue:setFunction(handleOnNewProcessing)
  Script.releaseObject(lidarSensor)
end
Script.register(
  'CSK_MultiRemoteLiDAR.OnRegisterLiDARSensor' .. lidarInstanceNumberString,
  registerLiDARSensor
)

--- Function to deregister on "OnNewScan"-event of lidar provider
---@param lidarSensor handle Scan Provider
local function deregisterLiDARSensor(lidarSensor)
  _G.logger:info(
    nameOfModule .. ': DeRegister LiDAR sensor ' .. lidarInstanceNumberString
  )
  Scan.Provider.RemoteScanner.deregister(
    lidarSensor,
    'OnNewScan',
    handleOnNewProcessing
  )
  scanQueue:clear()
  Script.releaseObject(lidarSensor)
end
Script.register(
  'CSK_MultiRemoteLiDAR.OnDeregisterLiDARSensor' .. lidarInstanceNumberString,
  deregisterLiDARSensor
)

-- Function to handle updates of processing parameters from Controller
---@param multiRemoteLiDARNo int Number of scanner instance to update
---@param parameter string Parameter to update
---@param value auto Value of parameter to update
local function handleOnNewProcessingParameter(multiRemoteLiDARNo,parameter,value)
  if multiRemoteLiDARNo == lidarInstanceNumber then -- set parameter only in selected script
    _G.logger:info(
      nameOfModule ..
        ": Update parameter '" ..
          parameter ..
            "' of multiRemoteLiDARInstanceNo." ..
              tostring(multiRemoteLiDARNo) .. ' to value = ' .. tostring(value)
    )

    if parameter == 'encoderMode' then
      processingParams[parameter] = value
      if value == true then
        if encoderHandle then
          Script.releaseObject(encoderHandle)
          encoderHandle = nil
        end
        encoderHandle = CSK_Encoder.getEncoderHandle()
        triggerEncoderMeasurement()
      end
    elseif parameter == 'triggerEncoderMeasurement' then
      triggerEncoderMeasurement()
    elseif parameter == 'encoderModeLoop' then
      processingParams[parameter] = value
      if value == true then
        triggerEncoderMeasurement()
      end
    elseif parameter == 'encoderTriggerEvent' then
      _G.logger:info(nameOfModule ..': Register instance ' ..lidarInstanceNumberString .. ' on event ' .. value)
      if processingParams.encoderTriggerEvent ~= '' then
        Script.deregister(processingParams.encoderTriggerEvent,triggerEncoderMeasurement)
      end
      processingParams.encoderTriggerEvent = value
      Script.register(value, triggerEncoderMeasurement)
    else
      if parameter == 'AngleFilterStartAngle' then
        processingParams.filter.angleFilter.startAngle = value
        _G.logger:info('instance ' ..lidarInstanceNumberString .. ' on new Anglefilter ' .. tostring(processingParams.filter.angleFilter.startAngle))
        filter.angleFilter:setThetaRange(math.rad(tonumber(processingParams.filter.angleFilter.startAngle)), math.rad(tonumber(processingParams.filter.angleFilter.stopAngle)))
      elseif parameter == 'AngleFilterStopAngle' then
        processingParams.filter.angleFilter.stopAngle = value
        _G.logger:info('instance ' ..lidarInstanceNumberString .. ' on new Anglefilter ' .. tostring(processingParams.filter.angleFilter.stopAngle))
        filter.angleFilter:setThetaRange(processingParams.filter.angleFilter.startAngle, processingParams.filter.angleFilter.stopAngle)
      elseif parameter == 'AngleFilterEnable' then
        _G.logger:info('instance ' ..lidarInstanceNumberString .. ' on new Anglefilter enable state ' .. tostring(value))
        processingParams.filter.angleFilter.enable = value
      end
      if parameter == 'viewerActive' and value == false then
        viewer:clear()
        viewer:present()
      end
    end
  elseif parameter == 'activeInUI' then
    processingParams[parameter] = false
  end
end
Script.register('CSK_MultiRemoteLiDAR.OnNewProcessingParameter',handleOnNewProcessingParameter)
