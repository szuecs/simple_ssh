# encoding: UTF-8

require 'hoe'

Hoe::add_include_dirs("lib")

Hoe.plugins.delete :rubyforge
Hoe.plugin :git

Hoe.spec 'simple_ssh' do
  developer "Sandor Szücs", 'sandor.szuecs@fu-berlin.de'
  
  self.flay_threshold = 100
  
  self.history_file = "CHANGELOG.rdoc"
  self.readme_file = "README.rdoc"
  
  extra_deps << ['net-ssh', '~> 2.0']
end

# vim: syntax=ruby
