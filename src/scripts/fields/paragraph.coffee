localPrettyName = "Multiline Text"

Formbuilder.registerField 'paragraph',

  order: 5

  view: """
    <textarea class='rf-size-<%= rf.get(Formbuilder.options.mappings.SIZE) %>'></textarea>
  """

  edit: """
    <%= Formbuilder.templates['edit/defaultVal']() %>
  """

  ###was: """
    <%= Formbuilder.templates['edit/size']() %>
    <%= Formbuilder.templates['edit/min_max_length']() %>
  """###

  ###
  addButton: """
    <span class="symbol">&#182;</span> Paragraph
  """
  ###
  prettyName: localPrettyName
  addButton: "<span class=\"symbol\">&#182;</span> " + localPrettyName

  # defaultAttributes: (attrs) ->
  #   _.pathAssign(attrs, Formbuilder.options.mappings.SIZE, 'small')
  #
  #   attrs
#
