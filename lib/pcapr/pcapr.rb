require 'logger'
require 'nokogiri'
require 'patron'
require 'digest'
require 'timeout'
require 'uri'

require 'fileutils'

class Pcapr
  def initialize( user,pass, logger = Logger.new(STDOUT) )
    @user = user
    @pass = pass
    
    @logger = logger
    
    #驱动浏览器底层的接口, patron对象
    @driver = Patron::Session.new
    @driver.timeout = 60 * 60 # 1 hour
    @driver.connect_timeout = 10000
    @driver.base_url = "http://www.pcapr.net"
    @driver.handle_cookies
    
    @protos = nil
  end
  
  # for spec test
  attr_reader :driver
  
  attr_accessor :logger
  
  def login
    #获取uuid
    login_html = @driver.get("/account/login")
    uuid = Nokogiri::HTML(login_html.body).css('#uuid')[0]['value']
    
    login_result = @driver.post("/account/login", {:_user=>@user ,:pass=>@pass, :uuid=>"#{uuid}", :_auth=> auth_md5(@user,@pass,uuid)})
    raise "login fail" if login_result.url.include?("/account/login")
  end
  
  #获取协议内容
  def protos
    return @protos if @protos
    protos_html = @driver.get("/browse/protos").body
    #获取协议内容
    raise "get protos fail,maybe this code is out of update" unless protos_html.match(/var raw = \(\{(.*)\}\)/)
    #格式为xx:1,xxx:2
    protos_str = $1
    @protos = str2protos(protos_str)
  end
  
  def pcap_urls(proto)
    ret = []
    proto_url = URI.encode("/browse?proto=#{proto}")
    url = @driver.get(proto_url).body
    nokogiri_parser = Nokogiri::HTML(url)
    ret += nokogiri_parser.css("ul#p-main div.p-body>a").collect { |link| link['href'] }
    if nokogiri_parser.css('li.p-overflow a').size > 0
      href = nokogiri_parser.css('li.p-overflow a').attr('href').value
      url = @driver.get( "/browse" + href.gsub(" ","%20") ).body
      ret += Nokogiri::HTML(url).css('li.l0 div.p-body>a').collect { |link| link['href'] }
    end
    ret
  end
  
  #获取该数据包文件
  def pcap_file(pcap_url, file)
    # set cookie
    @driver.get(pcap_url)
    res = @driver.get("/view/download")
    File.open(file,"wb") do |f|
      f.write(res.body)
    end
  end
  
  def run(dir)
    base_dir = dir
    login
    protos.each do |proto|
      proto_dir = proto2dir_and_create(base_dir, proto)
      logger.info "proto: #{proto}, downloading...(pcap save as: #{proto_dir}"
      pcap_urls(proto).each do |pcap_url|
        file = pcap2file(proto_dir, pcap_url)
        logger.info "  pcap file: #{pcap_url} save at '#{file}'"
        begin
          pcap_file(pcap_url, file)
          logger.debug "  save ok"
        rescue Patron::TimeoutError
          logger.error "  save fail: timeout after #{@driver.timeout} seconds"
        rescue =>e
          logger.error "  save fail: #{$!}"
        end
      end
    end
  end
  
  
  private
  def auth_md5(user,pass,uuid)
    str = user + '-' + pass
    md5 = Digest::MD5.hexdigest str
    Digest::MD5.hexdigest(md5 + uuid)
  end
  
  def str2protos(str)
    str.split(',').collect do |kv|
      kv.split(':')[0].gsub("'","").strip
    end
  end
  
  def proto2dir_and_create(base_dir, proto)
    #must use strip to cut because mkdir_p ignore the space at last
    proto_dir = File.join(base_dir, proto.tr("\\/:*?\"<>|"," ")).strip
    FileUtils.mkdir_p(proto_dir) unless File.directory?(proto_dir)
    proto_dir
  end
  
  def pcap2file(proto_dir, pcap_url)
    File.join( proto_dir, File.basename(pcap_url).gsub(/\.html$/,"").tr("\\/:*?\"<>|"," ") )
  end
end
