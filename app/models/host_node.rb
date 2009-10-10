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
  def initialize(id, ip_address, role, state, uptime, load, mem, storage)
    @buffer = ''
    @id = id
    @ip_address = ip_address
    @role = role
    @state = state
    @uptime = uptime
    @load = load
    @mem = mem
    @storage = storage
    @vms = []
  end
  
  # Get Virtual Machines hosted on the host node
  def getVMs
    @vms = VirtualMachine.all(@ip_address)
  end
  
  # Get All host nodes in the cluster
  def self.all
    list = []
    version = '0.0'

    exec_result_by_line(CMD_PVE_VER) do |line|
      result = line.scan(/pve\-manager\/(\d+\.\d+)\//)
      version = result[0][0] if result.is_a? Array and result[0].is_a? Array     
    end

    if version <= '1.3'
      correct_cols = 9
    else
      correct_cols = 8
    end
    
    exec_result_by_line(CMD_CLUSTER_LIST) do |line|
      arr = line.gsub(': ', '  ').gsub(/\s{2,}/, '  ').gsub(/^\s*/, '').split('  ')
      list << HostNode.new(arr[0], arr[1], arr[2], arr[3], arr[4], arr[5], arr[6], arr[7]) if arr.size == correct_cols  and not line.include? 'ERROR'
    end
    
    return list
  end
  
  def self.my_info
    info = {}
    
    exec_result_by_line(CMD_CLUSTER_MYINFO) do |line|
      arr = line.split(' ')
      info = {:id => arr[0], :hostname => arr[1], :ip_address => arr[2], :role => arr[3]} if arr.size == 4
    end
    
    return info
  end
end
