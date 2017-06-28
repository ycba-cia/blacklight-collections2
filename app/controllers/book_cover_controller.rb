require 'open-uri'

class BookCoverController < ApplicationController

  def show
    isbn = params[:isbn]
    size = params[:size] || 'small'
    image = openlibrary_cover_image(isbn, size)

    if image
      send_data image, type: 'image/jpeg', disposition: 'inline', filename: "#{isbn}.jpg"
    else
      redirect_to '/no_cover.png'
    end
  end

  private

  def openlibrary_cover_image(isbn, size)
    openlibrary_size = 'S'
    case size
      when 'medium'
        openlibrary_size = 'M'
      when 'large'
        openlibrary_size = 'L'
    end

    url = "http://covers.openlibrary.org/b/isbn/#{isbn}-#{openlibrary_size}.jpg"
    bytes = open(url).read
    bytes = nil if bytes.length < 1000  # received a 1x1 px image; cover not found
    bytes
  end

end
