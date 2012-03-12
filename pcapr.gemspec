# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pcapr/version"

Gem::Specification.new do |s|
  s.name        = "pcapr"
  s.version     = Pcapr::VERSION
  s.authors     = ["yafei LI"]
  s.email       = ["lyfi2003@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{a libarily for downloading all pcap files from pcapr.net}
  s.description = %q{a libarily for downloading all pcap files from pcapr.net}

  s.rubyforge_project = "pcapr"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency("nokogiri")
  s.add_dependency("patron")
end
