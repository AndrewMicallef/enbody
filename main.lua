require 'src.dependancies'

function love.load()

	particles = Particles{dim = 24, ntypes=2}
end

function love.update(dt)
	particles:update(dt)
end

function love.draw()
	particles:render()
end
