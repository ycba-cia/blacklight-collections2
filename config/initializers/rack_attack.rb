Rack::Attack.throttle("requests by ip", limit: ENV["RACK_ATTACK_LIMIT"].to_i, period: ENV["RACK_ATTACK_PERIOD"].to_i) do |request|
  request.ip
end