Camera = class()

function Camera:new()

    self = self:init{
        pitch = 0,
        yaw = 0,
        roll = 0,
        loc = cpml.vec3(0,0,0),
        fov = 0,

    }
    return self
end

function Camera:update(dt)
    -- TODO replace with quat rotation
    --pan
    local pan_amount = (50 / self.zoom) * dt
    if love.keyboard.isDown("up") then
        self.cy = self.cy - pan_amount
    end
    if love.keyboard.isDown("down") then
        self.cy = self.cy + pan_amount
    end
    --rotate
    local rotate_amount = math.pi * 0.5 * dt
    if love.keyboard.isDown("left") then
        self.cx = self.cx - rotate_amount
    end
    if love.keyboard.isDown("right") then
        self.cx = self.cx + rotate_amount
    end

    --zoom
    if love.keyboard.isDown("i") then
        self.zoom = self.zoom * 1.01
    end
    if love.keyboard.isDown("o") then
        self.zoom = self.zoom / 1.01
    end
end



function create_transform_matrix(pitch, yaw, roll)

    local xaxis = cpml.vec3(1,0,0)
    local yaxis = cpml.vec3(0,1,0)
    local zaxis = cpml.vec3(0,0,1)

    local total = cpml.quat.unit

    for _, v in ipairs({{pitch, xaxis}, {yaw, yaxis}, {roll, zaxis}}) do
        local angle, axis = unpack(v)
        local local_rotation = cpml.quat{
                            w = math.cos(angle / 2),
                            x = axis.x * math.sin(angle/2),
                            y = axis.y * math.sin( angle/2 ),
                            z = axis.z * math.sin( angle/2 ),
                            }

        -- generate local_rotation
        total = local_rotation * total --multiplication order matters on this line
    end

    local transform = cpml.mat4.from_quaternion(total)

    return transform
end
