require "net/ssh"

module SimpleSsh
  VERSION = '0.0.1'
  
  class SimpleSSH
    
    class << self
      def configure(options={})
        ssh = SimpleSsh::SimpleSSH.new(options)
        yield(ssh) if block_given?
        ssh
      end
    end # class methods end
    
    def initialize(options={})
       @hosts = options[:hosts] ||  []
       @cmds  = options[:cmds] || []
       @keys = options[:keys] || []
       @user = options[:user] || ""
    end
    
    attr_accessor :keys, :user
    
    def hosts
      @hosts ||= []
    end

    def cmds
      @cmds ||= []
    end
    
    def execute
      if block_given?
        @cmds.clear
        @result_by_cmd.clear
        yield(self)
      end

      results = {}
      @hosts.each do |host|
        results[host] = execute_cmds_on(user, host)
      end
      @result_by_host = results
    end
    
    attr_reader :result_by_host
    
    def result_by_cmd
      return @result_by_cmd if defined? @result_by_cmd and not @result_by_cmd.empty?
      
      @result_by_cmd = {}
      @result_by_host.each do |host, cmd_dict|
        cmd_dict.each do |cmd, res|
          @result_by_cmd[cmd] ||= {}
          @result_by_cmd[cmd][host]= res 
        end
      end
      @result_by_cmd
    end

    def to_s
      result_by_host.map do |host, cmd_dict|
        res = "#{host}:\n"
        cmd_dict.each do |cmd,cmd_res|
          res << "\t#{cmd}: #{cmd_res.split("\n").join("\n\t\t")}\n"
        end
        res
      end.join("")
    end
    
    def to_yaml(by=:host)
      require 'yaml' unless defined? YAML
      s = send "result_by_#{by.to_s}".to_sym
      YAML.dump(s)
    end
    
    def to_csv(sep=",")
      require "csv" unless defined? CSV
      csv = []

      cols = ["host", "cmd", "result"]
      csv << cols.join(sep)

      result_by_host.each do |host, cmd_dict|
        cmd_dict.each do |cmd, res|
          csv << (host + sep + cmd + sep + cmd_dict[cmd])
        end
      end

      csv.join("\n")
    end
    
    private
    
    def execute_cmds_on(user, host)
      result = {}
      begin
        Net::SSH.start( host, user, :keys => keys) do |ssh|
          @cmds.each do |cmd|
            begin
              result[cmd]= ssh.exec!(cmd).chomp
            rescue Exception => e
              $stderr.puts "Failed to execute #{cmd}"
            end
          end
        end
      rescue Exception => e
        $stderr.puts "Could not open connection #{user}@#{host} using private key #{keys}"
      end
      result
    end
  end
end
