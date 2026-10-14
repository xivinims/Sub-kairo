local B={}
function B.install()
 local runtime=game.ReplicatedStorage.ForestRuntime local world=workspace.ForestWorld local gui=game.StarterGui.TreeWorldMenu
 for _,d in ipairs(gui:GetDescendants())do
  if d:IsA("GuiObject")then d.BackgroundColor3=Color3.fromRGB(8,8,8)d.BorderSizePixel=0
   if d:IsA("TextLabel")or d:IsA("TextButton")or d:IsA("TextBox")then d.TextColor3=Color3.fromRGB(245,245,245)end
   if d:IsA("ImageLabel")or d:IsA("ImageButton")then d.ImageColor3=Color3.fromRGB(230,230,230)d.ImageTransparency=1end
  end
 end
 local loading=gui.Background loading.BackgroundTransparency=0 loading.GameTitle.Text="TreeWorld"loading.Description.Text="Explorar. Descansar."
 loading.Bar.BackgroundColor3=Color3.fromRGB(50,50,50)loading.Bar.LoadBar.BackgroundColor3=Color3.fromRGB(242,242,242)
 local menu=gui.MainMenu menu.BackgroundTransparency=.58 menu.PlayButton.BackgroundTransparency=.28
 local origin=world.Amenities.ForestRuins:GetAttribute("Origin")local focus=origin+Vector3.new(0,5,0)
 runtime:SetAttribute("MenuCameraFocus",focus)runtime:SetAttribute("MenuCameraCF",CFrame.lookAt(origin+Vector3.new(60,14,-12),focus))runtime:SetAttribute("MenuCameraView","RuinSide")
 runtime:SetAttribute("MenuTheme","Monochrome")runtime:SetAttribute("MusicTheme","MonochromeTransparent")return{menuTheme="Monochrome",camera="RuinSide"}
end
return B
