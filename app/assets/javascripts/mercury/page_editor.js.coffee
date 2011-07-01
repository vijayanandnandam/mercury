class @Mercury.PageEditor extends @Mercury.InlineEditor

  # options
  # saveStyle: 'form', or 'json' (defaults to json)
  # ignoredLinks: an array containing classes for links to ignore (eg. lightbox or accordian controls)
  constructor: (@saveUrl = null, @options = {}) ->
    super


  initializeInterface: ->
    @focusableElement = jQuery('<input>', {type: 'text', style: 'position:absolute;opacity:0'}).appendTo(@options.appendTo ? 'body')
    @iframe = jQuery('<iframe>', {class: 'mercury-iframe', seamless: 'true', frameborder: '0', src: 'about:blank', style: 'position:absolute;top:0;width:100%;visibility:hidden'})
    @iframe.appendTo(jQuery(@options.appendTo).get(0) ? 'body')

    @iframe.load => @initializeFrame()
    @iframeSrc = (url ? window.location.href).replace(/([http|https]:\/\/.[^\/]*)\/editor\/?(.*)/i, "$1/$2")
    @iframe.get(0).contentWindow.document.location.href = @iframeSrc

    @toolbar = new Mercury.Toolbar(@options)
    @statusbar = new Mercury.Statusbar(@options)


  initializeFrame: ->
    try
      return if @iframe.data('loaded')
      @iframe.data('loaded', true)
      @document = jQuery(@iframe.get(0).contentWindow.document)
      @injectStyles()

      # jquery: make jQuery evaluate scripts within the context of the iframe window -- note that this means that we
      # can't use eval in mercury (eg. script tags in ajax responses) because it will eval in the wrong context (you can
      # use top.Mercury though, if you keep it in mind)
      iframeWindow = @iframe.get(0).contentWindow
      jQuery.globalEval = (data) -> (iframeWindow.execScript || (data) -> iframeWindow["eval"].call(iframeWindow, data))(data) if (data && /\S/.test(data))
      iframeWindow.Mercury = Mercury

      @bindEvents()
      @initializeRegions()
      @finalizeInterface()

      @iframe.css({visibility: 'visible'})
    catch error
      alert("Mercury.PageEditor failed to load: #{error}\n\nPlease try refreshing.")


  finalizeInterface: ->
    super
    @hijackLinks()


  bindEvents: ->
    super
    Mercury.bind 'focus:frame', => @iframe.focus()


  resize: ->
    super

    @iframe.css {
      top: Mercury.displayRect.top
      left: 0
      height: Mercury.displayRect.height
    }


  contentWindow: ->
    @iframe.get(0).contentWindow


  saveUrl: ->
    @saveUrl || @iframeSrc


  hijackLinks: ->
    for link in jQuery('a', @document)
      ignored = false
      for classname in @options.ignoredLinks || []
        if jQuery(link).hasClass(classname)
          ignored = true
          continue
      if !ignored && (link.target == '' || link.target == '_self') && !jQuery(link).closest('.mercury-region').length
        jQuery(link).attr('target', '_top')
