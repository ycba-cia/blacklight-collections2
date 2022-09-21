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
      stub_request(:get, "https://manifests.collections.yale.edu/ycba/obj/34").
          with(
              headers: {
                  'Accept'=>'*/*',
                  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                  'User-Agent'=>'Ruby'
              }).
          to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','dort_iiif.json')), headers: {})
      stub_request(:get, "https://manifests.collections.yale.edu/ycba/orb/9452785").
          with(
              headers: {
                  'Accept'=>'*/*',
                  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                  'User-Agent'=>'Ruby'
              }).
          to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','helmingham_iiif.json')), headers: {})
      
      allow(controller).to receive(:get_solr_doc).and_return(document1)
      get :show, :params => { :id => 'tms:34', :size => 1, :index => 0 }
      expect(response).to have_http_status(:success)

      allow(controller).to receive(:get_solr_doc).and_return(document2)
      get :show, :params => { :id => 'orbis:9452785', :size => 1, :index => 0 }
      expect(response).to have_http_status(:success)
    end
  end

end