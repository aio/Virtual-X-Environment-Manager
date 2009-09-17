CMD_VZ_START = "/usr/sbin/vzctl start "
CMD_QM_START = "/usr/sbin/qm start "
CMD_VZ_STOP = "/usr/sbin/vzctl stop "
CMD_QM_STOP = "/usr/sbin/qm stop "
CMD_VZ_LIST = "/usr/sbin/vzlist "
CMD_QM_LIST = "/usr/sbin/qm list "
CMD_VZ_LISTALL = "/usr/sbin/vzlist -a"
CMD_QM_LISTALL = "/usr/sbin/qm list"

class VirtualMachine
  attr_accessor :vmid, :hostname, :ip_address
  attr_reader :buffer, :status, :type, :name

  def initialize(type, vmid, name, status, ip_address, hostname)
    @type = type
    @vmid = vmid.to_i
    @name = name.to_s
    @status = status.to_s
    @ip_address = ip_address.to_s
    @hostname = hostname.to_s
    @output = ''
  end

  def running?
    @status == 'running' ? true : false
  end

  def stopped?
    @status == 'stopped' ? true : false
  end

  def start
    cmdstr = (@type == 'vz' ? CMD_VZ_START : CMD_QM_START)
    IO.popen(cmdstr + @vmid.to_s, 'r') do |f|
      @buffer = f.read
    end
  end

  def stop
    cmdstr = (@type == 'vz' ? CMD_VZ_STOP : CMD_QM_STOP)
    IO.popen(cmdstr + @vmid.to_s, 'r') do |f|
      @buffer = f.read
    end
  end

  def output
    @buffer.gsub(/(\x0d|\x0a)/, '<br />')
  end

  def self.find(vmid)
    vm = nil
    vm = VirtualMachine.getVZList(CMD_VZ_LISTALL + " | grep #{vmid}")[0]
    vm = VirtualMachine.getQMList(CMD_QM_LISTALL + " | grep #{vmid}")[0] if vm == nil

    return vm
  end

  def self.all
    return self.getVZList(CMD_VZ_LISTALL) + self.getQMList(CMD_QM_LISTALL)
  end

  def self.getVZList(cmdstr)
    list = []
    IO.popen(cmdstr, 'r') do |f|
      f.read.each do |line|
        arr = line.gsub(/\s+/, ' ').gsub(/^\s*/, '').split(' ')
        list << VirtualMachine.new('vz', arr[0], arr[4], arr[2], arr[3], arr[4]) if arr[0] =~ /\d{3}/ and arr.size == 5
      end
    end
    return list
  end

  def self.getQMList(cmdstr)
    list = []
    IO.popen(cmdstr, 'r') do |f|
      f.read.each do |line|
        arr = line.gsub(/\s+/, ' ').gsub(/^\s*/, '').split(' ')
        list << VirtualMachine.new('qm', arr[0], arr[1], arr[2], '', '') if arr[0] =~ /\d{3}/ and arr.size == 6
      end
    end
    return list
  end

end
