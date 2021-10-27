local toolbar = plugin:CreateToolbar("Binky007's Utilities")
local PluginButton = toolbar:CreateButton("Open API", "Opens the API window", "rbxassetid://7400955864")
local WidgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	664,
	382,
	332,
	191
)
local Widget = plugin:CreateDockWidgetPluginGui("API Utility", WidgetInfo)
local APIGui = script.Parent:WaitForChild("APIGui")
local MethodTemplate = script.MethodTemplate
local ListTemplate = script.ListTemplate
local SelectedModule = "TestMod"
local Tag = "-- @"
local Modules = {}
local Connections = {}
local findTags = {
	"Name",
	"Description",
	"Arguements"
}

Widget.Title = "API Utility by binky007"
Widget.Name = "API Utility"
APIGui.Parent = Widget
PluginButton.ClickableWhenViewportHidden = true

local function Scan(parent)
	local Scripts = {}
	for _, item in ipairs(parent:GetDescendants()) do
		if item:IsA("ModuleScript") then
			Scripts[#Scripts+ 1] = item
		end
	end
	return Scripts
end

local function mergeArray(MasterTable, t1, t2)
	MasterTable = MasterTable or {}
	t1 = t1 or {}
	t2 = t2 or {}
	for _,v in ipairs(t1) do
		table.insert(MasterTable,v)
	end
	for _,v in ipairs(t2) do
		table.insert(MasterTable,v)
	end
	return MasterTable
end

local function updateList()
	table.clear(Modules)
	local t1 = Scan(game.ReplicatedStorage)
	local t2 = Scan(game.ServerScriptService)
	local t3 = Scan(game.ServerStorage)
	local fused = {}
	local step1 = mergeArray(fused, t1,t2)
	local step2 = mergeArray(step1, t3)
	fused = step2
	for _, Module in ipairs(fused) do
		Modules[Module.Name] = Module
	end
end

local function getTags(Source)
	local list = {}
	local Start = 0
	local running = true
	local timer = os.clock()
	while running and (os.clock()- timer < .1) do
		local stuff = {}
		for i, FindTag in ipairs(findTags) do
			local moduleDescriptionStart = (string.find(Source,Tag.. FindTag, Start) or -100000) + string.len(Tag.. FindTag)
			if moduleDescriptionStart < 0 then
				running = false
				break
			end
			local moduleDescriptionEnd = string.find(Source, "\n", moduleDescriptionStart)
			Start = moduleDescriptionEnd
			stuff[i] = string.sub(Source, moduleDescriptionStart+1, moduleDescriptionEnd-1)
		end
		if #stuff > 0 then
			list[#list + 1] = stuff
		end
	end
	return list
end

local function clearList(Frame)
	for _, item in ipairs(Frame:GetChildren()) do
		if item:IsA("Frame") then
			item:Destroy()
		end
	end
end

local function updateMethodList(Module)
	local Source = Module.Source
	local Methods = getTags(Source)
	local Start = (string.find(Source,Tag.. "ModuleDescription") or 0) + string.len(Tag.. "ModuleDescription")+  1
	local End = string.find(Source, "\n", Start)
	APIGui.TopBar["Module Description"].Text = string.sub(Source, Start, End-1)
	for index, info in ipairs(Methods) do
		local newFrame = MethodTemplate:Clone()
		newFrame.Description.Text = info[2]
		newFrame.MethodName.Text = Module.Name.. ":".. info[1].."("..info[3].. ")"
		newFrame.Parent = APIGui.MethodFrame
	end
end

local function resetVisiblity()
	APIGui.TopBar["Module Description"].Text = ""
	APIGui.ListFrame.Visible = true
	APIGui.MethodFrame.Visible = false
end

local function updateModuleList()
	for name, module in pairs(Modules) do
		local newFrame = ListTemplate:Clone()
		newFrame.ScriptName.Text = module.Parent.Name .. "." .. name
		newFrame.ScriptType.Text = module.ClassName
		newFrame.Next.Activated:Connect(function()
			print("Clicked")
			APIGui.ListFrame.Visible = not APIGui.ListFrame.Visible
			APIGui.MethodFrame.Visible = not APIGui.MethodFrame.Visible
			
			clearList(APIGui.MethodFrame)
			SelectedModule = name
			updateMethodList(module)
		end)
		newFrame.Parent = APIGui.ListFrame
	end
end

APIGui.TopBar.Back.Activated:Connect(resetVisiblity)

PluginButton.Click:Connect(function()
	if Widget.Enabled then
		Widget.Enabled = false
	else
		clearList(APIGui.MethodFrame)
		clearList(APIGui.ListFrame)
		resetVisiblity()
		Widget.Enabled = true
		updateList()
		updateModuleList()
		--updateMethodList(Modules[SelectedModule])
	end
end)
