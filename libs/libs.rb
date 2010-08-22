class String

  def sluggerize
    # Negative lookups are messy.
    self.gsub(/\s/m, '-').gsub(/(?![A-Z0-9\-_])(.?)/im, '\3')
  end

end