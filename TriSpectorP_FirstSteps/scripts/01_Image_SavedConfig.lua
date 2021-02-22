--[[----------------------------------------------------------------------------

  Application Name:
  01_Image_SavedConfig

  Description:
  This script shows how to acquire images using a config file that has previously
  been created and saved to the device. This is done via UI of the ImageAcquisition
  app.

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

-- luacheck: globals gImageProvider gImageConfig3D gViewer

-- Create an image provider and an empty config
gImageProvider = Image.Provider.Camera.create()
gImageConfig3D = Image.Provider.Camera.V3TConfig3D.create()
--Setup a viewer with a view decoration
gViewer = View.create('viewer3D1')
local imgDeco = View.ImageDecoration.create()

--@loadConfig(jobPath: string)
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
end
Script.register('Engine.OnStarted', main)
