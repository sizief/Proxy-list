class Proxy
  require 'rest-client'
  require 'nokogiri'
  require 'csv'
  
  def update
    begin
      puts "update proxy at #{Time.now}"
      remove_content
      pn
      fpl
      sp
    rescue
    end
  end

  def get
    proxy =  get_random_proxy
    proxy_url = proxy.nil? ? nil : "https://#{proxy.first}:#{proxy.last}"
  end
   
  protected
  def remove_content
    File.open('proxies.csv', 'w') {|file| file.truncate(0) }  
  end
  
  def get_random_proxy
    chosen_line = nil
    CSV.foreach("proxies.csv").each_with_index do |line, number|
      chosen_line = line if rand < 1.0/(number+1)
    end
    chosen_line
  end

  def save ip, port
    CSV.open('proxies.csv', 'a') do |csv|
        csv << [ip,port]
    end
  end

  def check_validity(ip,port)
    proxy = "https://"+ip.to_s+":"+port.to_s
    begin
      RestClient::Request.execute(method: :get, url: 'http://api.ipify.org?format=json',
                        timeout: 3, proxy: proxy)
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
    import_pn doc
  end

  def import_pn doc
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
      save ip, port if check_validity(ip,port)
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

end