--[[----------------------------------------------------------------------------

  Application Name:
  02_BasicSetupExample

  Description:
  This script shows a basic example on how to set up the image acquisition for
  TriSpectorP and to acquire images.

  How to Run:
  To show this sample, first set it as main (right-click -> "Set as main").
  Starting this sample is possible either by running the app (F5) or
  debugging (F7+F10). Setting breakpoint on the first row inside the 'main'
  function allows debugging step-by-step after 'Engine.OnStarted' event.
  Results can be seen in the image viewer on the DevicePage. You need to be
  connected to a TriSpectorP, this app does not work with the emulator.

  More Information:
  See the tutorials:
  https://supportportal.sick.com/tutorial/trispectorp-first-steps/
  https://supportportal.sick.com/tutorial/trispectorp-image-acquisition/

------------------------------------------------------------------------------]]
--Start of Global Scope---------------------------------------------------------

-- luacheck: globals gCamera gConfig gViewer

--Create a camera object
gCamera = Image.Provider.Camera.create()

--Create a 3D-gConfig object
gConfig = Image.Provider.Camera.V3TConfig3D.create()
gConfig:setExposureTime(50)
gConfig:setGain(1)
gConfig:setLaserThreshold(20)
gConfig:setPeakSelectionMode('STRONGEST')
gConfig:setProfileTriggerMode('ENCODER')
gConfig:setImageTriggerMode('NONE')
gConfig:setEncoderTicksPerMm(19)
gConfig:setProfileDistance(0.5)
gConfig:setXResolution(0.5)
gConfig:setFieldOfView(300, 400, 0, 200)
gConfig:setHeightmapLength(200)

gCamera:setConfig(gConfig)

--Setup a viewer with a view decoration
gViewer = View.create('viewer3D1')

local imgDeco = View.ImageDecoration.create()

local function main()
  gCamera:start()
end
Script.register('Engine.OnStarted', main)

-- Image callback
-- @OnNewImage(images: Image, sensorData: SensorData)
local function OnNewImage(images)
  if #images == 2 then -- Only 3D images
    local heightMap = images[1]
    local intensityMap = images[2]

    -- Set color range for optimized height visualization
    local min = heightMap:getMin()
    local max = heightMap:getMax()
    imgDeco:setRange(min, max)

    -- Add to 3D viewer
    gViewer:addHeightmap({heightMap, intensityMap}, imgDeco)
    gViewer:present()
  end
end

gCamera:register('OnNewImage', OnNewImage)

-- --@loadConfig(jobPath: string)
-- local function loadConfig(jobPath)
--   -- Check if file exists
--   if not File.exists(jobPath) then
--     print('Error: File not found: ' .. jobPath)
--     return
--   end

--   -- Try to load config
--   local loadedConfig = Object.load(jobPath)
--   if loadedConfig == nil then
--     print('Error: Failed loading configuration')
--     return
--   end

--   print('Config loaded')
--   return loadedConfig
-- end
