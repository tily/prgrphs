xml.instruct! :xml, :version => '1.0'
xml.rss :version => "2.0", :"xmlns:atom" => "http://www.w3.org/2005/Atom" do
        xml.channel do
                xml.tag! "atom:link", :href => "http://#{request.host}/#{@user.screen_name}/feed", :rel => "self", :type => "application/rss+xml"
                xml.title "http://#{request.host}/#{@user.screen_name}"
                xml.description "http://#{request.host}/#{@user.screen_name}"
                xml.link "http://#{request.host}/#{@user.screen_name}"
                @paragraphs.each do |paragraph|
                        xml.item do
                                xml.title("http://#{request.host}/#{paragraph.user.screen_name}/#{paragraph.id}")
				if params[:type] == 'image'
					src = "http://#{request.host}/#{paragraph.user.screen_name}/#{paragraph.id}.png"
					src += "?glitch=true" if params[:glitch] == 'true'
					xml.description "<img style='display:none' src='#{src}'>"
				else
					xml.description markdown2html(paragraph.body)
				end
                                xml.link("http://#{request.host}/#{paragraph.user.screen_name}/#{paragraph.id}")
                                xml.pubDate paragraph.updated_at.rfc822
                                xml.guid({:isPermaLink => false}, "http://#{request.host}/#{paragraph.user.screen_name}/#{paragraph.id}##{paragraph.updated_at.to_i}")
                        end
                end
        end
end
