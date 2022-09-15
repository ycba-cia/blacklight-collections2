require 'rails_helper'

RSpec.describe BookCoverController, type: :controller do

  #8/14/19 failed spec

  describe "GET #show" do
    it "returns http success for openlibrary" do
      get :show, :params => { :isbn => '0521547903' }
      #get :show, isbn: '0521547903'
      expect(response).to have_http_status(:success)

      get :show, :params => { :isbn => '0521547903', :size => "medium" }
      #get :show, isbn: '0521547903'
      expect(response).to have_http_status(:success)

      get :show, :params => { :isbn => '0521547903', :size => "large" }
      #get :show, isbn: '0521547903'
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #show2" do
    it "returns http success for google cover image" do
      #stubbed_controller = BookCoverController.new
      #didn't trigger
        #allow(stubbed_controller).to receive(:openlibrary_cover_image).with("0521547903","small").and_return(nil)
      #deprecated
        #BookCoverController.any_instance.stub(:openlibrary_cover_image).with("0521547903","small").and_return(nil)
      #deprecated
        #controller.stub(:openlibrary_cover_image).with("0521547903","small").and_return(nil)
      allow_any_instance_of(BookCoverController).to receive(:openlibrary_cover_image).with("0521547903","small").and_return(nil)
      get :show, :params => { :isbn => '0521547903' }
      expect(response).to have_http_status(:success)

      allow_any_instance_of(BookCoverController).to receive(:openlibrary_cover_image).with("notvalid","small").and_return(nil)
      get :show, :params => { :isbn => 'notvalid' }
      expect(response).to have_http_status(302)
    end
  end

  describe "GET #show3" do
    it "returns http success for amazon cover image" do
      allow_any_instance_of(BookCoverController).to receive(:openlibrary_cover_image).with("0521547903","small").and_return(nil)
      allow_any_instance_of(BookCoverController).to receive(:google_cover_image).with("0521547903").and_return(nil)
      get :show, :params => { :isbn => '0521547903' }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #show4" do
    it "returns http 302 not matching" do
      allow_any_instance_of(BookCoverController).to receive(:openlibrary_cover_image).with("0521547903","small").and_return(nil)
      allow_any_instance_of(BookCoverController).to receive(:google_cover_image).with("0521547903").and_return(nil)
      allow_any_instance_of(BookCoverController).to receive(:amazon_cover_image).with("0521547903").and_return(nil)
      get :show, :params => { :isbn => '0521547903' }
      expect(response).to have_http_status(302)
    end
  end


  it 'should return expected openlibrary book cover' do
    isbn = "0316769487"
    openlibrary_size = "S"
    u = "http://covers.openlibrary.org/b/isbn/#{isbn}-#{openlibrary_size}.jpg"
    expect(BookCoverController.new.instance_eval{openlibrary_cover_image("0316769487","small")}).to eq(BookCoverController.new.instance_eval{return_image(u)})
  end

  #8/1/19 removing, remote failure retrieving
=begin
  it 'should return expected google book cover' do
    exp = "http://books.google.com/books/content?id=ZotvleqZomIC&printsec=frontcover&img=1&zoom=1&source=gbs_api"
    expect(BookCoverController.new.instance_eval{google_cover_image("0316769487")}).to eq(BookCoverController.new.instance_eval{return_image(exp)})
  end
=end

  #failed in travis build 1/30/18, removing, most likely a remote issue
=begin
  it 'should return expected amazon book cover' do
    isbn = "0316769487"
    u = "http://images.amazon.com/images/P/#{isbn}.01.20TRZZZZ.jpg"
    exp = "http://books.google.com/books/content?id=ZotvleqZomIC&printsec=frontcover&img=1&zoom=1&source=gbs_api"
    expect(BookCoverController.new.instance_eval{amazon_cover_image(isbn)}).to eq(BookCoverController.new.instance_eval{return_image(u)})
  end
=end
  #TODO this will fail, need to obtain a code https://www.drupal.org/node/872368 and put in local_env
=begin
  it 'should return expected syndetics book cover' do
    isbn = "0316769487"
    client_code = ENV['SYNDETICS_CLIENT_CODE']
    type = "rn12"
    u = "http://www.syndetics.com/index.aspx?isbn=#{isbn}/summary.html&client=#{client_code}&type=#{type}"
    expect(BookCoverController.new.instance_eval{syndetics_cover_image(isbn,type)}).to == eq(BookCoverController.new.instance_eval{return_image(u)})
  end
=end

  #shut off 3/17/2020, not used (see commented out code in book_cover_controller), there is a 1000/day limit anyway
=begin
  it 'should return expected librarything book cover' do
    isbn = "0316769487"
    devkey = ENV['LIBRARYTHING_DEV_KEY']
    u = "http://covers.librarything.com/devkey/#{devkey}/medium/isbn/#{isbn}"
    expect(BookCoverController.new.instance_eval{librarything_cover_image(isbn)}).to eq(BookCoverController.new.instance_eval{return_image(u)})
  end
=end

end
