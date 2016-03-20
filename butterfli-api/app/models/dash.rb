class Dash < ActiveRecord::Base
	belongs_to :user
	has_many :posts


# Scraper Methods
# - - - - - - - - - - - - - - - - - - - - -
	def scraper(network, search)
	    unless !network && !search
	      case network
	      when 'twitter'
	      	parameters = ["en", 'images']
	        self.twitter_pic_scrape(search, parameters)
	      when 'giphy'
	      	parameters = ['']
	        self.giphy_scrape(search, parameters)
	      when 'tumblr'
	        self.tumblr_pic_scrape(search)
	      when 'reddit'
	        self.reddit_pic_scrape(search)
	      end
	    end		
	end
	def giphy_scrape(search, type)
		begin
		    self.giphy_search = search.downcase
		    self.save
			search = search ? search : self.giphy_search
			sanitize = search.tr(" ", "+");
			puts search
			
			key = "dc6zaTOxFJmzC"
			if type == 'stickers'
				url = "http://api.giphy.com/v1/stickers/search?q=" + sanitize + "&api_key=" + key
			elsif type == 'translate'
				url = "http://api.giphy.com/v1/gifs/translate?q=" + sanitize + "&api_key=" + key
			else
				url = "http://api.giphy.com/v1/gifs/search?q=" + sanitize + "&api_key=" + key
			end
			resp = Net::HTTP.get_response(URI.parse(url))
			buffer = resp.body
			result = JSON.parse(buffer)
			puts "results: ", result['data']
			temp = []
			pic_limit = 0
			pic_fail = 0
			count = 0
			result['data'].each do |x|
				temp.push(x["images"]["fixed_height"]["url"])
			end	
			puts temp
			temp.each do |post|
				self.build_post("giphy", post, nil, post, "giphy", post)
			end
			return temp 
		rescue
			return nil
		end
	end
	def reddit_pic_scrape(sub)
	    self.subreddit = sub.downcase
	    # term_arr = search_term.split(",")
	    self.save
		subredd = sub ? sub : self.subreddit
		reddit_api_url = "https://www.reddit.com/r/"+ subredd +".json"
		resp = Net::HTTP.get_response(URI.parse(reddit_api_url))
		data = resp.body
		result = JSON.parse(data)
		count = 0
		result["data"]["children"].each do |post|
			# puts post.to_json
			begin
				puts post["data"]["preview"]["images"].first["source"]["url"]
				puts post["data"]["title"]
				self.build_post("reddit", post["data"]["preview"]["images"].first["source"]["url"], post["data"]["title"], post["data"]["preview"]["images"].first["source"]["url"], post["data"]["preview"]["images"].first["source"], post["data"]["preview"]["images"].first["source"]["url"])
				count += 1
			rescue
				puts "nope"
			end
		end
		return count
	end	
	def twitter_pic_scrape(search, parameters)
	    self.twitter_pic_search = search.downcase
	    puts "encoded: ", URI::encode(self.twitter_pic_search)
	    self.save		
		t = self.get_twit_client
		search_var = search + " -rt"
		pic_limit = 0
		pic_fail = 0
		count = 0
		t.search(search_var, options = {}).collect do |tweet|
			puts 'tweet', tweet.to_json
			puts 'index', count
			count += 1
			unless tweet.media[0].nil?
				puts 'url', tweet.media[0].media_url
				if pic_limit < 25
					img = tweet.media[0].media_url
					post_build = self.build_post("twitter", img, tweet.text, img, img, tweet.id)
					puts 'post build: ' + post_build.to_s 
					if post_build
						puts 'pic count: ' + pic_limit.to_s
						pic_limit += 1
					else
						pic_fail += 1
					end
				else
					puts 'breakin out!'
					break
				end
					puts 'we skipped ' + pic_fail.to_s + ' pics that youve already seen. '
					puts 'searched ' + count.to_s + ' tweets and found ' + pic_limit.to_s + ' pics for ya!'

					if pic_limit == 0
						puts 'you should try and diversify your search! nothing to see here..'
					end
			end
		end	 		
	end
	def tumblr_pic_scrape(search)
		sanitize = search.tr(" ", "+");
		tum = self.get_tumblr_client
		client = Tumblr::Client.new
		puts 'string sanitized: ', sanitize
		img = client.tagged(sanitize)
		begin
			img.each do |post|
				puts post
				og_id = post["id"]
				author = post["post_author"]
				message = post["summary"]
				extracted_img = post['photos'][0]['alt_sizes'][0]['url']
				self.build_post("tumblr", extracted_img, message, extracted_img, author, og_id)
			end
		rescue
			puts "nope. tumblr_pic_scrape failed."
		end
	end

	def tumblr_blog_scrape(blog)
		tum = self.get_tumblr_client
		client = Tumblr::Client.new
		img = client.posts(blog + ".tumblr.com", :type => "photo", :limit => 50)["posts"]
		begin
			img.each do |post|
				puts post
				og_id = post["id"]
				author = post["post_author"]
				message = post["summary"]
				extracted_img = post['photos'][0]['alt_sizes'][0]['url']
				self.build_post("tumblr", extracted_img, message, extracted_img, author, og_id)
			end
		rescue
			puts "nope. tumblr_pic_scrape failed."
		end
	end



# Posting Methods
# - - - - - - - - - - - - - - - - - - - - -
	def post_tweet(post)
		twitCli = self.get_twit_client
		post = Post.find(post)
		puts post
		begin
			img = open(post.og_source)
			puts img
			if img.is_a?(StringIO)
			  ext = File.extname(url)
			  name = File.basename(url, ext)
			  Tempfile.new([name, ext])
			else
			  img
			end		
			post.twit_published += 1
			post.save
			body = post.body.to_s
			body_short = self.shorten(body, 90)
			res = twitCli.update_with_media(body_short, img)
		rescue => e
			puts e
			return 'tried'
		end
	end
	def post_tumblr(post)
		tumblr_client = self.get_tumblr_client
		@post = Post.find(post)
		@client = Tumblr::Client.new
		begin
			url = @post.og_source
			img = URI.parse(@post.image_src)
			blog_name = self.tumblr_blog_name
			uri = blog_name + ".tumblr.com"
			res = @client.photo(uri, caption: @post.body, source: img)
			if res["status"] == 401
				return 'tried'
			end
			@post.tumblr_published += 1
			@post.save
		rescue
			return 'tried'
		end
	end
	def post_content(post, network)
	    if !post
	      post = Post.all.where(dash_id: self.id, approved: true).shuffle.first.id      
	    end
	    case network
	    when 'twitter'
	    	self.post_tweet(post)
	    when 'tumblr'
	    	self.post_tumblr(post)
    	end
	end

	# Edit post body content
	def edit_post_body_content(post, body)
    	@post = Post.find(post)
    	@post.body = body
    	@post.save
	end




# Favorite Methods
# - - - - - - - - - - - - - - - - - - - - -	

	def like_content(network, post)
		network = post['title'].to_s
    	post_id = post.og_id
	    case network
	    when 'twitter'
	    	@client = self.get_twit_client
	    	@client.favorite(post_id)
	    when 'tumblr'
	    	@client = self.get_tumblr_client
	    	@client.favorite(post_id)
	    end
	end	


#Build Methods	
# - - - - - - - - - - - - - - - - - - - - -
	def build_post(title, src, body, image, author, og_id)
		p = self.posts.build(title: title, og_source: src, body: body, image_src: image, author: author, og_id: og_id)		
		p.save
		if p.save
			puts 'post saved!'
			return true
		else
			puts 'post didnt save!'
			return false
		end
	end




# Auth Methods
# - - - - - - - - - - - - - - - - - - - - -	
	def get_twit_client
		twitCli = Twitter::REST::Client.new do |config|
		  config.consumer_key        = self.twit_consumer_key
		  config.consumer_secret     = self.twit_consumer_secret
		  config.access_token        = self.twit_access_token
		  config.access_token_secret = self.twit_access_token_secret
		end
		return twitCli
	end
	def get_tumblr_client
		tumblr = Tumblr.configure do |config|
			  config.consumer_key = self.tumblr_consumer_key
			  config.consumer_secret = self.tumblr_consumer_secret
			  config.oauth_token = self.tumblr_oauth_token
			  config.oauth_token_secret = self.tumblr_oauth_token_secret
			end
		return tumblr
	end
	def get_postmark_client
		@postmark_client = Postmark::ApiClient.new(ENV['POSTMARK_API_KEY'])
		return @postmark_client
	end
	def fb_oauth
	    app_id = self.fb_app_id
	    app_secret = self.fb_app_secret
	    callback_url = "http://butterfli.herokuapp.com/dashes/#{self.id}/fb_set_token"
	    @oauth = Koala::Facebook::OAuth.new(app_id, app_secret, callback_url)
	    oauth_url = @oauth.url_for_oauth_code
	    puts oauth_url
	    return oauth_url 		
	end
	def fb_set_token(code)
	    app_id = self.fb_app_id
	    app_secret = self.fb_app_secret
	    callback_url = "http://butterfli.herokuapp.com/dashes/#{self.id}/fb_set_token"
	    @oauth = Koala::Facebook::OAuth.new(app_id, app_secret, callback_url)
		access_token = @oauth.get_access_token(code)
		self.fb_oauth_access_token = access_token
		self.save
	end



# UTIL
# - - - - - - - - - - - - - - - - - - - - -
	def shorten(body, len)
		puts 'Shortening!'
		puts body.length
		if body.length > len.to_i
			len = len.to_i - 3
			body = body.slice(0, len.to_i)
			body += "..."
			puts body
		end
		return body
	end

	def limiter(network)
		
	end

	
end
# - - - - - - - - - - - - - - - - - - - - -