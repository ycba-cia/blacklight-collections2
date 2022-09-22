require 'open-uri'

class BookCoverController < ApplicationController

  def show
    isbn = params[:isbn]
    size = params[:size] || 'small'

    openlibrary_image = openlibrary_cover_image(isbn, size)
    if openlibrary_image
      send_data openlibrary_image, type: 'image/jpeg', disposition: 'inline', filename: "#{isbn}.jpg"
    else
      google_image = google_cover_image(isbn)
      if google_image
        send_data google_image, type: 'image/jpeg', disposition: 'inline', filename: "#{isbn}.jpg"
      else
        amazon_image = amazon_cover_image(isbn)
        if amazon_image
          send_data amazon_image, type: 'image/jpeg', disposition: 'inline', filename: "#{isbn}.jpg"
        else
          ##TODO - commented out need to obtain a code https://www.drupal.org/node/872368
          #syndetics_image = syndetics_cover_image(isbn,"rn12")
          #if syndetics_image
          #  send_data syndetics_image, type: 'image/jpeg', disposition: 'inline', filename: "#{isbn}.jpg"
          #else
            #TODO - not implemented due to 1 call per second license agreement -https://www.librarything.com/services/keys.php
            #librarything_image = librarything_cover_image(isbn)
            #if librarything_image
            #  send_data syndetics_image, type: 'image/jpeg', disposition: 'inline', filename: "#{isbn}.jpg"
            #else
              redirect_to '/assets/not_available1.png'
            #end
        end
      end
    end
  end

  #private

  def return_image(url)
    bytes = URI.open(url).read
    bytes = nil if bytes.length < 1000  # received a 1x1 px image; cover not found
    bytes
  end

  def openlibrary_cover_image(isbn, size)
    openlibrary_size = 'S'
    case size
      when 'medium'
        openlibrary_size = 'M'
      when 'large'
        openlibrary_size = 'L'
    end

    url = "http://covers.openlibrary.org/b/isbn/#{isbn}-#{openlibrary_size}.jpg"
    return_image(url)
  end

  def google_cover_image(isbn)
    #u = "https://books.google.com/books?bibkeys=ISBN:"+isbn+"&jscmd=viewapi" #alternate
    u = "https://www.googleapis.com/books/v1/volumes?q=isbn:"+isbn
    j = JSON.load(URI.open(u))
    #j = open(u).string #alternate
    #puts "J:#{j}"
    if j && j["items"] && j["items"][0] && j["items"][0]["volumeInfo"] &&
        j["items"][0]["volumeInfo"]["imageLinks"] &&
          j["items"][0]["volumeInfo"]["imageLinks"]["thumbnail"]
      t = j["items"][0]["volumeInfo"]["imageLinks"]["thumbnail"]
    else
      return nil
    end
    return_image(t)
  end

  def amazon_cover_image(isbn)
    u = "http://images.amazon.com/images/P/#{isbn}.01.20TRZZZZ.jpg"
    #bytes = open(u,"mimeType" => "text/xml; charset=x-user-defined").read #alternate with header
    return_image(u)
  end

  #https://developers.exlibrisgroup.com/resources/voyager/code_contributions/SyndeticsStarterDocument.pdf
  #deprecated
=begin
  def syndetics_cover_image(isbn,type)
    client_code = ENV['SYNDETICS_CLIENT_CODE']
    u = "http://www.syndetics.com/index.aspx?isbn=#{isbn}/summary.html&client=#{client_code}&type=#{type}"
    return_image(u)
  end
=end

  #http://blog.librarything.com/main/2008/08/a-million-free-covers-from-librarything/
  #deprecated
=begin
  def librarything_cover_image(isbn)
    devkey = ENV['LIBRARYTHING_DEV_KEY']
    #EX: http://covers.librarything.com/devkey/KEY/medium/isbn/0545010225
    u = "http://covers.librarything.com/devkey/#{devkey}/medium/isbn/#{isbn}"
    puts "LT:"+u
    return_image(u)
  end
=end
end
