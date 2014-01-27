class Post < ActiveRecord::Base
  attr_accessible :body, :title

  def timestamp
    created_at.strftime('%d %B %Y %H:%M:%S')
  end
end
