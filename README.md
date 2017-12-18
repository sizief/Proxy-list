# proxy-list  
A simple proxy list crawler by Ruby

## sources
This script crawls three proxy generator sites and generate a proxies.csv file contains list of all proxies  

## How to use  
```ruby
require proxy
proxy = Proxy.new
proxy.update #clean the proxies.csv file and create new fresh list
proxy.get #get a random proxy from the proxies.csv
```

