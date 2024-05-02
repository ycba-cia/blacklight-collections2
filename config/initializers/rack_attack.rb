Rack::Attack.throttle("requests by ip", limit: 2, period: 1) do |request|
  request.ip
end