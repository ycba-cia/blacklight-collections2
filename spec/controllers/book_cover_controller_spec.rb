require 'rails_helper'

RSpec.describe BookCoverController, type: :controller do

  describe "GET #show" do
    it "returns http success" do
      get :show, :params => { :isbn => '0521547903' }
      #get :show, isbn: '0521547903'
      expect(response).to have_http_status(:success)
    end
  end

  it 'should return expected json from google book cover' do
    exp = "http://books.google.com/books/content?id=ZotvleqZomIC&printsec=frontcover&img=1&zoom=1&source=gbs_api"
    BookCoverController.new.instance_eval{google_cover_image("0316769487")}.should ==
        BookCoverController.new.instance_eval{return_image(exp)}
  end

end
