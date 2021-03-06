home_index_link = (type, tag) ->
  typePart = if type == 'popular' then '' else "/#{type}"
  tagPart = if tag == 'all' then '' else "/tags/#{tag}"

  link = typePart + tagPart

  if link.length == 0
    return '/'

  return link

load_index = (type, tag, push, load) ->
  existingType = $('body').data('type')
  existingTag = $('body').data('tag')

  if existingType == type and existingTag == tag
    return

  if not type?
    type = existingType

  if not tag?
    tag = existingTag
  
  $('body').data 'type', type
  $('body').data 'tag', tag

  $(".selectable.tag-b").removeClass('selected')
  $(".selectable.type-b").removeClass('selected')
  $(".selectable.tag-b[data-val=\"#{tag}\"]:first").addClass('selected')
  $(".selectable.type-b[data-val=\"#{type}\"]").addClass('selected')
  
  url = home_index_link(type, tag)

  window.history.pushState { type: type, tag: tag }, "", url if push
  _gaq.push(['trackPageview', url])
  document.title = "#{type[0].toUpperCase()}#{type[1..]} #{if tag? and tag != "all" then tag else ""} modules - Node.JS Modules"

  return unless load

  $('#modules').addClass('exit')

  replace = null
  run = false

  setTimeout (->
    replace() if replace?
    run = true), 400

  $('#loading').addClass('visible')
  if url == "/"
    url = "/popular"
  $.get url + "/partial", (content) ->
    $('#loading').removeClass('visible')
    replace = () ->
      $('#modules').remove()
      $('#main').append(content)
      modules = $('#modules')
      modules.addClass('enter')
      
      # force the style to be recalculated for the transition: 
      # http://stackoverflow.com/questions/3969817/css3-transitions-to-dynamically-created-elements
      window.getComputedStyle(modules.get(0)).getPropertyValue('top')
      modules.removeClass 'enter'

    replace() if run

loadTags = (text) =>
  selected = $('li.tag-b.selected').data('val')
  $.getJSON "/tags.json?q=#{text}", (tags) =>
    $('li.tag-b').remove()
    results = $('#tags ul')
    if selected != 'all'
      results.append $("<li data-val='all' class='tag-b selectable'><a href='/tags/all' class='tag'>all</a></li>")
    results.append $("<li data-val='#{selected}' class='tag-b selectable selected'><a href='/tags/#{selected}' class='tag'>#{selected}</a></li>")
    for tag in tags
      $tag = $("<li data-val='#{tag}' class='tag-b selectable'><a href='/tags/#{tag}' class='tag'>#{tag}</a></li>")
      if tag == selected or tag == 'all'
        continue
      results.append $tag


window.onpopstate = (state) ->
  if not state.state?
    window.history.replaceState { type: $('body').data('type'), tag: $('body').data('tag') }, "", window.location
  else
    load_index state.state?.type, state.state?.tag, false, true

$('#searchTags input').on 'change keyup', (evt) =>
  if $(evt.target).data('existing') != evt.target.value
    $(evt.target).data('existing', evt.target.value)
    loadTags(evt.target.value)

$('#tags').on 'click', 'a.tag', (evt) ->
  if evt.which != 1 or evt.metaKey or evt.ctrlKey
    return

  $this = $ this
  tag = $this.text()
  load_index undefined, tag, true, true


  evt.stopPropagation()
  evt.preventDefault()

$ ->
  
  $('a.type').click (evt) ->
    if evt.which != 1 or evt.metaKey or evt.ctrlKey
      return

    $this = $ this
    type = $this.text().toLowerCase()
    load_index type, undefined, true, true

    evt.stopPropagation()
    evt.preventDefault()
