class VirtualMachine
  attr_accessor :vmid, :hostname, :status, :ip_address

  def initialize(vmid = nil, status = nil, ip_address = nil, hostname = nil)
    super
    @vmid = vmid.to_i
    @status = status.to_s
    @ip_address = ip_address.to_s
    @hostname = hostname.to_s
  end

  def self.all
    list = []
    IO.popen("/usr/sbin/vzlist -a", 'r') do |f|
      f.read.each do |line|
        arr = line.gsub(/\s+/, ' ').gsub(/^\s*/, '').split(' ')
        list << VirtualMachine.new(arr[0], arr[2], arr[3], arr[4]) if arr[0] =~ /\d{3}/ and arr.size == 5
      end
    end

    return list
  end
end
