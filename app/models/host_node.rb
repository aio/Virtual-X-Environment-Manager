class HostNode
  attr_reader :buffer,
              :id,
              :ip_address,
              :role,
              :state,
              :uptime,
              :load,
              :mem,
              :storage_root,
              :storage_data,
              :vms
  
  # Initialize the host node
  def initialize(id, ip_address, role, state, uptime, load, mem, storage_root, storage_data)
    @buffer = ''
    @id = id
    @ip_address = ip_address
    @role = role
    @state = state
    @uptime = uptime
    @load = load
    @mem = mem
    @storage_root = storage_root
    @storage_data = storage_data
    @vms = []
  end
  
  # Get Virtual Machines hosted on the host node
  def getVMs
    @vms = VirtualMachine.all(@ip_address)
  end
  
  # Get All host nodes in the cluster
  def self.all
    list = []
    cmdstr = CMD_CLUSTER_LIST
    IO.popen(cmdstr) do |f|
      f.read.each do |line|
        arr = line.gsub(': ', '  ').gsub(/\s{2,}/, '  ').gsub(/^\s*/, '').split('  ')
        list << HostNode.new(arr[0], arr[1], arr[2], arr[3], arr[4], arr[5], arr[6], arr[7], arr[8]) if arr.size == 9  and not line.include? 'ERROR'
      end
    end
    return list
  end
  
  def self.my_info
    info = {}
    cmdstr = CMD_CLUSTER_MYINFO
    IO.popen(cmdstr) do |f|
      f.read.each do |line|
        arr = line.split(' ')
        info = {:id => arr[0], :hostname => arr[1], :ip_address => arr[2], :role => arr[3]} if arr.size == 4
      end
    end
    return info
  end
end
