module.exports =
  home_index_link: (type, tag) ->
    typePart = if type == 'popular' then '' else "/#{type}"
    tagPart = if tag == 'all' then '' else "/tags/#{tag}"

    link = typePart + tagPart

    if link.length == 0
      return '/'

    return link
