class VirtualMachinesController < ApplicationController
  def index
    @vms = VirtualMachine.all
  end

  def vnc_client
    @vm = VirtualMachine.find(params[:id])
  end

  def start
    @vm = VirtualMachine.find(params[:id])
    @vm.start if @vm.stopped?
    flash[:message] = @vm.output
    redirect_to :action => 'index'
  end

  def stop
    @vm = VirtualMachine.find(params[:id])
    @vm.stop if @vm.running?
    flash[:message] = @vm.output
    redirect_to :action => 'index'
  end

end
