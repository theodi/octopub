Before('@omniauth') do
  OmniAuth.config.test_mode = true
end

After('@omniauth') do
  OmniAuth.config.test_mode = false
end
