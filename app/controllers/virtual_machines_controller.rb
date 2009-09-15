class VirtualMachinesController < ApplicationController
  def index
    @vms = VirtualMachine.all
  end
end
