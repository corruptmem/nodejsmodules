home_index_link = (type, tag) ->
  typePart = if type == 'popular' then '' else "/#{type}"
  tagPart = if tag == 'all' then '' else "/tags/#{tag}"

  link = typePart + tagPart

  if link.length == 0
    return '/'

  return link

load_index = (type, tag, push) ->
  console.log "Loading #{type} #{tag} (push state: #{push})"

  if not type?
    type = $('body').data('type')

  if not tag?
    tag = $('body').data('tag')
  
  $('body').data 'type', type
  $('body').data 'tag', tag

  $(".selectable.tag-b").removeClass('selected')
  $(".selectable.type-b").removeClass('selected')
  $(".selectable.tag-b[data-val=#{tag}]").addClass('selected')
  $(".selectable.type-b[data-val=#{type}]").addClass('selected')
  
  url = home_index_link(type, tag)
  
  window.history.pushState { type: type, tag: tag }, "", url if push
  
  $.get url + ".partial", (content) ->
    $('#modules').replaceWith content

window.onpopstate = (state) ->
  if not state.state?
    console.log("Replacing initial state.")
    window.history.replaceState { type: $('body').data('type'), tag: $('body').data('tag') }, "", window.location
  load_index state.state.type, state.state.tag, false if state.state?

$ ->
  $('a.tag').click (evt) ->
    $this = $ this
    tag = $this.text()
    load_index undefined, tag, true


    evt.stopPropagation()
    evt.preventDefault()
  
  $('a.type').click (evt) ->
    $this = $ this
    type = $this.text().toLowerCase()
    load_index type, undefined, true

    evt.stopPropagation()
    evt.preventDefault()
