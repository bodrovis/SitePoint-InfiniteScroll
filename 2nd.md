## "Load more" button

Now lets implement a "Load more" button instead of an infinite scrolling. This solution may come in handy
when, for example, you have some links inside the footer that user could be interested in, however with endless
page the footer will continue to "run away" until all records are shown.

To demonstrate this I will modify the controller as follows:

*posts_controller.rb*

    def index
        get_and_show_posts
    end

    def index_with_button
        get_and_show_posts
    end

    private

    def get_and_show_posts
        @posts = Post.paginate(page: params[:page], per_page: 15).order('created_at DESC')
        respond_to do |format|
            format.html
            format.js
        end
    end

and add a route:

    get '/posts_with_button', to: 'posts#index_with_button', as: 'posts_with_button'

So that there are two independent pages that demonstrate two concepts.

*index_with_button.html.erb*

    <div class="page-header">
        <h1>My posts</h1>
    </div>

    <div id="my-posts">
        <%= render @posts %>
    </div>

    <div id="with-button">
        <%= will_paginate %>
    </div>

    <% if @posts.next_page %>
        <div id="load_more_posts" class="btn btn-primary btn-lg">More posts</div>
    <% end %>

The most of the view is the same. I only changed the id of the pagination wrapper (we will use it later to
write a proper condition) and added a `#load_more_posts` block that will be displayed as a button
with the help of Bootstrap. We want this button to be shown only if there are more pages available
(imagine situation where there is only one post in the blog - why would we need to render "Load more" button?).

This button should not be visible at first - we will show it with JavaScript; this way we keep fallback to the
default behaviour:

*application.css.scss*

    #load_more_posts {
        display: none;
        margin-bottom: 10px; /* Some margin to separate from the footer */
    }

Now lets add a new condition to our script:

*pagination.js.coffee*

    if $('#with-button').size() > 0
        $('.pagination').hide()
        loading_posts = false

        $('#load_more_posts').show().click ->
          unless loading_posts
            loading_posts = true
            more_posts_url = $('.pagination .next_page a').attr('href')
            $this = $(this)
            $this.html('<img src="/assets/ajax-loader.gif" alt="Loading..." title="Loading..." />').addClass('disabled')
            $.getScript more_posts_url, ->
              $this.text('More posts').removeClass('disabled') if $this
              loading_posts = false
          return

Here we are hiding the pagination block, showing the "Load more" button and binding a `click` event
handler to it. Also the `loading_posts` flag is used to prevent user clicking multiple times on the button.
In the event handler we are using the same concept as before: fetch a next page url, then add a 'loading'
image (and making the button look disabled) and submitting AJAX call to the server. We've also added a callback
that fires when response is recieved - this callback restores the button to its original state and sets
the flag to `false`.

And now the view:

*index_with_button.js.erb*

    $('#my-posts').append('<%= j render @posts %>');
    <% if @posts.next_page %>
        $('.pagination').replaceWith('<%= j will_paginate @posts %>');
        $('.pagination').hide();
    <% else %>
        $('.pagination, #load_more_posts').remove();
    <% end %>

Again we are appending new posts to the page, then render a new pagination (hiding it afterwards) if there are
more pages left or just removing the pagination and the button.

## Link to the particular page

We have discussed how to create an infinite scrolling and a "Load more" button instead of a simple pagination.
The one thing that you probably should think about - how a user can share a link to your website that leads
to the particular page? Right now there is no way to do this, because we do not change the URL - it is always
the same. In some cases this is unnecessary because a user still can share a link to a post, but sometimes
this can be an issue.

One of the possible ways to solve this problem is by changing a hash in the URL using JavaScript everytime the new
page is loaded. This will generate links like `http://localhost#page=2`. We can do this inside the callback
that is fired after `$.getScript` finishes loading the resource:

*pagination.js.coffee*

    page_regexp = /page=\d+/i
    $.getScript more_posts_url, ->
        # ...
        window.location.hash = more_posts_url.match(page_regexp)[0]

Do not forget that `more_posts_url` contains a link to the next page and we use it to fetch page number.
After that we can write a condition that fires on page load and checks if the hash contains page number.
If it does we can, for example, set a GET parameter with a page number and reload the page:

*pagination.js.coffee*

    hash = window.location.hash
    if hash.match(page_regexp)
        window.location.hash = '' # otherwise the hash will remain after reloading the page
        window.location.search = '?page=' + hash.match(/\d+/)

Probably it is a good idea to slightly modify the view so that pagination is displayed only when there is a next page
available (like we did with the "Load more" button), because otherwise when user enters a URL to go straight
to the last page, pagination will still be displayed and the JavaScript event handler will still be binded
however there are no records to show next.

*index.html.erb*

    <% if @posts.next_page %>
        <div id="infinite-scrolling">
            <%= will_paginate %>
        </div>
    <% end %>

This solution however leads to a problem when a user cannot load previous posts. You could implement a more complex
solution with a "Load previous" button or just display "Go to the first page" link. Also you can load
the records on the previous pages as well and render them all. Another way is to combine
a basic pagination that can be displayed on the top of the page and an infinite scrolling. This solves another
problem - what if our visitor wants to go to the last or, say, 31st page? Scrolling down and down (or clicking
"Load more" many times) will be very annoying for him. So we either should present him a way to jump to a desired page or
implement some filters (by date, category, views etc).

## Pagination and infinite scrolling

Lets implement the "combined" solution so that there is an infinite scrolling (or "Load more" button) present as well
as a basic pagination, which will be displayed on the top of the page. This will also work fine with JavaScript disabled -
our user will just see the pagination in two places, which isn't that bad.

Firstly, we add another pagination block to our views:

*index.html.erb* and *index_with_button.html.erb*

    <div class="page-header">
        <h1>My posts</h1>
    </div>

    <%= will_paginate %>

    [...]

After that we have to slightly modify the scripts so that only one pagination block is being referenced (I've placed
a comments near the modified lines):

*pagination.js.coffee*

    [...]

    if $('#infinite-scrolling').size() > 0
        $(window).bindWithDelay 'scroll', ->
          more_posts_url = $('#infinite-scrolling .next_page a').attr('href') # <--------
          if more_posts_url && $(window).scrollTop() > $(document).height() - $(window).height() - 60
            $('#infinite-scrolling .pagination').html( # <--------
              '<img src="/assets/ajax-loader.gif" alt="Loading..." title="Loading..." />')
            $.getScript more_posts_url, ->
              window.location.hash = more_posts_url.match(page_regexp)[0]
          return
        , 100

      if $('#with-button').size() > 0
        # Replace pagination
        $('#with-button .pagination').hide() # <--------
        loading_posts = false

        $('#load_more_posts').show().click ->
          unless loading_posts
            loading_posts = true
            more_posts_url = $('#with-button .next_page a').attr('href') # <--------
            if more_posts_url
              $this = $(this)
              $this.html('<img src="/assets/ajax-loader.gif" alt="Loading..." title="Loading..." />').addClass('disabled')
              $.getScript more_posts_url, ->
                $this.text('More posts').removeClass('disabled') if $this
                window.location.hash = more_posts_url.match(page_regexp)[0]
                loading_posts = false
          return

    [...]

*index.js.erb*

    $('#my-posts').append('<%= j render @posts %>');
    $('.pagination').replaceWith('<%= j will_paginate @posts %>');
    <% unless @posts.next_page %>
        $(window).unbind('scroll');
        $('#infinite-scrolling .pagination').remove();
    <% end %>

Inside `index.js.erb` we do not modify the 3rd line because we want pagination to update in both places so that
user knows where he is.

*index_with_button.js.erb*

    $('#my-posts').append('<%= j render @posts %>');
    $('.pagination').replaceWith('<%= j will_paginate @posts %>');
    <% if @posts.next_page %>
        $('#with-button .pagination').hide();
    <% else %>
        $('#with-button .pagination, #load_more_posts').remove();
    <% end %>

The same concept applies here. Also note that in both cases I have moved the `replaceWith` out of the conditional
statement. Now we want our pagination to be rewritten every time the next page is open. If we do not make this change
when the user opens the last page the top pagination will not be replaced - only the bottom one will be removed.




This brings us to the end of this article. I hope you've found some useful tips while reading it. Please share
your thoughts about the suggested solutions. Also it will be nice to know how do you solve the problem with
loading previous posts on your website. Thanks for reading, see you in future posts!