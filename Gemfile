source "https://rubygems.org"

# Specify your gem's dependencies in opal-webassembly.gemspec
gemspec

gem "rake", "~> 12.0"
gem "rspec", "~> 3.0"

gem "pry"

if File.directory? __dir__+"/../opal"
  gem "opal", path: __dir__+"/../opal"
else
  gem "opal", github: "hmdne/opal"
end

gem "opal-rspec"

if File.directory? __dir__+"/../opal-sprockets"
  gem "opal-sprockets", path: __dir__+"/../opal-sprockets"
else
  gem "opal-sprockets"
end

gem "mini_racer"
