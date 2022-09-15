require 'rails_helper'

RSpec.describe VufindController, type: :controller do


  describe "GET #show" do

    it "returns http success" do
      allow(InterfaceMapping).to receive(:find_by).with({:vufind_id=>"1669755"}).and_return(:oai_id=>"oai:tms.ycba.yale.edu:5485")
      get :show, :params => { :vufind_id => 1669755 }
      expect(response).to have_http_status(301)
    end
  end

  describe "GET #oaicat" do
    it "return http success" do
      #the allow might work, but using get instead
      #allow(request).to receive(query_parameters).and_return({"verb"=>"GetRecord", "identifier"=>"oai:tms.ycba.yale.edu:5485", "metadataPrefix"=>"lido"})
      get :oaicat, :params => {"verb"=>"GetRecord", "identifier"=>"oai:tms.ycba.yale.edu:5485", "metadataPrefix"=>"lido"}
      #expect(response).to have_http_status(302)
      expect(response).to redirect_to("https://harvester-bl.britishart.yale.edu/oaicatmuseum/OAIHandler?identifier=oai%3Atms.ycba.yale.edu%3A5485&metadataPrefix=lido&verb=GetRecord")
    end
  end
end