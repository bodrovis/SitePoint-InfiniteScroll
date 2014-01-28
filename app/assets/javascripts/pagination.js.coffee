root = window ? global

jQuery ->
  if $('#infinite-scrolling').size() > 0
    $(root).bindWithDelay 'scroll', ->
      more_posts_url = $('.pagination .next_page a').attr('href')
      if more_posts_url && $(root).scrollTop() > $(document).height() - $(root).height() - 60
        $('.pagination').text("Loading posts...")
        $.getScript(more_posts_url)
      return
    , 100
    #$(window).scroll()

  if $('#with-button').size() > 0
    # Replace pagination
    $('.pagination').hide()
    loading_posts = false

    $('#load_more_posts').show().click ->
      unless loading_posts
        more_posts_url = $('.pagination .next_page a').attr('href')
        $this = $(this)
        $this.html('<img src="/assets/ajax-loader.gif" alt="Loading..." title="Loading..." />').addClass('disabled')
        loading_posts = true
        $.getScript more_posts_url, ->
          $this.text('More posts').removeClass('disabled') if $this
          loading_posts = false
      return

  return