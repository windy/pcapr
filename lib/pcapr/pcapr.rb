require 'logger'
require 'nokogiri'
require 'patron'
require 'digest'

require 'fileutils'

class Pcapr
  def initialize( user,pass, logger = Logger.new(STDOUT) )
    @user = user
    @pass = pass
    
    @logger = logger
    
    #驱动浏览器底层的接口, patron对象
    @driver = Patron::Session.new
    @driver.timeout = 10000
    @driver.base_url = "http://www.pcapr.net"
    @driver.handle_cookies
    
    @protos = nil
  end
  
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
    #TODO
    url = @driver.get("/browse?proto=#{proto}").body
    Nokogiri::HTML(url).css("ul#p-main div.p-body>a").collect { |link| link['href'] }
  end
  
  #获取该数据包文件
  def pcap_file(pcap_url, file)
    @driver.get(pcap_url)
    #~ file = @driver.get_file("/view/download", "d:/ok.pcap", "Referer"=>@driver.base_url + pcap_url)
    file = @driver.get_file("/view/download", file)
  end
  
  def run(dir)
    base_dir = dir
    login
    protos.each do |proto|
      proto_dir = File.join(base_dir, proto)
      proto_dir.tr!("<>","")
      FileUtils.mkdir_p(proto_dir) unless File.directory?(proto_dir)
      logger.info "proto: #{proto}, downloading...(pcap save as: #{proto_dir}"
      pcap_urls(proto).each do |pcap_url|
        file = File.join(proto_dir, File.basename(pcap_url).gsub(/\.html$/,""))
        logger.info "  pcap file: #{file} save at '#{file}'"
        begin
          pcap_file(pcap_url, file)
          logger.debug "  save ok"
        rescue Exception
          logger.error " save fail: #{$!}"
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
  
  
  
end
