root = window ? global

jQuery ->
  if $('.pagination').size() > 0
    $(root).bindWithDelay 'scroll', ->
      url = $('.pagination .next_page a').attr('href')
      if url && $(root).scrollTop() > $(document).height() - $(root).height() - 50
        $('.pagination').text("Loading posts...")
        $.getScript(url)
      return
    , 100
    #$(window).scroll()

  return