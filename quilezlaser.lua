local laserColors = {
	{1, 0.3, 0.3},
	{0.6, 0.3, 1},
	{1, 0.6, 0.3}
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

function visual.drawline( sprite, source, destination, info )
    local r, g, b, a
    local writeZ, additive = true, false
    local target = GetCameraTransform().pos
    local DrawFunction = DrawLine
    local width = 0.03
    if info then
        r = info.r and info.r or 1
        g = info.g and info.g or 1
        b = info.b and info.b or 1
        a = info.a and info.a or 1
        width = info.width or width
        target = info.target or target
        if info.writeZ ~= nil then
            writeZ = info.writeZ
        end
        if info.additive ~= nil then
            additive = info.additive
        end
        DrawFunction = info.DrawFunction ~= nil and info.DrawFunction or (info.writeZ == false and DebugLine or DrawLine)
    end
    if sprite then
        local middle = VecScale( VecAdd( source, destination ), .5 )
        local len = VecLength( VecSub( source, destination ) )
        local transform = Transform( middle, QuatRotateQuat( QuatLookAt( source, destination ), QuatEuler( -90, 0, 0 ) ) )
        local target_local = TransformToLocalPoint( transform, target )
        target_local[2] = 0
        local transform_fixed = TransformToParentTransform( transform, Transform( nil, QuatLookAt( target_local, nil ) ) )
        DrawSprite( sprite, transform_fixed, width, len, r, g, b, a, writeZ, additive )
    else
        DrawFunction( source, destination, r, g, b, a );
    end
end

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
    ar:SetBoneTransform("laser", Transform(Vec(0, 0, 0), QuatLookAt(Vec(0, 0, 0), TinT)))
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

    -- PointLight(target.hitpos, lc[1], lc[2], lc[3], 1)
    -- DebugLine(target.hitpos, self:GetBoneGlobalTransform('laserring').pos, 0, 1, 0, 1)
    -- DebugLine(target.hitpos, self:GetBoneGlobalTransform('root'), 0, 1, 0, 1)
    local col = laserColors[GetInt("savegame.mod.laserMode")]
    visual.drawline(laserSprite, self:GetBoneGlobalTransform('nozzle').pos, target.hitpos, {
        r = col[1], 
        g = col[2], 
        b = col[3],
        additive = true,
        width = 0.5
    });

    if InputDown('lmb') then
        -- local dir = TransformToParentVec(tlt, Vec(0, 0, -1))
        -- local length, hitPoint, hitBody, hitShape = shootLaser(0, shapes, origin, dir, 0, {})
        -- if length ~= laserDist then
        --     laserHitScale = 1
        --     laserDist = length
        -- end
        -- laserHitScale = math.max(0.0, laserHitScale - dt)
        -- local velocity = VecNormalize(VecSub(target.hitpos, toolPos))
        -- SpawnParticle(toolPos, VecScale(velocity, 25), 1)
    end
end

tool.model = {
    scale = 0.5,
    prefab = [[
<prefab version="0.9.2">
    <group name="base">
        <vox scale="0.5" pos="0.0 0.0 0.0" rot="0.0 0.0 0.0" file="MOD/assets/laser.vox" object="laserbase"/>
    </group>
    <group name="ring">
        <vox scale="0.5" pos="0.0 -0.3 -0.9" rot="0.0 0.0 0.0" file="MOD/assets/laser.vox" object="laserring"/>
    </group>
    <location name="nozzle" pos="0.05 0.35 -1.2"/>
</prefab>
    ]],

    objects = {
        {'laserbase', Vec(13, 1, 13)},
        {'laserring', Vec(7, 20, 7)},
    }
}

RegisterToolUMF('quilezlaser', tool)