require 'rails_helper'

RSpec.describe CatalogController, :type => :controller do

  let(:solrdoc1) do
    SolrDocument.new(JSON.parse(File.open("spec/fixtures/dort.json","rb").read))
  end

  let(:solrdoc2) do
    SolrDocument.new(JSON.parse(File.open("spec/fixtures/helmingham.json","rb").read))
  end

  describe "GET #cite" do
    it "tests cite" do
      allow(SolrDocument).to receive(:find).with("34").and_return(solrdoc1)
      get :cite, :params => { :id => "34"}
      expect(response).to have_http_status(200)
    end
  end

  describe "GET #show" do
    it "tests getID" do
      stub_request(:get, "http://10.5.96.78:8983/solr/ycba_blacklight/get?ids=34&wt=json").
          with(
              headers: {
                  'Accept'=>'*/*',
                  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                  'User-Agent'=>'Faraday v2.7.11'
              }).
          to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','dort_BL.json')), headers: {})
      get :show, :params => { :id => "34"}
      expect(controller.getID).to be == "34"
    end
  end

  describe "handling econnrefused exeption" do
    controller do
      def index
        raise Blacklight::Exceptions::ECONNREFUSED
      end
    end
    it "renders econnrefused" do
      get :index
      expect(response).to have_http_status(200)
    end
  end

  describe "handling econnrefused exeption" do
    controller do
      def index
        raise Blacklight::Exceptions::RecordNotFound
      end
    end
    it "renders econnrefused" do
      get :index
      expect(response).to have_http_status(404)
    end
  end


  describe "#display_marc_field?" do
    it "returns" do
      context = Blacklight::Configuration::ShowField.new
      document = solrdoc1
      expect(controller.display_marc_field?(context,document)).to be == false
      document = solrdoc2
      expect(controller.display_marc_field?(context,document)).to be == true
    end
  end

  describe "#display_lido_field?" do
    it "returns" do
      context = Blacklight::Configuration::ShowField.new
      document = solrdoc1
      expect(controller.display_lido_field?(context,document)).to be == true
      document = solrdoc2
      expect(controller.display_lido_field?(context,document)).to be == false
    end
  end

  describe "#display_marc_accessor_field?" do
    it "returns" do
      context = Blacklight::Configuration::ShowField.new
      document = solrdoc1
      expect(controller.display_marc_accessor_field?(context,document)).to be == false
      document = solrdoc2
      expect(controller.display_marc_accessor_field?(context,document)).to be == false

      context = Blacklight::Configuration::ShowField.new(accessor: "type_acc")
      document = solrdoc1
      expect(controller.display_marc_accessor_field?(context,document)).to be == false
      document = solrdoc2
      expect(controller.display_marc_accessor_field?(context,document)).to be == true

    end
  end

  describe "#display_lido_accessor_field?" do
    it "returns" do
      context = Blacklight::Configuration::ShowField.new
      document = solrdoc1
      expect(controller.display_lido_accessor_field?(context,document)).to be == false
      document = solrdoc2
      expect(controller.display_lido_accessor_field?(context,document)).to be == false

      context = Blacklight::Configuration::ShowField.new(accessor: "type_acc")
      document = solrdoc1
      expect(controller.display_lido_accessor_field?(context,document)).to be == true
      document = solrdoc2
      expect(controller.display_lido_accessor_field?(context,document)).to be == false
    end
  end

  describe "#render_related_content?" do
    it "returns" do
      context = Blacklight::Configuration::ShowField.new
      document = solrdoc1
      expect(controller.render_related_content?(context,document)).to be == false
      document = solrdoc2
      expect(controller.render_related_content?(context,document)).to be == false

      #document = solrdoc2
      document = SolrDocument.new(recordtype_ss: ["marc"],resourceURL_ss: ["Related content to render"])
      expect(controller.render_related_content?(context,document)).to be == true
    end
  end

  describe "#isLidoLoan?" do
    it "returns" do
      context = Blacklight::Configuration::ShowField.new 
      document = SolrDocument.new(recordtype_ss: ["lido"])
      expect(controller.isLidoLoan?(context,document)).to be == false

      document = SolrDocument.new(recordtype_ss: ["lido"],callnumber_ss: ["L2022.1"])
      expect(controller.isLidoLoan?(context,document)).to be == true

      document = SolrDocument.new(recordtype_ss: ["lido"],callnumber_ss: ["B2022.1"])
      expect(controller.isLidoLoan?(context,document)).to be == false
    end
  end


end