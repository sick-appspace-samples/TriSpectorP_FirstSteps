--[[----------------------------------------------------------------------------

  Application Name:
  03_PassFail

  Description:
  This script shows how to acquire images using a config file that has previously
  been created and saved to the device. This is done via UI of the ImageAcquisition
  app.  A simple pass/fail analysis on the object's elongation is done, and the
  result is output by setting an LED on the camera.

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

-- luacheck: globals gImageProvider gImageConfig3D gLed gViewer

-- Create an image provider and an empty config
gImageProvider = Image.Provider.Camera.create()
gImageConfig3D = Image.Provider.Camera.V3TConfig3D.create()

--Create a LED object
gLed = LED.create('RESULT_LED')
gLed:setColor('blue')

--Setup a viewer with a view decoration
gViewer = View.create('viewer3D1')
local imgDeco = View.ImageDecoration.create()

-- Create a pixel region decoration
local regionDeco = View.PixelRegionDecoration.create()
regionDeco:setColor(0, 250, 0, 100) -- Green semi transparent

---Image callback
---@param images Image
---@param sensorData SensorData
local function OnNewImage(images)
  gViewer:clear()
  local hMapId = nil
  if #images == 2 then -- Only 3D images
    local heightMap = images[1]
    local intensityMap = images[2]

    -- Set color range for optimized height visualization
    local min = heightMap:getMin()
    local max = heightMap:getMax()
    imgDeco:setRange(min, max)

    -- Add to 3D viewer
    hMapId = gViewer:addHeightmap({heightMap, intensityMap}, imgDeco)
  end

  --Find blobs

  -- Use the Select tool in the UI to find the height of the conveyor and type
  -- something slightly larger than this value instead of 35 below
  local threshRegion = images[1]:threshold(35)

  --Specify the minimum amount of pixels for a connected region to be counted as a blob
  local blobs = threshRegion:findConnected(50)

  for i = 1, #blobs do
    gViewer:addPixelRegion(blobs[i], regionDeco, nil, hMapId)
    local elongation = blobs[i]:getElongation(images[1])
    if elongation > 1.75 then -- pass
      print('PASS, Elongation is:' .. elongation)
      gLed:setColor('green')
    else --fail
      print('FAIL, Elongation is:' .. elongation)
      gLed:setColor('red')
    end
  end
  gViewer:present()
end

---Load config
---@param jobPath string
local function loadConfig(jobPath)
  -- Check if file exists
  if not File.exists(jobPath) then
    print('Error: File not found: ' .. jobPath)
    return
  end

  -- Try to load config
  local loadedConfig = Object.load(jobPath)
  if loadedConfig == nil then
    print('Error: Failed loading configuration')
    return
  end

  print('Config loaded')
  return loadedConfig
end

local function main()
  -- Define path to config file
  local jobPath = 'public/Image3DConfig.json'

  -- Load image config
  gImageConfig3D = loadConfig(jobPath)

  if gImageConfig3D:validate() then -- If OK
    -- Apply config on image provider
    gImageProvider:setConfig(gImageConfig3D)

    -- Register image callback
    gImageProvider:register('OnNewImage', OnNewImage)

    -- Start image provider
    gImageProvider:start()
  else
    print('Error in image config')
  end
  gLed:activate()
end
Script.register('Engine.OnStarted', main)
