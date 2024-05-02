Rack::Attack.throttle("requests by ip", limit: 1, period: 1) do |request|
  request.ip
end