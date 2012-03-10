require 'spec_helper'

describe Pcapr do
  before(:each) do
    user= "bocycn@gmail.com"
    pass="sinfor"
    @o = Pcapr.new(user,pass)
  end
  it "should login success" do
    lambda { @o.login }.should_not raise_error
  end
  
  it "should login fail" do
    user= "bocycn1@gmail.com"
    pass="sinfor"
    @o = Pcapr.new(user,pass)
    lambda { @o.login }.should raise_error
  end
  
  it "protos should get right" do
    @o.login
    @o.protos.should be_include("dns")
  end
  
  it "all_proto should get auth.cap" do
    @o.login
    @o.pcap_urls("dns").should be_include("/view/siim/2011/11/3/7/capture.pcap.html")
  end
  
  it "file get it " do
    @o.login
    pcap_url = "/view/siim/2011/11/3/7/capture.pcap.html"
    file = File.join($helper_dir,'test.pcap')
    base = File.join($helper_dir,'base.pcap')
    File.delete(file) if File.exist?(file)
    @o.pcap_file(pcap_url,file)
    File.should be_exist(file)
    #~ File.size(file).should == File.size(base)
    File.delete(file) if File.exist?(file)
  end
  
  it "run try" do
    @o.run( File.join($helper_dir,"me") )
  end
  
  
end
