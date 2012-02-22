require "net/ssh"

module SimpleSsh
  VERSION = '0.0.2'

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
      @result_by_host = {}
    end

    attr_accessor :user
    attr_reader :result_by_host

    def hosts
      @hosts ||= []
    end

    def cmds
      @cmds ||= []
    end

    def keys
      @keys ||= []
    end

    def execute
      if block_given?
        @cmds.clear
        yield(self)
      end

      results = {}
      hosts.each do |host|
        @result_by_host[host] = execute_cmds_on(@user, host)
      end
      result_by_host
    end

    def result_by_cmd
      result = {}
      result_by_host.each do |host, cmd_dict|
        cmd_dict.each do |cmd, res|
          result[cmd] ||= {}
          result[cmd][host]= res
        end
      end
      result
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
        Net::SSH.start( host, user, :keys => @keys) do |ssh|
          @cmds.each do |cmd|
            begin
              channel = ssh.open_channel do |channel|
                channel.exec(cmd) do |ch, success|
                  ch.on_data do |ch,data|
                    result[cmd] = data.chomp
                  end
                  ch.on_extended_data do |ch, type, data|
                    result[cmd] = data.chomp
                  end
                end
              end
            rescue Exception => e
              $stderr.puts "Failed to execute #{cmd}"
            end
          end
        end
      rescue Exception => e
        $stderr.puts "Could not open connection #{user}@#{host} using private key #{@keys}"
        raise
      end
      result
    end
  end
end
