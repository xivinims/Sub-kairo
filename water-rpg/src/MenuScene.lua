-- World-space menu routes. No camera parenting: every section has a real scene position.
local MenuScene={}
MenuScene.Duration=.9
MenuScene.Sections={
 Main={camera=Vector3.new(0,0,0),panel=Vector3.new(-.7,.15,-14)},
 Settings={camera=Vector3.new(10,.5,-2),panel=Vector3.new(15,.3,-16)},
 Credits={camera=Vector3.new(-10,.7,-2),panel=Vector3.new(-15,.3,-16)},
 Log={camera=Vector3.new(4,1,-8),panel=Vector3.new(5,.6,-23)},
}
function MenuScene.route(base,name)
 local section=assert(MenuScene.Sections[name],'Unknown menu section')
 local cameraPosition=base:PointToWorldSpace(section.camera)
 local panelPosition=base:PointToWorldSpace(section.panel)
 local view=CFrame.lookAt(cameraPosition,panelPosition,base.UpVector)
 -- Back (+Z) faces the camera, so the SurfaceGui is readable from the chosen viewpoint.
 local plane=CFrame.lookAt(panelPosition,panelPosition+view.LookVector,base.UpVector)
 return view,plane
end
function MenuScene.panelSize(viewport,fov,distance,kind)
 local width,height=500,400
 if kind=='Main' then width,height=600,480 end
 local margin=kind=='Main' and 60 or 38
 local scale=math.min(1,(viewport.X-margin)/width,(viewport.Y-margin)/height)
 scale=math.max(.2,scale)
 local worldHeight=2*distance*math.tan(math.rad(fov/2))
 local h=worldHeight*(height*scale)/viewport.Y
 return Vector3.new(h*width/height,h,.035)
end
return MenuScene
