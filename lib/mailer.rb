require 'action_mailer'

class Mailer < ActionMailer::Base
  Config = YAML.load File.read('config/mailer.yml')

  def fax
    recipients Config['recipient']
    subject Config['password']
    body Config['fax_number'] + "\n\n"
    from Config['sender']
    attach_pdf
  end

  protected
  def attach_pdf
    filename = "#{Date.today}.pdf"
    attachment :content_type => 'application/pdf',
      :filename => filename,
      :body => File.read(File.join(Config['pdf_tank'], filename))
  end
end
