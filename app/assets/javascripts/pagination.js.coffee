jQuery ->
  page_regexp = /page=\d+/i

  hash = window.location.hash
  if hash.match(page_regexp)
    window.location.hash = ''
    window.location.search = '?page=' + hash.match(/\d+/)

  if $('#infinite-scrolling').size() > 0
    $(window).bindWithDelay 'scroll', ->
      more_posts_url = $('.pagination .next_page a').attr('href')
      if more_posts_url && $(window).scrollTop() > $(document).height() - $(window).height() - 60
        $('#infinite-scrolling .pagination').html(
          '<img src="/assets/ajax-loader.gif" alt="Loading..." title="Loading..." />')
        $.getScript more_posts_url, ->
          window.location.hash = more_posts_url.match(page_regexp)[0]
      return
    , 100

  if $('#with-button').size() > 0
    # Replace pagination
    $('.pagination').hide()
    loading_posts = false

    $('#load_more_posts').show().click ->
      unless loading_posts
        loading_posts = true
        more_posts_url = $('.pagination .next_page a').attr('href')
        if more_posts_url
          $this = $(this)
          $this.html('<img src="/assets/ajax-loader.gif" alt="Loading..." title="Loading..." />').addClass('disabled')
          $.getScript more_posts_url, ->
            $this.text('More posts').removeClass('disabled') if $this
            window.location.hash = more_posts_url.match(page_regexp)[0]
            loading_posts = false
      return

  return