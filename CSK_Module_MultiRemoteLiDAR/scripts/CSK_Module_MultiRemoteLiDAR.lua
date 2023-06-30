--MIT License
--
--Copyright (c) 2023 SICK AG
--
--Permission is hereby granted, free of charge, to any person obtaining a copy
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--copies of the Software, and to permit persons to whom the Software is
--furnished to do so, subject to the following conditions:
--
--The above copyright notice and this permission notice shall be included in all
--copies or substantial portions of the Software.
--
--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--SOFTWARE.

---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************

-- If app property "LuaLoadAllEngineAPI" is FALSE, use this to load and check for required APIs
-- This can improve performance of garbage collection
_G.availableAPIs = require('Sensors/MultiRemoteLiDAR/helper/checkAPIs') -- can be used to adjust function scope of the module related on available APIs of the device
-----------------------------------------------------------
-- Logger
_G.logger = Log.SharedLogger.create('ModuleLogger')
_G.logHandle = Log.Handler.create()
_G.logHandle:attachToSharedLogger('ModuleLogger')
_G.logHandle:setConsoleSinkEnabled(false) --> Set to TRUE if CSK_Logger module is not used
_G.logHandle:setLevel("ALL")
_G.logHandle:applyConfig()
-----------------------------------------------------------

-- Loading script regarding MultiRemoteLiDAR_Model
-- Check this script regarding MultiRemoteLiDAR_Model parameters and functions
local multiRemoteLiDAR_Model = require('Sensors/MultiRemoteLiDAR/MultiRemoteLiDAR_Model')

local multiRemoteLiDAR_Instances = {} -- Handle all instances
table.insert(multiRemoteLiDAR_Instances, multiRemoteLiDAR_Model.create(1)) -- Create at least 1 instance

-- Load script to communicate with the MultiRemoteLiDAR_Model UI
-- Check / edit this script to see/edit functions which communicate with the UI
local multiRemoteLiDARController = require('Sensors/MultiRemoteLiDAR/MultiRemoteLiDAR_Controller')
multiRemoteLiDARController.setMultiRemoteLiDAR_Instances_Handle(multiRemoteLiDAR_Instances) -- share handle of instances

--**************************************************************************
--**********************End Global Scope ***********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--- Function to react on startup event of the app
local function main()

  multiRemoteLiDARController.setMultiRemoteLiDAR_Model_Handle(multiRemoteLiDAR_Model) -- share handle of Model

  ----------------------------------------------------------------------------------------
  -- INFO: Please check if module will eventually load inital configuration triggered via
  --       event CSK_PersistentData.OnInitialDataLoaded
  --       (see internal variable _G.multiRemoteLiDAR_Model.parameterLoadOnReboot)
  --       If so, the app will trigger the "OnDataLoadedOnReboot" event if ready after loading parameters
  --
  -- Can be used e.g. like this
  --
  -- Setup
  -- CSK_MultiRemoteLiDAR.setSelectedInstance(1)
  -- CSK_MultiRemoteLiDAR.setInterface('ETHERNET')
  -- CSK_MultiRemoteLiDAR.setIP('192.168.1.110')
  -- CSK_MultiRemoteLiDAR.startLiDARSensor()
  --
  -- Encoder Mode
  -- CSK_MultiRemoteLiDAR.setEncoderMode(true)
  -- CSK_MultiRemoteLiDAR.setEncoderDurationMode('TICKS')
  -- CSK_MultiRemoteLiDAR.setEncoderDurationModeValue(1000) -- collect scan data for 1000 encoder ticks
  -- CSK_MultiRemoteLiDAR.setEncoderModeLoop(false) -- Do NOT automatically restart the measurement
  -- CSK_MultiRemoteLiDAR.setEncoderTriggerEvent('CSK_Module.OnNewTrigger') -- This event will trigger a new measurement
  ----------------------------------------------------------------------------------------

  CSK_MultiRemoteLiDAR.pageCalled() -- Update UI

end
Script.register("Engine.OnStarted", main)

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************