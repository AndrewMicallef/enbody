Camera = class()

function Camera:new()

    self = self:init{
        -- rotation angles and rates of change
        pitch = 0,
        yaw = 0,
        roll = 0,

        pitch_rate = 0.05,
        yaw_rate = 0.05,
        roll_rate = 0.05,

        -- location
        loc = cpml.vec3(0,0,0),
        fov = 0,
    }
    return self
end

function Camera:update(dt)
    -- TODO replace with quat rotation

    -- pitch [w,s]
    if love.keyboard.isDown("w") then
        self.pitch = self.pitch - self.pitch_rate * dt
    end
    if love.keyboard.isDown("s") then
        self.pitch = self.pitch + self.pitch_rate * dt
    end
    --yaw [a,d]
    if love.keyboard.isDown("a") then
        self.yaw = self.yaw - self.yaw_rate * dt
    end
    if love.keyboard.isDown("d") then
        self.yaw = self.yaw + self.yaw_rate * dt
    end

    --roll [q,e]
    if love.keyboard.isDown("q") then
        self.roll = self.roll - self.roll_rate * dt
    end
    if love.keyboard.isDown("e") then
        self.roll = self.roll + self.roll_rate * dt
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
