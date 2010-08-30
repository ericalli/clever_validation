module CleverValidation
  
  class << self
    def config
      @config ||= {
        :js_library => nil
      }
    end
  end
  
  def clever_validation_for(*params)
    options = params.extract_options!.symbolize_keys
          
    if object = options.delete(:object)
      objects = [object].flatten
    else
      objects = params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
    end
    
    count = objects.inject(0) {|sum, object| sum + object.errors.count }
    unless count.zero?
        html = {}
        [:id, :class].each do |key|
          if options.include?(key)
            value = options[key]
            html[key] = value unless value.blank?
          else
            html[key] = 'clever_validation'
          end
      end
       
      options[:js_library]       ||= CleverValidation.config[:js_library] || "jquery"
      options[:effect]           ||= "highlight" unless options.include?(:effect)
      options[:object_name]      ||= params.first
      options[:title]            ||= "Uh oh! There are #{pluralize(count, 'error')} with your submission." unless options.include?(:title)
      options[:sub_title]        ||= 'The errors occured on the following fields:' unless options.include?(:sub_title)
      options[:show_me_text]     ||= "show me" unless options.include?(:show_me_text)
      options[:highlight_color]  ||= "FFFF99" unless options.include?(:highlight_color)
      options[:duration]         ||= 2 unless options.include?(:duration)
       
       if ['shake', 'pulsate', 'highlight'].include? options[:effect].downcase
         effect = options[:effect].downcase       
       else
         effect = "highlight"
       end
     
       if options[:js_library] == "prototype" 
         hide_link  = link_to("Hide", "javascript:;", {:onclick=>"Element.hide('clever_validation');", :id=> "hide_link"})
       elsif options[:js_library] == "jquery"
         hide_link  = link_to("Hide", "javascript:;", {:onclick=>"$('#clever_validation').hide();", :id=> "hide_link"})
       end
     
       error_messages = objects.map {|object| object.errors.collect{ |column,error| content_tag( :li, "#{error} " + link_to("#{options[:show_me_text]}", "javascript:;", {:onclick=>"#{render_effect(options[:js_library], effect, column, options[:object_name], options[:highlight_color], options[:duration])}", :class => "show_me_link"}) ) } } 
     
       contents = ''
       contents << content_tag(options[:header_tag] || :h3, options[:title])
       contents << content_tag(:p, options[:sub_title])
       contents << content_tag(:ul, error_messages)
       contents << hide_link

       content_tag(:div, contents, html)
   else
     ''
   end
  end

  def render_effect(js_library, effect, column, object, highlight_color, duration)
    if js_library == "prototype"
      scroll_effect = "Effect.ScrollTo('#{cleanup_object(object)}_#{column}', { offset: -35, queue: 'front' })"
      if effect == "highlight"
        highlight_color = 
        "new Effect.Highlight('#{cleanup_object(object)}_#{column}', { startcolor: '##{highlight_color}', duration: #{duration} }); #{scroll_effect}"
      elsif [ 'shake', 'pulsate' ].include? effect
        "new Effect.#{effect.capitalize}('#{cleanup_object(object)}_#{column}'); #{scroll_effect}"
      end
    else
      scroll_effect = "$('html, body').animate({ scrollTop: $('#'+'#{cleanup_object(object)}_#{column}').offset().top -35}, 1000);"      
      if effect == "highlight"
        highlight_color = 
        "$(document).ready(function() { $('#'+'#{cleanup_object(object)}_#{column}').effect('highlight', { color: '##{highlight_color}' }, 2500); }); #{scroll_effect}"
      elsif [ 'shake', 'pulsate' , 'bounce' ].include? effect
        "$(document).ready(function() { $('#'+'#{cleanup_object(object)}_#{column}').effect('#{effect}', { times:3 }, 4000); }); #{scroll_effect}"      
      end
    end
  end
  
  def cleanup_object(object)
    object.gsub!(/[^\w\.\-]/, '_')
    return object.downcase
  end
    
end