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

local fitterHandle = PointCloud.ShapeFitter.create()
fitterHandle:setOptimizeCoefficients(true)
fitterHandle:setDistanceThreshold(15)
fitterHandle:setMaxIterations(100) --default 100
fitterHandle:setProbability(0.90)

local scanDecos = {}

for i = 1, 4 do
  local deco = View.ScanDecoration.create()
  deco:setPointSize(4)
  deco:setColor(i * 50, i * 50, i * 50)
  table.insert(scanDecos, deco)
end

local shapeDecos = {}

shapeDecos.red = View.ShapeDecoration.create()
shapeDecos.red:setFillColor(255,0,0, 150)
shapeDecos.red:setLineColor(255,0,0, 150)
shapeDecos.red:setPointSize(25)

shapeDecos.lightRed = View.ShapeDecoration.create()
shapeDecos.lightRed:setFillColor(180,0,0, 150)
shapeDecos.lightRed:setLineColor(180,0,0, 150)
shapeDecos.lightRed:setPointSize(25)

shapeDecos.green = View.ShapeDecoration.create()
shapeDecos.green:setFillColor(0,255,0, 150)
shapeDecos.green:setLineColor(0,255,0, 150)
shapeDecos.green:setPointSize(25)

shapeDecos.lightGreen = View.ShapeDecoration.create()
shapeDecos.lightGreen:setFillColor(0,180,0, 150)
shapeDecos.lightGreen:setLineColor(0,180,0, 150)
shapeDecos.lightGreen:setPointSize(25)

shapeDecos.blue = View.ShapeDecoration.create()
shapeDecos.blue:setFillColor(0,0,255, 150)
shapeDecos.blue:setLineColor(0,0,255, 150)
shapeDecos.blue:setPointSize(25)

shapeDecos.lightBlue = View.ShapeDecoration.create()
shapeDecos.lightBlue:setFillColor(0,0,180, 100)
shapeDecos.lightBlue:setLineColor(0,0,180, 100)
shapeDecos.lightBlue:setPointSize(25)

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
filter.angleFilter:setEnabled(processingParams.filter.angleFilter.enable)

filter.meanFilter = Scan.MeanFilter.create()
filter.meanFilter:setAverageDepth(tonumber(processingParams.filter.meanFilter.scanDepth))
filter.meanFilter:setEnabled(processingParams.filter.meanFilter.enableScanDepth)



--- Function to trigger new scan measurement merged with encoder data
local function triggerEncoderMeasurement()
  viewer:clear()
  viewer:present()
  mergedPointCloud = PointCloud.create('INTENSITY')
  incOffset = encoderHandle:getCurrentIncrement()
  encoderCycle = false
  doEncoderMeasurement = true
end

local function measure(pointCloud, direction)
  local testPointcloud = PointCloud.create('INTENSITY')
  local xPoint,yPoint,zPoint,intensityPoint = pointCloud:getPoint(0) -- punkt 1
  if direction == "up" then
    xPoint,yPoint,zPoint,intensityPoint = pointCloud:getPoint(0) -- punkt 1
  elseif direction == "down" then
    xPoint,yPoint,zPoint,intensityPoint = pointCloud:getPoint(pointCloud:getSize()-1) -- punkt 1
  end
  testPointcloud:appendPoint(xPoint, yPoint, zPoint, intensityPoint) -- punkt 1 in PointCloud einfügen

  xPoint,yPoint,zPoint,intensityPoint = pointCloud:getPoint(1) -- punkt 1
  if direction == "up" then
    xPoint,yPoint,zPoint,intensityPoint = pointCloud:getPoint(1) -- punkt 1
  elseif direction == "down" then
    xPoint,yPoint,zPoint,intensityPoint = pointCloud:getPoint(pointCloud:getSize()-2) -- punkt 1
  end
  testPointcloud:appendPoint(xPoint, yPoint, zPoint, intensityPoint) -- punkt 1 in PointCloud einfügen

  local outputPointcloud = PointCloud.create('INTENSITY')
  local enablePoint = true
  local indexCornerPoint = 2
  local cornerPoint = nil
  local lineErrektor,_ = PointCloud.ShapeFitter.fitLine(fitterHandle, testPointcloud)
  for i = 2, pointCloud:getSize() - 2 do
    if enablePoint then
      if direction == "up" then
        xPoint,yPoint,zPoint,intensityPoint = pointCloud:getPoint(i)
      elseif direction == "down" then
        xPoint,yPoint,zPoint,intensityPoint = pointCloud:getPoint(pointCloud:getSize() - i)
      end
      local testPoint = Point.create(xPoint,yPoint,zPoint)
      local lastPointX, _,_,_ = PointCloud.getPoint(testPointcloud, i-1)
      if math.abs(Point.getDistanceToLine(testPoint, lineErrektor)) < processingParams.measuring.edgeDetection.gradientThreshold then
        testPointcloud:appendPoint(xPoint, yPoint, zPoint, intensityPoint)
        indexCornerPoint = i
        outputPointcloud:appendPoint(xPoint+100,yPoint,zPoint,intensityPoint)
        lineErrektor,_ = PointCloud.ShapeFitter.fitLine(fitterHandle, testPointcloud)
      else
        if direction == "up" then
          xPoint,yPoint,zPoint,intensityPoint = pointCloud:getPoint(i+1)
        elseif direction == "down" then
          xPoint,yPoint,zPoint,intensityPoint = pointCloud:getPoint(pointCloud:getSize() - (i+1))
        end
        testPoint = Point.create(xPoint,yPoint,zPoint)
        if math.abs(Point.getDistanceToLine(testPoint, lineErrektor)) > processingParams.measuring.edgeDetection.gradientThreshold then
          if direction == "up" then
            xPoint,yPoint,zPoint,intensityPoint = pointCloud:getPoint(i-1)
          elseif direction == "down" then
            if i > 2 then
              xPoint,yPoint,zPoint,intensityPoint = pointCloud:getPoint(pointCloud:getSize() - (i-1))
              
            else
              xPoint,yPoint,zPoint,intensityPoint = pointCloud:getPoint(pointCloud:getSize() - (i))
            end
          end
          if lineErrektor then
            cornerPoint = Shape3D.getClosestSurfacePoint(lineErrektor, Point.create(xPoint, yPoint, zPoint)) -- letzter punkt = Eckpunkt
          else
            cornerPoint = Point.create(xPoint, yPoint, zPoint) -- letzter punkt = Eckpunkt
          end
          
          enablePoint = false
        else
          print("only a peak by" .. tostring(i) .. "/" .. tostring(pointCloud:getSize()-1))
          testPointcloud:appendPoint(xPoint, yPoint, zPoint, intensityPoint)
          outputPointcloud:appendPoint(xPoint+100,yPoint,zPoint,intensityPoint)
        end
      end
    else
      return outputPointcloud, cornerPoint
    end
  end
  return outputPointcloud, cornerPoint
end

local function edgeDetection(pointcloud, gradientThreshold, gabThreshold)
  local edgeDetectionGab, edgeDetectionHeight, edgeDetectionAngle = nil, nil, nil
  local pcA, cornerPointA= measure(pointcloud,"up")
  local pcB, cornerPointB = measure(pointcloud,"down")

  local x,y,z,_ = PointCloud.getPoint(pointcloud, 0)
  local startPoint = Point.create(x,y,z)
  local size, width, height = pointcloud:getSize()
  x,y,z,_ = PointCloud.getPoint(pointcloud, size-1)
  local stoppPoint = Point.create(x,y,z)

  if cornerPointA and cornerPointB then
    if cornerPointA:getY() <= 0 and cornerPointB:getY() <=0 then
      edgeDetectionGab = math.abs(math.abs(cornerPointA:getY()) - math.abs(cornerPointA:getY()))
    elseif (cornerPointA:getY() <= 0 and cornerPointB:getY() >=0) or (cornerPointA:getY() >= 0 and cornerPointB:getY() <=0) then
      edgeDetectionGab = math.abs(math.abs(cornerPointA:getY()) + math.abs(cornerPointB:getY()))
    else
      edgeDetectionGab = math.abs(math.abs(cornerPointA:getY()) - math.abs(cornerPointB:getY()) )
    end
    edgeDetectionHeight = math.abs(cornerPointA:getX()) - math.abs(cornerPointB:getX())
    local correctionGab = (math.sin(math.rad(1))*cornerPointA:getX())/2
    edgeDetectionGab = edgeDetectionGab - correctionGab

    if edgeDetectionGab < gabThreshold then
      edgeDetectionGab = -9999
      edgeDetectionHeight = -9999
    end
    --angle
    local mErrektor, mTuebbing, zaehler
    if cornerPointErrektor and cornerPointTuebbing then
      if startPoint:getY() < 0 and cornerPointB:getY() < 0 then
        zaehler = (math.abs(  startPoint:getY() ) - math.abs( cornerPointB:getY()  ))
      elseif startPoint:getY() < 0 and cornerPointB:getY() > 0 then
        zaehler = math.abs( startPoint:getY() - cornerPointB:getY() )
      elseif startPoint:getY() > 0 and cornerPointB:getY() < 0 then
        zaehler = startPoint:getY() - cornerPointB:getY()
      elseif startPoint:getY() > 0 and cornerPointB:getY() > 0 then
        zaehler = (startPoint:getY() - cornerPointB:getY())
      end
              
      if zaehler == 0 then
        mErrektor = 0
      else
        mErrektor =(startPoint:getX() - cornerPointErrektor:getX()) / zaehler
      end
      print(mErrektor)
      if cornerPointA:getY() < 0 and stoppPoint:getY() < 0 then
        zaehler = (math.abs(  cornerPointA:getY() ) - math.abs( stoppPoint:getY()  ))
      elseif cornerPointA:getY() < 0 and stoppPoint:getY() > 0 then
        zaehler = math.abs( cornerPointA:getY() - stoppPoint:getY() )
      elseif cornerPointA:getY() > 0 and stoppPoint:getY() < 0 then
        zaehler = cornerPointA:getY() - stoppPoint:getY()
      elseif cornerPointA:getY() > 0 and stoppPoint:getY() > 0 then
        zaehler = (cornerPointA:getY() - stoppPoint:getY())
      end

      if zaehler == 0 then
        mErrektor = 0
      else
        mTuebbing =(cornerPointTuebbing:getX() - stoppPoint:getX()) / zaehler
      end

      local nenner = (mTuebbing - mErrektor)
      zaehler = (1 + (mErrektor * mTuebbing))
      edgeDetectionAngle = math.deg(math.atan(math.abs(nenner /zaehler )))
      print("Angle : " .. tostring(angle))
    end
  end
  return edgeDetectionGab, edgeDetectionHeight, edgeDetectionAngle, cornerPointA, cornerPointB
end

local function fixedPoint(pointcloud, scanAngleA, scanAngleB)
  local fixedPointHeight = nil

  return fixedPointHeight
end

local function meanFilterBeamsWidth(pc)
  -- local size = Scan.getBeamCount(scan)
  -- -- erster Beam
  -- local distance, theta, phi = Scan.getPoint(scan, 0)
  -- local distanceN1, thetaN1, phiN1 = Scan.getPoint(scan, 0+1)
  -- local distanceN2, thetaN2, phiN2 = Scan.getPoint(scan, 0+2)
  -- local meanDistance = ( distance + distanceN1 + distanceN2 ) /3
  -- Scan.setPoint(scan, 0, 0, meanDistance, theta, phi)

  -- for i=0, (size -3) do
  --   -- alle weiteren Beams
  --   local distance, theta, phi = Scan.getPoint(scan, i)
  --   local distanceN1, thetaN1, phiN1 = Scan.getPoint(scan, i+1)
  --   local distanceN2, thetaN2, phiN2 = Scan.getPoint(scan, i+2)
  --   local meanDistance = ( distance + distanceN1 + distanceN2 ) /3
  --   Scan.setPoint(scan, i+1, i+1, meanDistance, thetaN1, phiN1)
  -- end

  -- -- letzter Beam
  -- local distance, theta, phi = Scan.getPoint(scan, size - 3)
  -- local distanceN1, thetaN1, phiN1 = Scan.getPoint(scan, size - 2)
  -- local distanceN2, thetaN2, phiN2 = Scan.getPoint(scan, size - 1)
  -- local meanDistance = ( distance + distanceN1 + distanceN2 ) /3
  -- Scan.setPoint(scan, size-1, size -1, meanDistance, thetaN2, phiN2)

  local filteredPC = PointCloud.create()
  local bx,cx
  local size = ( pc:getSize() -1)
  for i=1, size do
    local ax,ay = pc:getPoint(i)
      if i < size  then
        bx,_ = pc:getPoint(i-1)
        cx,_= pc:getPoint(i+1)
      else
        bx,_ = pc:getPoint(i-1)
        cx,_ = pc:getPoint(i-2)
      end
    local mean = (ax + bx + cx ) /3
    PointCloud.appendPoint(filteredPC,mean, ay, 0, 50)
  end
  local pc = nil
  pc = PointCloud.clone(filteredPC)

  return pc
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
  
  
  -------------
  --angle filter
  scan = filter.angleFilter:filter(scan)

  --mean filter scans depth
  scan = filter.meanFilter:filter(scan)
  -----------
  if scan then
    _G.logger:info(nameOfModule .. ': new scan on instance No.' .. lidarInstanceNumberString) -- for debugging
    if processingParams.encoderMode then
      encoderMode(scan)

    elseif processingParams.viewerType == 'PointCloud' then
      local pc = transformer:transformToPointCloud(scan)
      -- mean filter beams width
      if processingParams.filter.meanFilter.enableBeamsWidth then
        pc = meanFilterBeamsWidth(pc)
      end

      if processingParams.filter.resolutionHalving.enable then
          local filteredPC = PointCloud.create()
          local k =0
          local factor =2
          while k <= (pc:getSize()-1) do
            filteredPC:appendPoint(pc:getPoint(k))
            k=k+factor
          end
          pc = filteredPC
      end


      --------------------------------------------------------------------------------------
      --measuring

      local edgeDetectionGab, edgeDetectionHeight, edgeDetectionAngle, cornerPointA, cornerPointB = nil, nil, nil, nil, nil
      print("here")
      if processingParams.measuring.edgeDetection.enable then
        print("edge-detection")
        edgeDetectionGab, edgeDetectionHeight, edgeDetectionAngle, cornerPointA, cornerPointB = edgeDetection(pc, processingParams.measuring.edgeDetection.gradientThreshold, processingParams.measuring.edgeDetection.gabThreshold)
        print(edgeDetectionGab, edgeDetectionHeight, edgeDetectionAngle)
      end

      local fixedPointHeight = nil

      if processingParams.measuring.fixedPoint.enable then
        fixedPointHeight = fixedPoint(pc, processingParams.measuring.fixedPoint.scanAngleA, processingParams.measuring.fixedPoint.scanAngleB)
      end




      -------------------------------------------------------------------------------------



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
          viewer:addPointCloud(pc, pcDeco, 'pc1')
          --add viewer points
          if cornerPointA and cornerPointB and processingParams.measuring.edgeDetection.enable then
            viewer:addPoint(cornerPointA, shapeDecos.blue, "cornerPointA")
            viewer:addPoint(cornerPointB, shapeDecos.lightBlue, "cornerPointB")
          end
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
  end
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
      --angle filter
      if parameter == 'AngleFilterStartAngle' then
        processingParams.filter.angleFilter.startAngle = value
        _G.logger:info('instance ' ..lidarInstanceNumberString .. ' on new Anglefilter ' .. tostring(processingParams.filter.angleFilter.startAngle))
        filter.angleFilter:setThetaRange(math.rad(tonumber(processingParams.filter.angleFilter.startAngle)), math.rad(tonumber(processingParams.filter.angleFilter.stopAngle)))
      elseif parameter == 'AngleFilterStopAngle' then
        processingParams.filter.angleFilter.stopAngle = value
        _G.logger:info('instance ' ..lidarInstanceNumberString .. ' on new Anglefilter ' .. tostring(processingParams.filter.angleFilter.stopAngle))
        filter.angleFilter:setThetaRange(math.rad(tonumber(processingParams.filter.angleFilter.startAngle)), math.rad(tonumber(processingParams.filter.angleFilter.stopAngle)))
      elseif parameter == 'AngleFilterEnable' then
        _G.logger:info('instance ' ..lidarInstanceNumberString .. ' on new Anglefilter enable state ' .. tostring(value))
        processingParams.filter.angleFilter.enable = value
        filter.angleFilter:setEnabled(processingParams.filter.angleFilter.enable)
      -- mean filter
      elseif parameter == 'MeanFilterScanDepthEnable' then
        _G.logger:info('instance ' ..lidarInstanceNumberString .. ' on new mean filter scan depth ' .. tostring(value))
        processingParams.filter.meanFilter.enableScanDepth = value
        filter.meanFilter:setEnabled(processingParams.filter.meanFilter.enableScanDepth)
      elseif parameter == 'MeanFilterScanDepth' then
        _G.logger:info('instance ' ..lidarInstanceNumberString .. ' on new mean filter scan depth ' .. tostring(value))
        processingParams.filter.meanFilter.scanDepth = value
        filter.meanFilter:setAverageDepth(tonumber(processingParams.filter.meanFilter.scanDepth))
      elseif parameter == 'MeanFilterBeamsWidthEnable' then
        _G.logger:info('instance ' ..lidarInstanceNumberString .. ' on new mean filter beams width ' .. tostring(value))
        processingParams.filter.meanFilter.enableBeamsWidth = value
      elseif parameter == 'MeanFilterBeamsWidth' then
        _G.logger:info('instance ' ..lidarInstanceNumberString .. ' on new mean filter beams width ' .. tostring(value))
        processingParams.filter.meanFilter.beamsWidth = value
      --resolution halving
      elseif parameter == 'ResolutionHalvingEnabled' then
        _G.logger:info('instance ' ..lidarInstanceNumberString .. ' on resolution halving enabled ' .. tostring(value))
        processingParams.filter.resolutionHalving.enable = value
      -- measure
      elseif parameter == 'EdgeDetectionEnabled' then
        _G.logger:info('instance ' ..lidarInstanceNumberString .. ' on edge detection enabled ' .. tostring(value))
        processingParams.measuring.edgeDetection.enable = value
      elseif parameter == 'EdgeDetectionGabThreshold' then
        _G.logger:info('instance ' ..lidarInstanceNumberString .. ' on new edge detection gab threshold ' .. tostring(value))
        processingParams.measuring.edgeDetection.gabThreshold = tonumber(value)
      elseif parameter == 'EdgeDetectionGradientThreshold' then
        _G.logger:info('instance ' ..lidarInstanceNumberString .. ' on new edge detection gradient threshold ' .. tostring(value))
        processingParams.measuring.edgeDetection.gradientThreshold = tonumber(value)
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
