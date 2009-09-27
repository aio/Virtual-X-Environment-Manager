class VirtualMachinesController < ApplicationController
  # List all the VMs on all the host nodes in the cluster
  def index
    @host_nodes = HostNode.all
    @host_nodes.each do |hn|
      hn.getVMs
    end
  end

  # Create remote desktop for specific VM
  def vnc_client
    @vm = VirtualMachine.find(params[:host_ip], params[:id])
    @vm.create_vnc_proxy if @vm.type == 'qm'
    @vm.create_vnc_console if @vm.type == 'vz'
  end

  # Create monitor for specific QM VM
  def monitor
    @vm = VirtualMachine.find(params[:host_ip], params[:id])
    @vm.create_vnc_console if @vm.type == 'qm'
  end

  # Start up specific VM
  def start
    @vm = VirtualMachine.find(params[:host_ip], params[:id])
    @vm.start if @vm.stopped?
    flash[:message] = @vm.output
    redirect_to :action => 'index'
  end

  # Stop specific VM
  def stop
    @vm = VirtualMachine.find(params[:host_ip], params[:id])
    @vm.stop if @vm.running?
    flash[:message] = @vm.output
    redirect_to :action => 'index'
  end

end
