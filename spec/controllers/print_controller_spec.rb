require 'rails_helper'

RSpec.describe PrintController, type: :controller do

  let(:document1) do
    JSON.parse(File.open("spec/fixtures/dort.json","rb").read)
  end

  let(:document2) do
    JSON.parse(File.open("spec/fixtures/helmingham.json","rb").read)
  end

  describe "GET #show" do
    it "returns http success" do
      allow(controller).to receive(:get_solr_doc).and_return(document1)
      get :show, :params => { :id => 'tms:34', :size => 1, :index => 0 }
      expect(response).to have_http_status(:success)

      allow(controller).to receive(:get_solr_doc).and_return(document2)
      get :show, :params => { :id => 'orbis:9452785', :size => 1, :index => 0 }
      expect(response).to have_http_status(:success)
    end
  end

end