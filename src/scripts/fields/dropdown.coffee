Formbuilder.registerField 'dropdown',

  order: 24

  view: """
    <select>
      <% if (rf.get(Formbuilder.options.mappings.INCLUDE_BLANK)) { %>
        <option value=''></option>
      <% } %>

      <% for (i in (rf.get(Formbuilder.options.mappings.OPTIONS) || [])) { %>
        <option <%= rf.get(Formbuilder.options.mappings.OPTIONS)[i].checked && 'selected' %>>
          <%= rf.get(Formbuilder.options.mappings.OPTIONS)[i].label %>
        </option>
      <% } %>
    </select>
  """

  edit: """
    <%= Formbuilder.templates['edit/options']() %>
  """

  ###was:  """
    <%= Formbuilder.templates['edit/options']({ includeBlank: true }) %>
  """###

  addButton: """
    <span class="symbol"><span class="fa fa-caret-down"></span></span> Dropdown
  """

  defaultAttributes: (attrs) ->
    _.pathAssign(attrs, Formbuilder.options.mappings.OPTIONS, [
        label: "",
        checked: false
      ,
        label: "",
        checked: false
      ])
    _.pathAssign(attrs, Formbuilder.options.mappings.INCLUDE_BLANK, false)

    attrs