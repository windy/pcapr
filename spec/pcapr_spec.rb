require 'spec_helper'

require 'digest'

describe Pcapr do
  before(:each) do
    user= "bocycn@gmail.com"
    pass="sinfor"
    @o = Pcapr.new(user,pass)
  end
  
  it "should show version" do
    lambda { Pcapr::VERSION }.should_not raise_error
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
    @o.protos.should be_include("gtp <ftp>")
    @o.protos.should be_include("http/xml")
    @o.protos.should be_include("ieee 802.15.4")
    @o.protos.should be_include("ipx rip")
    @o.protos.should be_include("megaco/sdp/sdp")
    @o.protos.should be_include("m2pa (id 12)")
  end
  
  it "should get pcapfile urls when proto include quote" do
    @o.login
    urls = @o.pcap_urls("afs (rx)")
    urls.size.should >= 7
    urls.should be_include("/view/tyson.key/2009/10/0/6/LiquidWar_Lobby_1_00002_20091101140004.pcap.html")
  end
  
  it "should support more pcap urls" do
    @o.login
    urls = @o.pcap_urls("dns")
    urls.size.should == 34
  end
  
  it "all_proto should get auth.cap" do
    @o.login
    @o.pcap_urls("dns").should be_include("/view/siim/2011/11/3/7/capture.pcap.html")
  end
  
  it "file get it but timeout" do
    begin
      @o.login
      pcap_url = "/view/sudhakar_gajjala/2010/6/1/21/6462.pcap.html"
      file = File.join($helper_dir, 'timeout.pcap')
      @o.driver.timeout = 1
      lambda { @o.pcap_file(pcap_url,file) }.should raise_error(Patron::TimeoutError)
    ensure
      @o.driver.timeout = 60*60
    end
  end
  
  it "driver timeout default is 1 hour" do
    @o.driver.timeout.should == 60*60
  end
  
  it "file get it " do
    @o.login
    pcap_url = "/view/siim/2011/11/3/7/capture.pcap.html"
    file = File.join($helper_dir,'test.pcap')
    base = File.join($helper_dir,'base.pcap')
    File.delete(file) if File.exist?(file)
    @o.pcap_file(pcap_url,file)
    File.should be_exist(file)
    File.size(file).should == File.size(base)
    Digest::MD5.hexdigest(File.read(file)).should == Digest::MD5.hexdigest(File.read(base))
    File.delete(file) if File.exist?(file)
  end
  
  #~ it "run try" do
    #~ @o.run( File.join($helper_dir,"me") )
  #~ end
  
  
end
