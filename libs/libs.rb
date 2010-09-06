class String

  def sluggerize
    # Negative lookups are messy.
    self.gsub(/\s/m, '-').gsub(/(?![A-Z0-9\-_])(.?)/im, '\3')
  end

  # This is rudimentary!
  def pluralize(num=false, plural=nil)
    plural ||= "#{self}es" if self =~ /.*s$/ 
    plural ||= "#{self}s"
    return (!num || num.nil?) || num.to_i != 1 ? plural : self
  end

end


class Numeric

  def commify(n=false, max=false, title='', char='%.01f', plus=true)
    self.to_s =~ /([^\.]*)(\..*)?/
    int, dec = $1.reverse, $2 ? $2 : ""
    loop { break unless int.gsub!(/(,|\.|^)(\d{3})(\d)/, '\1\2,\3') }
    int = int.reverse + dec

    if (max && (max === true || max <= n.to_i) && n.to_i >= 1000)
      if (n.to_i >= 1000000000)
        num = sprintf(char, (n.to_i/100000000.to_f))
        ext = 'b'
      elsif (n.to_i >= 1000000)
        num = sprintf(char, (n.to_i/1000000.to_f))
        ext = 'm'
      else (n.to_i >= 1000)
        num = sprintf(char, (n.to_i/1000.to_f))
        ext  = 'k'
      end
    
      num.to_s =~ /([^\.]*)(\..*)?/
      num, dec = $1.reverse, $2 ? $2 : ""
      while num.gsub!(/(,|\.|^)(\d{3})(\d)/, '\1\2,\3')
      end
      num = num.reverse + dec
    
      str = "#{num}<span class='num_ext'>#{ext}</span>#{plus ? "<span class='num_plus'>+</span>" : ''}"
    else
      str = int
    end
    "<span title='#{int} #{title}'>#{str}</span>"
  end

end