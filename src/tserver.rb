require "java"

import "eu.webtoolkit.jwt.WtServlet"
import "eu.webtoolkit.jwt.Configuration"

import "org.apache.catalina.startup.Tomcat"
import "org.apache.catalina.connector.Connector"

require "rubygems"
require "active_support"

require "ripl"

$myconfig = ActiveSupport::JSON.decode(File.new(ARGV[ 0]).read)
File.open($myconfig["pidfile"], 'w') {|f| f.write(Process.pid.to_s+"\n")}

class MyServlet < WtServlet
  def createApplication(env)
    require $myconfig["servletfile"]
    Kernel.const_get($myconfig["servletclass"]).new(env)
  end
end

tomcat = Tomcat.new
tomcat.setBaseDir("/tmp")
con = Connector.new("org.apache.coyote.http11.Http11NioProtocol")

con.setPort($myconfig["port"])
tomcat.getService().addConnector(con)
tomcat.setConnector(con)

ctx = tomcat.addContext("", $myconfig["basedir"])

wrapper=tomcat.addServlet("", "jwt example", MyServlet.new)

if $myconfig.has_key?("jwt-config-file")
  wrapper.addInitParameter("jwt-config-file",$myconfig["jwt-config-file"])
end

if $myconfig.has_key?("applicationtype")
  wrapper.addInitParameter("ApplicationType",$myconfig["applicationtype"])
end
                                                
ctx.addServletMapping("/*", "jwt example")
ctx.addApplicationListener("eu.webtoolkit.jwt.ServletInit")

tomcat.start
puts
puts
puts "touch "+$myconfig["stopfile"] + Process.pid.to_s
puts
puts


Thread.new do
  while true
    Ripl.start
  end
end
            

while ! File.exists?($myconfig["stopfile"] + Process.pid.to_s)
  sleep 1
end

begin
  tomcat.stop
  tomcat.destroy
  puts "Tomcat stopped."
rescue
rescue java.lang.Throwable
end

File.unlink($myconfig["pidfile"])
File.unlink($myconfig["stopfile"] + Process.pid.to_s)
puts
puts "Stopped."
puts
