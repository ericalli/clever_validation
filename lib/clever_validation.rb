module CleverValidation
  def clever_validation_for(*params)
     options = params.extract_options!.symbolize_keys
     if object = options.delete(:object)
       objects = [object].flatten
     else
       objects = params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
     end
     count   = objects.inject(0) {|sum, object| sum + object.errors.count }
     unless count.zero?
       html = {}
       [:id, :class].each do |key|
         if options.include?(key)
           value = options[key]
           html[key] = value unless value.blank?
         else
           html[key] = 'cleverValidation'
         end
       end
       options[:object_name] ||= params.first
       options[:title] = "There are #{pluralize(count, 'error')} with your submission" unless options.include?(:title)
       options[:sub_title] ||= 'The errors occured with the following fields:' unless options.include?(:sub_title)
       
       if options[:effect].nil?
         effect = ""
       else       
         if [ 'shake', 'pulsate', 'highlight' ].include? options[:effect].downcase
           effect = options[:effect].downcase
           if options[:highlight_color].nil?
             highlight_color = "FFFF99"
           else
             highlight_color = options[:highlight_color]
           end
           if options[:duration].nil?
             duration = 2
           else
             duration = options[:duration]
           end
         end
       end
       
       error_messages = objects.map {|object| object.errors.collect{ |column,error| content_tag( :li, "- #{error} " + link_to("(show me)", "javascript:void(0);", {:onclick=>"#{render_effect(effect, column, options[:object_name], highlight_color, duration)} Effect.ScrollTo('#{cleanup_object(options[:object_name])}_#{column}', { offset: -35, queue: 'front' })", :id=> "showMeLink"}) ) } } 
       
       contents = ''
       contents << content_tag(options[:header_tag] || :h3, options[:title]) unless options[:title].blank?
       contents << content_tag(:p, options[:sub_title]) unless options[:sub_title].blank?
       contents << content_tag(:ul, error_messages)
       contents << link_to("Hide", "javascript:void(0);", {:onclick=>"Element.hide('cleverValidation');", :id=> "hideLink"})

       content_tag(:div, contents, html)
     else
       ''
     end
  end
  
  def render_effect(effect, column, object, highlight_color, duration)
    if effect == "highlight"
      highlight_color = 
      "new Effect.Highlight('#{cleanup_object(object)}_#{column}', { startcolor: '##{highlight_color}', duration: #{duration} });"
    elsif [ 'shake', 'pulsate', 'highlight' ].include? effect
      "new Effect.#{effect.capitalize}('#{cleanup_object(object)}_#{column}');"
    else
      ""
    end
  end
  
  def cleanup_object(object)
    object.gsub!(/[^\w\.\-]/, '_')
    return object.downcase
  end
    
end