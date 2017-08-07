class ItemMailer < ApplicationMailer
  default from: 'notifications@collections.ycba.yale.edu'

  def email_item(to_user)
    #@url  = 'http://example.com/login'
    @user = to_user
    @record_id = "http://localhost:3000/catalog/2066869/cite"
    mail(to: @user, subject: 'here is your YCBA record')
  end
end