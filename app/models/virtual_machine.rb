class VirtualMachine
  attr_accessor :vmid, :hostname, :status, :ip_address
  attr_reader :buffer

  def initialize(vmid = nil, status = nil, ip_address = nil, hostname = nil)
    @vmid = vmid.to_i
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
    IO.popen("/usr/sbin/vzctl start #{@vmid}", 'r') do |f|
      @buffer = f.read
    end
  end

  def stop
    IO.popen("/usr/sbin/vzctl stop #{@vmid}", 'r') do |f|
      @buffer = f.read
    end
  end

  def output
    @buffer.gsub(/(\x0d|\x0a)/, '<br />')
  end

  def self.find(vmid)
    vm = nil
    IO.popen("/usr/sbin/vzlist -a | grep #{vmid}", 'r') do |f|
      f.read.each do |line|
        arr = line.gsub(/\s+/, ' ').gsub(/^\s*/, '').split(' ')
        vm = VirtualMachine.new(arr[0], arr[2], arr[3], arr[4]) if arr[0] =~ /\d{3}/ and arr.size == 5
      end
    end

    return vm

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
