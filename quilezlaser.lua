local laserColors = {
	{1, 0.3, 0.3},
	{0.6, 0.3, 1},
	{1, 0.6, 0.3}
}
local brightness = {
    {8, 5, 5},
    {5, 6, 8},
    {8, 6, 5}
}
local laserNames = {
	"Classic Quilez Plasma Laser",
	"Pressurized Cold Plasma Laser",
	"Low Power Infrared Laser"
}
local toolpos = Transform(Vec(0.8, -0.6, -1.0), QuatEuler(0, 0, 0))
local tool = {
    printname = "Quilez Laser",
    group = 6,
    ammo = 10000
}

-- function shootLaser(body, shape, origin, dir, currentLength, deflectorsHit)
-- 	QueryRequire("physical")
-- 	if shape ~= 0 then
-- 		QueryRejectShape(shape)
-- 	end
-- 	if body ~= 0 then
-- 		QueryRejectBody(body)
-- 	end
-- 	local hit, hitDist, hitNormal, hitShape = QueryRaycast(origin, dir, MAX_DIST, 0.0, true)
-- 	local length = MAX_DIST
-- 	if hit then
-- 		length = hitDist
-- 	end
-- 	local hitPoint = VecAdd(origin, VecScale(dir, length))
-- 	local t = Transform(VecLerp(origin, hitPoint, 0.5))
-- 	local xAxis = VecNormalize(VecSub(hitPoint, origin))
-- 	local zAxis = VecNormalize(VecSub(origin, GetCameraTransform().pos))
-- 	t.rot = QuatAlignXZ(xAxis, zAxis)
-- 	DrawSprite(laserSprite, t, length, 0.05+math.random()*0.01, 8, 4, 4, 1, true, true)
-- 	local col = LASER_COLORS[GetInt("savegame.mod.laserMode")]
-- 	DrawSprite(laserSprite, t, length, 0.5, col[1], col[2], col[3], 1, true, true)
-- 	local hitBody = GetShapeBody(hitShape)
-- 	if HasTag(hitBody, "mirror2") and currentLength < MAX_DIST then
-- 		local alreadyHit = false
-- 		for i=1, #deflectorsHit do
-- 			if deflectorsHit[i] == hitBody then
-- 				alreadyHit = true
-- 				break
-- 			end
-- 		end
-- 		if not alreadyHit then
-- 			deflectorsHit[#deflectorsHit+1] = hitBody
-- 			local t = GetBodyTransform(hitBody)
-- 			local refDir = TransformToParentVec(t, Vec(0, 0, 1))
-- 			SetShapeEmissiveScale(hitShape, 1)
-- 			return shootLaser(hitBody, hitShape, t.pos, refDir, currentLength + length, deflectorsHit)
-- 		end
-- 	end
-- 	local hitBody = GetShapeBody(hitShape)
-- 	if HasTag(hitBody, "mirror") and currentLength < MAX_DIST then
-- 		local refDir = VecSub(dir, VecScale(hitNormal, VecDot(hitNormal, dir)*2))
-- 		return shootLaser(hitBody, hitShape, hitPoint, refDir, currentLength + length, deflectorsHit)
-- 	end
-- 	return currentLength + length, hitPoint, hitBody, hitShape
-- end

function tool:Initialize()
	laserReady = 0
	laserFireTime = 0
	laserLoop = LoadLoop("MOD/assets/laser-loop.ogg")
	laserHitLoop = LoadLoop("MOD/assets/laser-hit-loop.ogg")
	laserSprite = LoadSprite("MOD/assets/laser.png")
	laserDist = 0
	laserHitScale = 0
	deflectors = FindBodies("mirror2", true)
	if GetInt("savegame.mod.laserMode") == 0 then
		SetInt("savegame.mod.laserMode", 1)
	end
end

function tool:Animate()
    local ar = self.armature
    local target = PLAYER:GetCamera():Raycast(500, -1)
    local TinT = self:GetPredictedTransform():ToLocal(target.hitpos)
    ar:SetBoneTransform("root", Transform(Vec(0, 0, 0), QuatLookAt(Vec(0, 0, 0), TinT)))
end

function tool:Deploy()
end

function tool:Holster()
end

function tool:GetTarget()
end

function tool:LeftClick()
end

function tool:RightClick()
end

function tool:LeftClickReleased()
end

function tool:RightClickReleased()
end

function tool:Tick()
    -- local now = GetTime()
    -- local lc = VecLerp(Vec(1, 0, 1), Vec(0, 1, 1), 0.5 + math.sin(now)/2)
    SetToolTransform(toolpos)
    local target = PLAYER:GetCamera():Raycast(500, -1)

    if InputDown('lmb') then
        local col = laserColors[GetInt("savegame.mod.laserMode")]
        local brt = brightness[GetInt("savegame.mod.laserMode")]
        local newCol = {};
        PointLight(target.hitpos, col[1], col[2], col[3], 1)
        PointLight(target.hitpos, brt[1], brt[2], brt[3], 0.01)
        PointLight(self:GetBoneGlobalTransform('tip').pos, newCol[1], newCol[2], newCol[3], 1)
        DebugCross(self:GetBoneGlobalTransform('tip').pos)
        visual.drawline(laserSprite, self:GetBoneGlobalTransform('nozzle').pos, target.hitpos, {
            r = col[1], 
            g = col[2], 
            b = col[3],
            additive = true,
            width = 0.5
        })
        visual.drawline(laserSprite, self:GetBoneGlobalTransform('nozzle').pos, target.hitpos, {
            r = brt[1], 
            g = brt[2], 
            b = brt[3],
            additive = true,
            width = 0.05 + math.random() * 0.01
        })
    end
end

tool.model = {
    prefab = [[
<prefab version="0.9.2">
    <group id_="473592032" open_="true" name="laser" pos="0.0 0.0 0.0" rot="0.0 0.0 0.0">
        <group id_="2048256128" open_="true" name="base" pos="0.0 0.0 0.0">
            <vox id_="1640400640" pos="-0.025 -0.175 0.175" rot="0.0 0.0 0.0" file="MOD/assets/laser.vox" object="laserbase" scale="0.5"/>
        </group>
        <group id_="1912784896" open_="true" name="ring" pos="0.0 0.0 -0.25" rot="0.0 0.0 0.0">
            <vox id_="2089677312" pos="-0.025 -0.325 0.025" rot="0.0 0.0 0.0" file="MOD/assets/laser.vox" object="laserring" scale="0.5"/>
        </group>
        <location id_="1100482176" name="nozzle" pos="0.0 0.0 0.275"/>
        <location id_="2067721472" name="tip" pos="0.0 0.0 -0.425"/>
    </group>
</prefab>
    ]],
    objects = {
        {'laserbase', Vec(7, 12, 7)}, -- these sizes were swapped (and the 12 was a 20)
        {'laserring', Vec(13, 1, 13)},
    }
}

RegisterToolUMF('quilezlaser', tool)