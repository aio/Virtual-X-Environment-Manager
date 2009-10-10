require 'socket'

class VirtualMachine
  attr_reader :buffer,
              :id, 
              :status, 
              :type, 
              :name, 
              :host_ip,
              :hostname, 
              :ip_address,
              :vnc_port,
              :vnc_password 

  def initialize(type, id, host_ip, name, status, ip_address, hostname)
    @type = type
    @id = id.to_i
    @host_ip = host_ip
    @name = name.to_s
    @status = status.to_s
    @ip_address = ip_address.to_s
    @hostname = hostname.to_s
    @vnc_port = 0
    @vnc_password = ''
    @buffer = ''
  end

  def running?
    @status == 'running' ? true : false
  end

  def stopped?
    @status == 'stopped' or @status == 'mounted' ? true : false
  end

  def start
    if @host_ip == IPSocket.getaddress(Socket.gethostname)
      prefix = ''
    else
      prefix = "#{CMD_SSH_EXEC} #{host_ip} " 
    end
    
    cmdstr = "#{prefix} #{(@type == 'vz' ? CMD_VZ_START : CMD_QM_START)} #{@id.to_s}"
    
    @buffer = exec_result(cmdstr)
    
  end

  def stop
    if @host_ip == IPSocket.getaddress(Socket.gethostname)
      prefix = ''
    else
      prefix = "#{CMD_SSH_EXEC} #{host_ip} " 
    end
    
    cmdstr = "#{prefix} #{(@type == 'vz' ? CMD_VZ_STOP : CMD_QM_STOP)} #{@id.to_s}"
    @buffer = exec_result(cmdstr)
  end

  def output
    @buffer.gsub(/(\x0d|\x0a)/, '<br />') if @buffer
  end
  
  # Get the KVM/QEMU or OpenVZ VM on specific host node
  # Parameters:
  #   host_ip: IP Address of the host node
  #   id: VMID for the virtual machine
  # Return:
  #   Object of class VirtualMachine
  def self.find(host_ip, id)
    if host_ip == IPSocket.getaddress(Socket.gethostname)
      prefix = ''
    else
      prefix = "#{CMD_SSH_EXEC} #{host_ip} " 
    end
    vm = nil
    vm = VirtualMachine.getVZList(host_ip, prefix + CMD_VZ_LISTALL + " | grep #{id}")[0]
    vm = VirtualMachine.getQMList(host_ip, prefix + CMD_QM_LISTALL + " | grep #{id}")[0] if vm == nil

    return vm
  end

  # Get all KVM/QEMU and OpenVZ VMs on specific host node
  #   host_ip: IP Address of the host node
  # Return:
  #   List of VirtualMachine Objects  
  def self.all(host_ip)
    if host_ip == IPSocket.getaddress(Socket.gethostname)
      prefix = ''
    else
      prefix = "#{CMD_SSH_EXEC} #{host_ip} " 
    end
    return self.getVZList(host_ip, prefix + CMD_VZ_LISTALL) + self.getQMList(host_ip, prefix + CMD_QM_LISTALL)
  end

  # Get all OpenVZ VMs on specific host node
  #   host_ip: IP Address of the host node
  #   cmdstr: command string to execute
  # Return:
  #   List of VirtualMachine Objects
  def self.getVZList(host_ip, cmdstr)
    list = []
    
    exec_result_by_line(cmdstr) do |line|
      arr = line.gsub(/\s+/, ' ').gsub(/^\s*/, '').split(' ')
      list << VirtualMachine.new('vz', arr[0], host_ip, arr[4], arr[2], arr[3], arr[4]) if arr[0] =~ /\d{3}/ and arr.size == 5  # type, id, host_ip, name, status, ip_address, hostname
    end
    
    return list
  end

  # Get all KVM/QEMU VMs on specific host node
  #   host_ip: IP Address of the host node
  #   cmdstr: command string to execute
  # Return:
  #   List of VirtualMachine Objects
  def self.getQMList(host_ip, cmdstr)
    list = []
    
    exec_result_by_line(cmdstr) do |line|
      arr = line.gsub(/\s+/, ' ').gsub(/^\s*/, '').split(' ')
      list << VirtualMachine.new('qm', arr[0], host_ip, arr[1], arr[2], '', '') if arr[0] =~ /\d{3}/ and arr.size == 6  # type, id, host_ip, name, status, ip_address, hostname
    end
    
    return list
  end

  # Get available TCP port for vnc proxy
  # Return:
  #   Integer value of the TCP port available
  def self.next_vnc_port
    for port in 5900..6000 do
      no_err = true
      begin
        sock = TCPServer.new('localhost', port)
      rescue Exception => e
        no_err = false
      end
      
      if no_err
        sock.close
        return port
      end
    end
    
    return nil
  end

  # Create VNC proxy for KVM/QM VM desktop
  # Return:
  #   Integer value of the execution result
  def create_vnc_proxy
    port = VirtualMachine.next_vnc_port
    timeout = 30
    
    if @host_ip == IPSocket.getaddress(Socket.gethostname)
      prefix = ''
    else
      prefix = "#{CMD_SSH_BATCH} #{@host_ip} " 
    end
    
    if port
      @vnc_port = port
      
      # generate random password
      chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
      @vnc_password = ""
      # password length is 8 as vnc server only accept 8 chars in maxium
      1.upto(8) { |i| @vnc_password << chars[rand(chars.size-1)] } 
      
      qmstr = "/usr/sbin/qm vncproxy #{@id} #{@vnc_password}"
      cmdstr = "/bin/nc -l -p #{@vnc_port} -w #{timeout} -c \"#{prefix} #{qmstr}\" 2>/dev/null &"
      puts "cmd: #{cmdstr}"
      return system(cmdstr)
    end
  end
  
  # Create VNC proxy for OpenVZ VM console
  # Return:
  #   Integer value of the execution result
  def create_vnc_console
    if @host_ip == IPSocket.getaddress(Socket.gethostname)
      prefix = ''
    else
      prefix = "#{CMD_SSH_EXEC} #{@host_ip} " 
    end
    
    port = VirtualMachine.next_vnc_port
    timeout = 1
    if port and self.running?
      @vnc_port = port
      
      # generate random password
      chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
      @vnc_password = ""
      # password length is 8 as vnc server only accept 8 chars in maxium
      1.upto(8) { |i| @vnc_password << chars[rand(chars.size-1)] } 
      
      pwdfile = "/tmp/.vncpwd.#{rand()}"
      
      File.open(pwdfile, 'w') {|f| f.write(@vnc_password)}
      
      if @type == 'vz'
        if @status == 'running'
          vzcmd = "/usr/sbin/vzctl enter #{@id}"
        elsif @status == 'mounted'
          vzcmd = "/usr/bin/pvebash #{@id} root"
        else
          vzcmd = "/usr/bin/pvebash #{@id} private"
        end
      elsif @type == 'qm'
        vzcmd = "/usr/sbin/qm monitor #{@id}"
      else
        vzcmd = "/bin/true"  # should not be reached
      end
      
      cmdstr = "/usr/bin/vncterm -rfbport #{@vnc_port} -passwdfile rm:#{pwdfile} -timeout #{timeout} -c #{prefix} #{vzcmd} &";
      
      puts "cmd: #{cmdstr}"
      return system(cmdstr)
    end
    
  end
  
end
