class VufindController < ApplicationController

  def show
    vufind_id = params[:vufind_id]
    i = InterfaceMapping.find_by vufind_id: vufind_id
    oai_id = i[:oai_id]
    path = "/catalog/orbis:#{oai_id.split(":")[2]}" if oai_id.include?("orbis")
    path = "/catalog/tms:#{oai_id.split(":")[2]}" if oai_id.include?("tms")
    redirect_to path, status: 301
    end
  end
