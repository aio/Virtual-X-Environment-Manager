require 'socket'

CMD_VZ_START = "/usr/sbin/vzctl start "
CMD_QM_START = "/usr/sbin/qm start "
CMD_VZ_STOP = "/usr/sbin/vzctl stop "
CMD_QM_STOP = "/usr/sbin/qm stop "
CMD_VZ_LIST = "/usr/sbin/vzlist "
CMD_QM_LIST = "/usr/sbin/qm list "
CMD_VZ_LISTALL = "/usr/sbin/vzlist -a"
CMD_QM_LISTALL = "/usr/sbin/qm list"

class VirtualMachine
  attr_reader :buffer, 
              :status, 
              :type, 
              :name, 
              :vmid, 
              :hostname, 
              :ip_address,
              :vnc_port,
              :vnc_password 

  def initialize(type, vmid, name, status, ip_address, hostname)
    @type = type
    @vmid = vmid.to_i
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
    @buffer.gsub(/(\x0d|\x0a)/, '<br />') if @buffer
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

  def create_vnc_proxy
    port = VirtualMachine.next_vnc_port
    timeout = 30
    if port
      @vnc_port = port
      
      # generate random password
      chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
      @vnc_password = ""
      # password length is 8 as vnc server only accept 8 chars in maxium
      1.upto(8) { |i| @vnc_password << chars[rand(chars.size-1)] } 
      
      qmstr = "/usr/sbin/qm vncproxy #{@vmid} #{@vnc_password}"
      cmdstr = "/bin/nc -l -p #{@vnc_port} -w #{timeout} -c \"#{qmstr}\" & 2>1"
      # puts "cmd: #{cmdstr}"
      return system(cmdstr)
    end
  end
  
  def create_vnc_console
=begin
my ($class, $cid, $veid, $type, $userid, $status) = @_;

my $remip;
my $remcmd = [];

$userid = 'unknown' if !$userid;

my $cinfo = PVE::Cluster::clusterinfo ();

if ($cid != $cinfo->{local}->{cid}) {
  $remip = $cinfo->{"CID_$cid"}->{ip};
  $remcmd = ['/usr/bin/ssh', '-t', $remip];
}

my $port = __next_vnc_port ();
# generate ticket, olny first 8 character used by vnc
my $ticket = Digest::SHA1::sha1_base64 ($userid, rand(), time());

my $timeout = 1; # immediately exit when last client disconnects

my $realcmd = sub {
  my $upid = shift;
  
  syslog ('info', "starting vnc console $upid\n");
  
  # fixme: use ssl
  
  my $pwfile = "/tmp/.vncpwfile.$$";
  
  my $vzcmd;
  
  if ($type eq 'openvz') {
    if ($status eq 'running') {
      $vzcmd = [ '/usr/sbin/vzctl', 'enter', $veid ];
      } elsif ($status eq 'mounted') {
        $vzcmd = [ "/usr/bin/pvebash", $veid, 'root'];
        } else {
          $vzcmd = [ "/usr/bin/pvebash", $veid, 'private'];
          }
  } elsif ($type eq 'qemu') {
    $vzcmd = [ "/usr/sbin/qm", 'monitor', $veid ];
    } else {
      $vzcmd = [ '/bin/true' ]; # should not be reached
    }
      
  my @cmd = ('/usr/bin/vncterm', '-rfbport', $port,
  '-passwdfile', "rm:$pwfile",
  '-timeout', $timeout, '-c', @$remcmd, @$vzcmd);
  
  my $cmdstr = join (' ', @cmd);
  syslog ('info', "CMD: $cmdstr");
  
  my $fh = IO::File->new ($pwfile, "w", 0600);
  print $fh "$ticket\n";
  $fh->close;
  
  if (system (@cmd) != 0) {
    my $msg = "VM $veid console viewer failed - $?";
    syslog ('err', $msg);
    exit (-1);
    }
    
    exit (0);
    };
    
    if (my $uid = __fork_worker ('vncview', "$cid:$veid:$userid:$port:$ticket", $realcmd)) {
      
      #PVE::Config::update_file ("vncview", $uid);
      
      return { port => $port, ticket => $ticket};
    }
    
   return undef;
          
        
=end
    
  end
  
end
