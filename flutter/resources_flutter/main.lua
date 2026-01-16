-------------------------------------------------------------------------------
--                                                                           --
-- Copyright 2026 EligoVision. Interactive Technologies                      --
--                                                                           --
-- Permission is hereby granted, free of charge, to any person obtaining a   --
-- copy of this software and associated documentation files                  --
-- (the "Software"), to deal in the Software without restriction, including  --
-- without limitation the rights to use, copy, modify, merge, publish,       --
-- distribute, sublicense, and/or sell copies of the Software, and to permit --
-- persons to whom the Software is furnished to do so, subject to the        --
-- following conditions:                                                     --
--                                                                           --
-- The above copyright notice and this permission notice shall be included   --
-- in all copies or substantial portions of the Software.                    --
--                                                                           --
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS   --
-- OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF                --
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.    --
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY      --
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,      --
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE         --
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                    --
--                                                                           --
-------------------------------------------------------------------------------

local logger = set_lua_logger("flutter_example")

globals = {
	model = reactorController:getReactorByName("model/logo"),
	audio = reactorController:getReactorByName("audio/main")
}

local pluginManager = evi.PluginManager.instance()
if pluginManager then
	local result = pluginManager:registerPlugin("flutter")
	if result >= 0 then
		logger:info("'flutter' plugin registered!")
	else
		logger:error("Cannot register 'flutter' plugin!")
	end
else
	logger:error("Cannot create plugin manager!")
end

local ffi = require_sys("ffi")
local flutterLib = ffi.load(__evi_os == "ios" and "@executable_path/Frameworks/evi_plugin_flutter.framework/evi_plugin_flutter" or "evi_plugin_flutter")

ffi.cdef[[
	typedef struct {
		char nodeName[256];
	} LuaArgs;

	void evi_plugin_flutter_call_flutter(const char* aEntryPoint, const char* aLibraryURI, const char* aName, void* aData);
	void evi_plugin_flutter_add_listener(const char* aEntryPoint, const char* aLibraryURI);
]]

if flutter then
	local function createTraits(affectLifecyle, transparent, h, w, x, y, id)
		local traits = flutter.HostView.Traits()
		traits:setAffectLifecycleEVI(affectLifecyle)
		traits:setTransparent(transparent)
		traits:setHeight(h)
		traits:setWidth(w)
		traits:setX(x)
		traits:setY(y)
		traits:setContainerId(id)

		return traits
	end

	traits1 = createTraits(false, true, 0.1, 0.18, 1 - 0.18, 0.2, "flutter_container_main")
	traits1:setLayer(10.0)
	flutterHostViewMain = flutter.HostView("main", "", traits1)

	traits2 = createTraits(false, true, 0.2, 0.5, 0.0, 0.8, "flutter_container_button")
	traits2:setLayer(15.0)
	flutterHostViewButton = flutter.HostView("bottomWidgets", "", traits2)

	flutterLib.evi_plugin_flutter_add_listener("main", "")
	flutterLib.evi_plugin_flutter_add_listener("bottomWidgets", "")
	lua2flutterData = ffi.new("LuaArgs")
end

globals.audio:subscribeEvent("onFinished", function()
	flutterLib.evi_plugin_flutter_call_flutter("bottomWidgets", "", "onAudioFinished", lua2flutterData)
end)

local function onDownCb(nodePath)
	local node = nodePath:back()
	local nodeName = node:getName()
	logger:info("Pressed on: ", nodeName)
	ffi.copy(lua2flutterData.nodeName, nodeName)
	flutterLib.evi_plugin_flutter_call_flutter("bottomWidgets", "", "onNodeClick", lua2flutterData)

	return false
end

local observer = EVosgGA.PickHandler.Observer()
pickHandler:registerObserver(observer)

local timer_ui = reactorController:getReactorByName("timer/ui")
timer_ui:subscribeEvent("onAlarm", function()
	flutterHostViewMain:display()
	flutterHostViewButton:display()
	observer:setOnDownCb(onDownCb)
end)

timer_ui:start(0.5, TimerReactor.Mode.ONCE)

