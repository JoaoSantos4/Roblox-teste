-- Módulo real: teste de resize, safe area, reparent, texto e menus exclusivos.
local function signal()
 local listeners = {}
 return { Connect = function(_,fn) table.insert(listeners,fn); return { Disconnect = function() end } end,
 Fire = function(_,...) for _,fn in ipairs(listeners) do fn(...) end end }
end
local objects = {}
local methods = {}
function methods:IsA(class) return self.ClassName == class end
function methods:GetChildren()
 local result = {}
 for _,v in ipairs(objects) do if v.Parent == self then table.insert(result,v) end end
 return result
end
function methods:GetDescendants()
 local result = {}
 for _,v in ipairs(self:GetChildren()) do
  table.insert(result,v)
  for _,child in ipairs(v:GetDescendants()) do table.insert(result,child) end
 end
 return result
end
function methods:FindFirstChild(name)
 for _,v in ipairs(self:GetChildren()) do if v.Name == name then return v end end
end
function methods:GetPropertyChangedSignal(name)
 if not self._signals[name] then self._signals[name] = signal() end
 return self._signals[name]
end
local function new(class,parent)
 local data = { ClassName = class, Parent = parent, Enabled = true, Visible = false, TextSize = 16,
 Name = class, IgnoreGuiInset = false, Activated = signal(), DescendantAdded = signal() }
 local object = setmetatable({ _data = data, _signals = {} }, {
 __index = function(self,k) return methods[k] or self._data[k] end,
 __newindex = function(self,k,v)
  local old = self._data[k]; self._data[k] = v
  if old ~= v and self._signals[k] then self._signals[k]:Fire() end
 end })
 table.insert(objects,object)
 return object
end
local Instance = { new = new }
local UDim = { new = function(...) return {...} end }
local UDim2 = { new = function(...) return {...} end, fromScale = function(...) return {...} end, fromOffset = function(...) return {...} end }
local Vector2 = { new = function(x,y) return { X = x, Y = y } end }
local Color3 = { new = function(...) return {...} end, fromRGB = function(...) return {...} end }
local Enum = { Font = { GothamBold = "Bold" }, SortOrder = { LayoutOrder = 1 }, AutomaticSize = { Y = 1 } }
local playerGui = new("PlayerGui")
local player = { WaitForChild = function() return playerGui end }
local camera = new("Camera"); camera.ViewportSize = Vector2.new(1280,720)
local Workspace = new("Workspace"); Workspace.CurrentCamera = camera
local GuiService = new("GuiService")
function GuiService:GetGuiInset() return Vector2.new(0,58),Vector2.new(0,0) end
local UserInputService = new("UserInputService"); UserInputService.TouchEnabled = false; UserInputService.KeyboardEnabled = true
local services = { Players = { LocalPlayer = player }, Workspace = Workspace, GuiService = GuiService, UserInputService = UserInputService }
local game = { GetService = function(_,name) return services[name] end }
local UI = (function()
-- UI_SOURCE
end)()
local count = 0
local function check(value) assert(value); count += 1 end
local phone = UI.Layout(390,844,true,0,58)
check(phone.Compact and phone.Width == 390 and phone.Height == 786 and phone.RollBottom == 150)
local landscape = UI.Layout(844,390,true,0,58)
check(landscape.Compact and landscape.RollWidth == 380 and landscape.RollBottom == 72)
check(not UI.Layout(1280,720,false,0,58).Compact)
local function panel()
 local gui = new("ScreenGui",playerGui)
 local panel = new("Frame",gui)
 local toggle = new("TextButton",gui); toggle.Position = UDim2.fromOffset(15,100); toggle.Size = UDim2.fromOffset(145,50)
 local close = new("TextButton",panel)
 return gui,panel,toggle,close
end
local a,ap,at,ac = panel()
local b,bp,bt,bc = panel()
local savedPosition = at.Position
UI.RegisterPanel("inventory",a,ap,at,ac,480,500,1)
UI.RegisterPanel("shop",b,bp,bt,bc,520,480,2)
check(at.Parent == a and at.Position == savedPosition)
check(ap.Size[1] == 480 and ap.Size[2] == 500)
ap.Visible = true; bp.Visible = true
check(bp.Visible and not ap.Visible)
ap.Visible = true
check(ap.Visible and not bp.Visible)
check(ac.Size[1] == 40 and ac.Size[2] == 40)
local nav = playerGui:FindFirstChild("RNGNavigationGui")
local menu = nav:FindFirstChild("MenuButton")
local drawer = nav:FindFirstChild("MenuDrawer")
check(not menu.Visible)
camera.ViewportSize = Vector2.new(390,844)
check(menu.Visible and at.Parent == drawer and bt.Parent == drawer)
check(ap.Size[1] == 366 and ap.Size[2] == 500)
menu.Activated:Fire()
check(drawer.Visible and not ap.Visible and not bp.Visible)
ap.Visible = true
check(not drawer.Visible)
camera.ViewportSize = Vector2.new(844,390)
check(ap.Size[2] == 308)
camera.ViewportSize = Vector2.new(1280,720)
check(not menu.Visible and at.Parent == a and bt.Parent == b and at.Position == savedPosition)
local rollGui = new("ScreenGui",playerGui)
local controls,card = new("Frame",rollGui),new("Frame",rollGui)
UI.RegisterRoll(rollGui,controls,card)
check(controls.Size[1] == 380 and controls.Position[4] == -24)
camera.ViewportSize = Vector2.new(390,844)
check(controls.Position[4] == -150 and controls.Size[1] == 366)
local label = new("TextLabel",ap)
a.DescendantAdded:Fire(label)
check(label.TextScaled and label:FindFirstChild("RNGTextBounds").MinTextSize == 12)
UI.CloseAll()
check(not ap.Visible and not bp.Visible)
camera.ViewportSize = Vector2.new(1280,720)
UI.PanelSizes.shop = Vector2.new(430,450)
UI.Refresh()
check(bp.Size[1] == 430 and bp.Size[2] == 450)
print("UIConfig: " .. count .. " verificações passaram (viewport e interface simulados)")
