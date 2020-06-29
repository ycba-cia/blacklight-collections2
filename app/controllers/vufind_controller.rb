class VufindController < ApplicationController

  def show
    vufind_id = params[:vufind_id]
    i = InterfaceMapping.find_by vufind_id: vufind_id
    oai_id = i[:oai_id]
    path = "/catalog/orbis:#{oai_id.split(":")[2]}" if oai_id.include?("orbis")
    path = "/catalog/tms:#{oai_id.split(":")[2]}" if oai_id.include?("tms")
    redirect_to path, status: 301
  end

  def oaicat
    params = request.query_parameters
    str = params.to_query
    url = "https://harvester-bl.britishart.yale.edu/oaicatmuseum/OAIHandler?#{str}"

    #message = "<p>Harvester has moved to a new endpoint: #{url}</p>"
    #render html: message.html_safe

    redirect_to url
  end
end

