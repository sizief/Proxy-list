class Proxy
  require 'rest-client'
  require 'nokogiri'
  require 'csv'
  
  def update
    begin
      puts "update proxy at #{Time.now}"
      remove_content
      pn_ir
      pn
      fpl
      sp
    rescue
    end
  end

  def get_ir
    get "proxies_ir.csv"
  end

  def get_int
    get "proxies.csv"
  end
   
  protected
  def get file_name
    proxy =  get_random_proxy file_name
    proxy_url = proxy.nil? ? nil : "https://#{proxy.first}:#{proxy.last}"
  end

  def remove_content
    files = %w(proxies.csv proxies_ir.csv)
    files.each do |file_name|
      File.open(file_name, 'w') {|file| file.truncate(0) }  
    end 
  end
  
  def get_random_proxy file_name
    chosen_line = nil
    CSV.foreach(file_name).each_with_index do |line, number|
      chosen_line = line if rand < 1.0/(number+1)
    end
    chosen_line
  end

  def save ip, port, iran_proxy=false
    file_name = (iran_proxy == true) ? 'proxies_ir.csv' : 'proxies.csv'
    CSV.open(file_name, 'a') do |csv|
        csv << [ip,port]
    end
  end

  def check_validity(ip,port)
    proxy = "https://"+ip.to_s+":"+port.to_s
    begin
      RestClient::Request.execute(method: :get, url: 'http://api.ipify.org?format=json',timeout: 3, proxy: proxy)
    rescue
      return false
    end
    return true
  end

  def pn #proxynova website
    proxy_list_page = "https://www.proxynova.com/proxy-server-list/"
    response = RestClient::Request.execute(method: :get, url: "#{URI.parse(proxy_list_page)}", timeout: 10)
    html_page = Nokogiri::HTML(response)
    doc = html_page.xpath('//*[@id="tbl_proxy_list"]/tbody[1]/tr')
    import_pn doc, false
  end

  def pn_ir #proxynova website
    proxy_list_page = "https://www.proxynova.com/proxy-server-list/country-ir/"
    response = RestClient::Request.execute(method: :get, url: "#{URI.parse(proxy_list_page)}", timeout: 10)
    html_page = Nokogiri::HTML(response)
    doc = html_page.xpath('//*[@id="tbl_proxy_list"]/tbody[1]/tr')
    import_pn doc, true
  end

  def import_pn doc, iran_proxy
    doc.each do |row|
      ip = row.css("td[1]").text
      next unless ip.include? "document" #there is some row that did not contain ips
      ip.slice!("document.write('")
      ip.slice!("'.substr(2) + '")
      ip.slice!("');")
      ip = ip[2..-1]

      if row.css("td[2] a").text.empty?
        port = row.css("td[2]").text.gsub(/[^0-9]/, "")
      else
        port = row.css("td[2] a").text
      end
      save(ip, port, iran_proxy) if check_validity(ip,port)
    end
  end 

  def fpl #free proxy list website
    proxy_list_page = "https://free-proxy-list.net/"
    response = RestClient::Request.execute(method: :get, url: "#{URI.parse(proxy_list_page)}", timeout: 10)
    html_page = Nokogiri::HTML(response)
    doc = html_page.xpath('//*[@id="proxylisttable"]/tbody/tr')
    
    doc.each_with_index do |row, index|
      ip = row.css("td[1]").text
      port = row.css("td[2]").text
      https = row.css("td[7]").text
      save ip, port if check_validity(ip,port)
      break if index > 30 #there are too many proxies on their list
    end
  end

  def sp #ssl proxies website
    proxy_list_page = "https://www.sslproxies.org/"
    #response = RestClient.get("#{URI.parse(proxy_list_page)}")
    response = RestClient::Request.execute(method: :get, url: "#{URI.parse(proxy_list_page)}", timeout: 10)
    html_page = Nokogiri::HTML(response)
    doc = html_page.xpath('//*[@id="proxylisttable"]/tbody/tr')
    
    doc.each_with_index do |row, index|
      ip = row.css("td[1]").text
      port = row.css("td[2]").text
      save ip, port if check_validity(ip,port)    
      break if index > 30 #there are too many proxies on their list
    end
  end

  def spys #free proxy list website
    proxy_list_page = "http://spys.one/free-proxy-list/IR/"
    response = RestClient::Request.execute(method: :get, url: "#{URI.parse(proxy_list_page)}", timeout: 10)
    html_page = Nokogiri::HTML(response)
    doc = html_page.xpath('//*[@class="proxylisttable"]/tbody/tr')
    
    doc.each_with_index do |row, index|
      ip = row.css("td[1]").text
      port = row.css("td[2]").text
      https = row.css("td[7]").text
      save ip, port if check_validity(ip,port)
      break if index > 30 #there are too many proxies on their list
    end
  end

end