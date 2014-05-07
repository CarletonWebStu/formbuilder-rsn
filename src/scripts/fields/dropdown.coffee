Formbuilder.registerField 'dropdown',

  order: 24

  view: """
    <select>
      <% if (rf.get(Formbuilder.options.mappings.INCLUDE_BLANK)) { %>
        <option value=''></option>
      <% } %>

      <%
        var optionsForLooping = rf.get(Formbuilder.options.mappings.OPTIONS) || [];
        for (var i = 0 ; i < optionsForLooping.length ; i++) {
      %>
        <option <%= rf.get(Formbuilder.options.mappings.OPTIONS)[i].checked && 'selected' %>>
          <%= Formbuilder.helpers.warnIfEmpty(rf.get(Formbuilder.options.mappings.OPTIONS)[i].label, Formbuilder.options.dict.EMPTY_OPTION_WARNING) %>
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
    _.pathAssign(attrs, Formbuilder.options.mappings.OPTIONS, Formbuilder.generateDefaultOptionsArray())
    _.pathAssign(attrs, Formbuilder.options.mappings.INCLUDE_BLANK, false)

    attrs
