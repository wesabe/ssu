wesabe.provide('logger.file')
wesabe.require('logger.simple')

#
# File Logger prints to a file.
#
class wesabe.logger.file extends wesabe.logger.simple
  @initialize: ->
    wesabe.debug('Registering file logger')

    try
      # Wesabe Logger registration - if not already registered.
      catMgr = Components.classes["@mozilla.org/categorymanager;1"]
                      .getService(Components.interfaces.nsICategoryManager)
      shouldRegister = true
      cats = catMgr.enumerateCategories()
      while cats.hasMoreElements() && shouldRegister
        cat = cats.getNext()
        catName = cat.QueryInterface(Components.interfaces.nsISupportsCString).data
        if catName == "loggers"
          catEntries = catMgr.enumerateCategory(cat)
          while catEntries.hasMoreElements()
            catEntry = catEntries.getNext()
            catEntryName = catEntry.QueryInterface(Components.interfaces.nsISupportsCString).data
            shouldRegister = false if catEntryName == "Wesabe Logger"

      if shouldRegister
        wesabe.debug('registering Wesabe Logger with category manager')
        catMgr.addCategoryEntry("loggers", "Wesabe Logger", "@wesabe.com/logger;1", false, true)

    catch ex
      wesabe.error('!! error registering file logger: ', ex)

  _log: (args, level) ->
    try
      @getLoggerComponent().log(@format(args, level))
    catch ex
      dump("error while logging: #{ex}\n")
      super(args, level)

  getLoggerComponent: ->
    return Components.classes["@wesabe.com/logger;1"]
      .getService(Components.interfaces.nsIWesabeLogger)
