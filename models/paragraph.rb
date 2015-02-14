class Paragraph
	include Mongoid::Document
	include Mongoid::Timestamps
	field :body, type: String
	field :published, type: Boolean
	belongs_to :user
	before_create do
		self.id = UUID.new.generate
	end
end
